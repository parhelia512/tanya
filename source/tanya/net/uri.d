/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * URL parser.
 *
 * Copyright: Eugene Wissner 2017.
 * License: $(LINK2 https://www.mozilla.org/en-US/MPL/2.0/,
 *                  Mozilla Public License, v. 2.0).
 * Authors: $(LINK2 mailto:info@caraus.de, Eugene Wissner)
 */
module tanya.net.uri;

import std.ascii : isAlphaNum, isDigit;
import std.traits : isSomeString;
import std.uni : isAlpha, isNumber;
import tanya.memory;

/**
 * Thrown if an invalid URI was specified.
 */
final class URIException : Exception
{
    /**
     * Params:
     *  msg  = The message for the exception.
     *  file = The file where the exception occurred.
     *  line = The line number where the exception occurred.
     *  next = The previous exception in the chain of exceptions, if any.
     */
    this(string msg,
         string file = __FILE__,
         size_t line = __LINE__,
         Throwable next = null) @nogc @safe pure nothrow
    {
        super(msg, file, line, next);
    }
}

/**
 * A Unique Resource Locator.
 */
struct URL
{
    /// The URL scheme.
    const(char)[] scheme;

    /// The username.
    const(char)[] user;

    /// The password.
    const(char)[] pass;

    /// The hostname.
    const(char)[] host;

    /// The port number.
    ushort port;

    /// The path.
    const(char)[] path;

    /// The query string.
    const(char)[] query;

    /// The anchor.
    const(char)[] fragment;

    /**
     * Attempts to parse an URL from a string.
     * Output string data (scheme, user, etc.) are just slices of input string
     * (e.g., no memory allocation and copying).
     *
     * Params:
     *  source = The string containing the URL.
     *
     * Throws: $(D_PSYMBOL URIException) if the URL is malformed.
     */
    this(const char[] source) @nogc
    {
        auto value = source;
        ptrdiff_t pos = -1, endPos = value.length, start;

        foreach (i, ref c; source)
        {
            if (pos == -1 && c == ':')
            {
                pos = i;
            }
            if (endPos == value.length && (c == '?' || c == '#'))
            {
                endPos = i;
            }
        }

        // Check if the colon is a part of the scheme or the port and parse
        // the appropriate part
        if (value.length > 1 && value[0] == '/' && value[1] == '/')
        {
            // Relative scheme
            start = 2;
        }
        else if (pos > 0)
        {
            // Validate scheme
            // [ toLower(alpha) | digit | "+" | "-" | "." ]
            foreach (ref c; value[0 .. pos])
            {
                if (!c.isAlphaNum && c != '+' && c != '-' && c != '.')
                {
                    if (endPos > pos)
                    {
                        if (!parsePort(value[pos .. $]))
                        {
                            throw make!URIException(defaultAllocator,
                                                    "Failed to parse port");
                        }
                    }
                    goto ParsePath;
                }
            }

            if (value.length == pos + 1) // only scheme is available
            {
                this.scheme = value[0 .. $ - 1];
                return;
            }
            else if (value.length > pos + 1 && value[pos + 1] == '/')
            {
                this.scheme = value[0 .. pos];

                if (value.length > pos + 2 && value[pos + 2] == '/')
                {
                    start = pos + 3;
                    if (this.scheme == "file"
                     && value.length > start
                     && value[start] == '/')
                    {
                        // Windows drive letters
                        if (value.length - start > 2 && value[start + 2] == ':')
                        {
                            ++start;
                        }
                        goto ParsePath;
                    }
                }
                else
                {
                    start = pos + 1;
                    goto ParsePath;
                }
            }
            else // certain schemas like mailto: and zlib: may not have any / after them
            {
                
                if (!parsePort(value[pos .. $]))
                {
                    this.scheme = value[0 .. pos];
                    start = pos + 1;
                    goto ParsePath;
                }
            }
        }
        else if (pos == 0 && parsePort(value[pos .. $]))
        {
            // An URL shouldn't begin with a port number
            throw defaultAllocator.make!URIException("URL begins with port");
        }
        else
        {
            goto ParsePath;
        }

        // Parse host
        pos = -1;
        for (ptrdiff_t i = start; i < value.length; ++i)
        {
            if (value[i] == '@')
            {
                pos = i;
            }
            else if (value[i] == '/')
            {
                endPos = i;
                break;
            }
        }

        // Check for login and password
        if (pos != -1)
        {
            // *( unreserved / pct-encoded / sub-delims / ":" )
            foreach (i, c; value[start .. pos])
            {
                if (c == ':')
                {
                    if (this.user is null)
                    {
                        this.user = value[start .. start + i];
                        this.pass = value[start + i + 1 .. pos]; 
                    }
                }
                else if (!c.isAlpha &&
                         !c.isNumber &&
                         c != '!' &&
                         c != ';' &&
                         c != '=' &&
                         c != '_' &&
                         c != '~' &&
                         !(c >= '$' && c <= '.'))
                {
                    this.scheme = this.user = this.pass = null;
                    throw make!URIException(defaultAllocator,
                                            "Restricted characters in user information");
                }
            }
            if (this.user is null)
            {
                this.user = value[start .. pos];
            }

            start = ++pos;
        }

        pos = endPos;
        if (endPos <= 1 || value[start] != '[' || value[endPos - 1] != ']')
        {
            // Short circuit portscan
            // IPv6 embedded address
            for (ptrdiff_t i = endPos - 1; i >= start; --i)
            {
                if (value[i] == ':')
                {
                    pos = i;
                    if  (this.port == 0 && !parsePort(value[i .. endPos]))
                    {
                        this.scheme = this.user = this.pass = null;
                        throw defaultAllocator.make!URIException("Invalid port");
                    }
                    break;
                }
            }
        }

        // Check if we have a valid host, if we don't reject the string as url
        if (pos <= start)
        {
            this.scheme = this.user = this.pass = null;
            throw defaultAllocator.make!URIException("Invalid host");
        }

        this.host = value[start .. pos];

        if (endPos == value.length)
        {
            return;
        }

        start = endPos;

    ParsePath:
        endPos = value.length;
        pos = -1;
        foreach (i, ref c; value[start .. $])
        {
            if (c == '?' && pos == -1)
            {
                pos = start + i;
            }
            else if (c == '#')
            {
                endPos = start + i;
                break;
            }
        }
        if (pos == -1)
        {
            pos = endPos;
        }

        if (pos > start)
        {
            this.path = value[start .. pos];
        }
        if (endPos >= ++pos)
        {
            this.query = value[pos .. endPos];
        }
        if (++endPos <= value.length)
        {
            this.fragment = value[endPos .. $];
        }
    }

