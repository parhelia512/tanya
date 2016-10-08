/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Copyright: Eugene Wissner 2016.
 * License: $(LINK2 https://www.mozilla.org/en-US/MPL/2.0/,
 *                  Mozilla Public License, v. 2.0).
 * Authors: $(LINK2 mailto:belka@caraus.de, Eugene Wissner)
 *
 * ---
 * import tanya.async;
 * import tanya.network.socket;
 *
 * class EchoProtocol : TransmissionControlProtocol
 * {
 *     private DuplexTransport transport;
 *
 *     void received(ubyte[] data)
 *     {
 *         transport.write(data);
 *     }
 *
 *     void connected(DuplexTransport transport)
 *     {
 *         this.transport = transport;
 *     }
 *
 *     void disconnected(SocketException exception = null)
 *     {
 *     }
 * }
 *
 * void main()
 * {
 *     auto address = new InternetAddress("127.0.0.1", cast(ushort) 8192);
 *     version (Windows)
 *     {
 *         auto sock = new OverlappedStreamSocket(AddressFamily.INET);
 *     }
 *     else
 *     {
 *         auto sock = new StreamSocket(AddressFamily.INET);
 *         sock.blocking = false;
 *     }
 *
 *     sock.bind(address);
 *     sock.listen(5);
 *
 *     auto io = new ConnectionWatcher(sock);
 *     io.setProtocol!EchoProtocol;
 *
 *     defaultLoop.start(io);
 *     defaultLoop.run();
 *
 *     sock.shutdown();
 * }
 * ---
 */
module tanya.async.loop;

import tanya.async.protocol;
import tanya.async.transport;
import tanya.async.watcher;
import tanya.container.buffer;
import tanya.memory;
import tanya.memory.mmappool;
import tanya.network.socket;
import core.time;
import std.algorithm.iteration;
import std.algorithm.mutation;
import std.typecons;

version (DisableBackends)
{
}
else version (linux)
{
    import tanya.async.event.epoll;
    version = Epoll;
}
else version (Windows)
{
    import tanya.async.event.iocp;
    version = IOCP;
}
else version (OSX)
{
    version = Kqueue;
}
else version (iOS)
{
    version = Kqueue;
}
else version (FreeBSD)
{
    version = Kqueue;
}
else version (OpenBSD)
{
    version = Kqueue;
}
else version (DragonFlyBSD)
{
    version = Kqueue;
}

/**
 * Events.
 */
enum Event : uint
{
    none   = 0x00,       /// No events.
    read   = 0x01,       /// Non-blocking read call.
    write  = 0x02,       /// Non-blocking write call.
    accept = 0x04,       /// Connection made.
    error  = 0x80000000, /// Sent when an error occurs.
}

alias EventMask = BitFlags!Event;

/**
 * Tries to set $(D_PSYMBOL MmapPool) to the default allocator.
 */
shared static this()
{
    if (allocator is null)
    {
        allocator = MmapPool.instance;
    }
}

/**
 * Event loop.
 */
abstract class Loop
{
    /// Pending watchers.
    protected PendingQueue!Watcher pendings;

    protected PendingQueue!Watcher swapPendings;

    /**
     * Returns: Maximal event count can be got at a time
     *          (should be supported by the backend).
     */
    protected @property inout(uint) maxEvents() inout const pure nothrow @safe @nogc
    {
        return 128U;
    }

    /**
     * Initializes the loop.
     */
    this()
    {
        pendings = MmapPool.instance.make!(PendingQueue!Watcher);
        swapPendings = MmapPool.instance.make!(PendingQueue!Watcher);
    }

    /**
     * Frees loop internals.
     */
    ~this()
    {
        MmapPool.instance.dispose(pendings);
        MmapPool.instance.dispose(swapPendings);
    }

    /**
     * Starts the loop.
     */
    void run()
    {
        done_ = false;
        do
        {
            poll();

            // Invoke pendings
            swapPendings.each!((ref p) => p.invoke());

            swap(pendings, swapPendings);
        }
        while (!done_);
    }

    /**
     * Break out of the loop.
     */
    void unloop() @safe pure nothrow
    {
        done_ = true;
    }

    /**
     * Start watching.
     *
     * Params:
     *     watcher = Watcher.
     */
    void start(ConnectionWatcher watcher)
    {
        if (watcher.active)
        {
            return;
        }
        watcher.active = true;
        reify(watcher, EventMask(Event.none), EventMask(Event.accept));
    }

    /**
     * Stop watching.
     *
     * Params:
     *     watcher = Watcher.
     */
    void stop(ConnectionWatcher watcher)
    {
        if (!watcher.active)
        {
            return;
        }
        watcher.active = false;

        reify(watcher, EventMask(Event.accept), EventMask(Event.none));
    }

    /**
     * Should be called if the backend configuration changes.
     *
     * Params:
     *     watcher   = Watcher.
     *     oldEvents = The events were already set.
     *     events    = The events should be set.
     *
     * Returns: $(D_KEYWORD true) if the operation was successful.
     */
    abstract protected bool reify(ConnectionWatcher watcher,
                                  EventMask oldEvents,
                                  EventMask events);