    /*
     * Attempts to parse and set the port.
     *
     * Params:
     *  port = String beginning with a colon followed by the port number and
     *         an optional path (query string and/or fragment), like:
     *         `:12345/some_path` or `:12345`.
     *
     * Returns: Whether the port could be found.
     */
    private bool parsePort(const char[] port) pure nothrow @safe @nogc
    {
        ptrdiff_t i = 1;
        float lPort = 0;

        for (; i < port.length && port[i].isDigit() && i <= 6; ++i)
        {
            lPort += (port[i] - '0') / cast(float)(10 ^^ (i - 1));
        }
        if (i == 1 && (i == port.length || port[i] == '/'))
        {
            return true;
        }
        else if (i == port.length || port[i] == '/')
        {
            lPort *= 10 ^^ (i - 2);
            if (lPort > ushort.max)
            {
                return false;
            }
            this.port = cast(ushort) lPort;
            return true;
        }
        return false;
    }
}

///
@nogc unittest
{
    auto u = URL("example.org");
    assert(u.path == "example.org"); 

    u = URL("relative/path");
    assert(u.path == "relative/path"); 

    // Host and scheme
    u = URL("https://example.org");
    assert(u.scheme == "https");
    assert(u.host == "example.org");
    assert(u.path is null);
    assert(u.port == 0);
    assert(u.fragment is null);

    // With user and port and path
    u = URL("https://hilary:putnam@example.org:443/foo/bar");
    assert(u.scheme == "https");
    assert(u.host == "example.org");
    assert(u.path == "/foo/bar");
    assert(u.port == 443);
    assert(u.user == "hilary");
    assert(u.pass == "putnam");
    assert(u.fragment is null);

    // With query string
    u = URL("https://example.org/?login=true");
    assert(u.scheme == "https");
    assert(u.host == "example.org");
    assert(u.path == "/");
    assert(u.query == "login=true");
    assert(u.fragment is null);

    // With query string and fragment
    u = URL("https://example.org/?login=false#label");
    assert(u.scheme == "https");
    assert(u.host == "example.org");
    assert(u.path == "/");
    assert(u.query == "login=false");
    assert(u.fragment == "label");

    u = URL("redis://root:password@localhost:2201/path?query=value#fragment");
    assert(u.scheme == "redis");
    assert(u.user == "root");
    assert(u.pass == "password");
    assert(u.host == "localhost");
    assert(u.port == 2201);
    assert(u.path == "/path");
    assert(u.query == "query=value");
    assert(u.fragment == "fragment");
}