    /**
     * Returns: The blocking time.
     */
    protected @property inout(Duration) blockTime()
    inout @safe pure nothrow
    {
        // Don't block if we have to do.
        return swapPendings.empty ? blockTime_ : Duration.zero;
    }

    /**
     * Sets the blocking time for IO watchers.
     *
     * Params:
     *     blockTime = The blocking time. Cannot be larger than
     *                 $(D_PSYMBOL maxBlockTime).
     */
    protected @property void blockTime(in Duration blockTime) @safe pure nothrow
    in
    {
        assert(blockTime <= 1.dur!"hours", "Too long to wait.");
        assert(!blockTime.isNegative);
    }
    body
    {
        blockTime_ = blockTime;
    }

    /**
     * Kills the watcher and closes the connection.
     */
    protected void kill(IOWatcher watcher, SocketException exception)
    {
        watcher.socket.shutdown();
        defaultAllocator.dispose(watcher.socket);
        MmapPool.instance.dispose(watcher.transport);
        watcher.exception = exception;
        swapPendings.insertBack(watcher);
    }

    /**
     * Does the actual polling.
     */
    abstract protected void poll();

    /// Whether the event loop should be stopped.
    private bool done_;

    /// Maximal block time.
    protected Duration blockTime_ = 1.dur!"minutes";
}

/**
 * Exception thrown on errors in the event loop.
 */
class BadLoopException : Exception
{
@nogc:
    /**
     * Params:
     *     file = The file where the exception occurred.
     *     line = The line number where the exception occurred.
     *     next = The previous exception in the chain of exceptions, if any.
     */
    this(string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    pure @safe nothrow const
    {
        super("Event loop cannot be initialized.", file, line, next);
    }
}

/**
 * Returns the event loop used by default. If an event loop wasn't set with
 * $(D_PSYMBOL defaultLoop) before, $(D_PSYMBOL defaultLoop) will try to
 * choose an event loop supported on the system.
 *
 * Returns: The default event loop.
 */
@property Loop defaultLoop()
{
    if (defaultLoop_ !is null)
    {
        return defaultLoop_;
    }
    version (Epoll)
    {
        defaultLoop_ = MmapPool.instance.make!EpollLoop;
    }
    else version (IOCP)
    {
        defaultLoop_ = MmapPool.instance.make!IOCPLoop;
    }
    else version (Kqueue)
    {
        import tanya.async.event.kqueue;
        defaultLoop_ = MmapPool.instance.make!KqueueLoop;
    }
    return defaultLoop_;
}

/**
 * Sets the default event loop.
 *
 * This property makes it possible to implement your own backends or event
 * loops, for example, if the system is not supported or if you want to
 * extend the supported implementation. Just extend $(D_PSYMBOL Loop) and pass
 * your implementation to this property.
 *
 * Params:
 *     loop = The event loop.
 */
@property void defaultLoop(Loop loop)
in
{
    assert(loop !is null);
}
body
{
    defaultLoop_ = loop;
}

private Loop defaultLoop_;

/**
 * Queue.
 *
 * Params:
 *     T = Content type.
 */
class PendingQueue(T)
{
    /**
     * Creates a new $(D_PSYMBOL Queue).
     */
    this()
    {
    }

    /**
     * Removes all elements from the queue.
     */
    ~this()
    {
        foreach (e; this)
        {
            MmapPool.instance.dispose(e);
        }
    }

    /**
     * Returns: First element.
     */
    @property ref T front()
    in
    {
        assert(!empty);
    }
    body
    {
        return first.next.content;
    }

    /**
     * Inserts a new element.
     *
     * Params:
     *     x = New element.
     *
     * Returns: $(D_KEYWORD this).
     */
    typeof(this) insertBack(T x)
    {
        Entry* temp = MmapPool.instance.make!Entry;
        
        temp.content = x;

        if (empty)
        {
            first.next = rear = temp;
        }
        else
        {
            rear.next = temp;
            rear = rear.next;
        }

        return this;
    }

    alias insert = insertBack;

    /**
     * Inserts a new element.
     *
     * Params:
     *     x = New element.
     *
     * Returns: $(D_KEYWORD this).
     */
    typeof(this) opOpAssign(string Op)(ref T x)
        if (Op == "~")
    {
        return insertBack(x);
    }

    /**
     * Returns: $(D_KEYWORD true) if the queue is empty.
     */
    @property bool empty() const @safe pure nothrow
    {
        return first.next is null;
    }

    /**
     * Move position to the next element.
     *
     * Returns: $(D_KEYWORD this).
     */
    typeof(this) popFront()
    in
    {
        assert(!empty);
    }
    body
    {
        auto n = first.next.next;

        MmapPool.instance.dispose(first.next);
        first.next = n;

        return this;
    }

    /**
     * Queue entry.
     */
    protected struct Entry
    {
        /// Queue item content.
        T content;

        /// Next list item.
        Entry* next;
    }

    /// The first element of the list.
    protected Entry first;

    /// The last element of the list.
    protected Entry* rear;
}