private unittest
{
    auto u = URL("127.0.0.1");
    assert(u.path == "127.0.0.1");

    u = URL("http://127.0.0.1");
    assert(u.scheme == "http");
    assert(u.host == "127.0.0.1");

    u = URL("http://127.0.0.1:9000");
    assert(u.scheme == "http");
    assert(u.host == "127.0.0.1");
    assert(u.port == 9000);

    u = URL("//example.net");
    assert(u.host == "example.net");
    assert(u.scheme is null);

    u = URL("//example.net?q=before:after");
    assert(u.host == "example.net");
    assert(u.query == "q=before:after");

    u = URL("localhost:8080");
    assert(u.host == "localhost");
    assert(u.port == 8080);

    u = URL("ftp:");
    assert(u.scheme == "ftp");

    u = URL("file:///C:\\Users");
    assert(u.scheme == "file");
    assert(u.path == "C:\\Users");

    u = URL("localhost:66000");
    assert(u.scheme == "localhost");
    assert(u.path == "66000");

    u = URL("file:///home/");
    assert(u.scheme == "file");
    assert(u.path == "/home/");

    u = URL("file:///home/?q=asdf");
    assert(u.scheme == "file");
    assert(u.path == "/home/");
    assert(u.query == "q=asdf");

    u = URL("http://secret@example.org");
    assert(u.scheme == "http");
    assert(u.host == "example.org");
    assert(u.user == "secret");

    u = URL("h_tp://:80");
    assert(u.path == "h_tp://:80");
    assert(u.port == 0);

    u = URL("zlib:/home/user/file.gz");
    assert(u.scheme == "zlib");
    assert(u.path == "/home/user/file.gz");
}

private @nogc unittest
{
    URIException exception;
    try
    {
        auto u = URL("h_tp:asdf");
    }
    catch (URIException e)
    {
        exception = e;
    }
    assert(exception !is null);
    defaultAllocator.dispose(exception);
}

private @nogc unittest
{
    URIException exception;
    try
    {
        auto u = URL("http://:80");
    }
    catch (URIException e)
    {
        exception = e;
    }
    assert(exception !is null);
    defaultAllocator.dispose(exception);
}

private @nogc unittest
{
    URIException exception;
    try
    {
        auto u = URL(":80");
    }
    catch (URIException e)
    {
        exception = e;
    }
    assert(exception !is null);
    defaultAllocator.dispose(exception);
}

private @nogc unittest
{
    URIException exception;
    try
    {
        auto u = URL("http://user1:pass1@user2:pass2@example.org");
    }
    catch (URIException e)
    {
        exception = e;
    }
    assert(exception !is null);
    defaultAllocator.dispose(exception);
}

private @nogc unittest
{
    URIException exception;
    try
    {
        auto u = URL("http://blah.com:port");
    }
    catch (URIException e)
    {
        exception = e;
    }
    assert(exception !is null);
    defaultAllocator.dispose(exception);
}

private @nogc unittest
{
    URIException exception;
    try
    {
        auto u = URL(":/");
    }
    catch (URIException e)
    {
        exception = e;
    }
    assert(exception !is null);
    defaultAllocator.dispose(exception);
}

/**
 * Attempts to parse an URL from a string and returns the specified component
 * of the URL or $(D_PSYMBOL URL) if no component is specified.
 *
 * Params:
 *  T      = "scheme", "host", "port", "user", "pass", "path", "query",
 *           "fragment" or $(D_KEYWORD null) for a struct with all components.
 *  source = The string containing the URL.
 *
 * Returns: Requested URL component.
 */
URL parseURL(const char[] source) @nogc
{
    return URL(source);
}

/// Ditto.
auto parseURL(string T)(const char[] source)
if (T == "scheme"
 || T == "host"
 || T == "user"
 || T == "pass"
 || T == "path"
 || T == "query"
 || T == "fragment"
 || T == "port")
{
    auto ret = URL(source);
    return mixin("ret." ~ T);
}

///
@nogc unittest
{
    auto u = parseURL("http://example.org:5326");
    assert(u.scheme == parseURL!"scheme"("http://example.org:5326"));
    assert(u.host == parseURL!"host"("http://example.org:5326"));
    assert(u.user == parseURL!"user"("http://example.org:5326"));
    assert(u.pass == parseURL!"pass"("http://example.org:5326"));
    assert(u.path == parseURL!"path"("http://example.org:5326"));
    assert(u.query == parseURL!"query"("http://example.org:5326"));
    assert(u.fragment == parseURL!"fragment"("http://example.org:5326"));
    assert(u.port == parseURL!"port"("http://example.org:5326"));
}
