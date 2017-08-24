/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * This module contains functions that manipulate template type lists as well
 * as algorithms to perform arbitrary compile-time computations.
 *
 * Copyright: Eugene Wissner 2017.
 * License: $(LINK2 https://www.mozilla.org/en-US/MPL/2.0/,
 *                  Mozilla Public License, v. 2.0).
 * Authors: $(LINK2 mailto:info@caraus.de, Eugene Wissner)
 * Source: $(LINK2 https://github.com/caraus-ecms/tanya/blob/master/source/tanya/meta/metafunction.d,
 *                 tanya/meta/metafunction.d)
 */
module tanya.meta.metafunction;

import tanya.meta.trait;
import tanya.meta.transform;

/**
 * Tests whether $(D_INLINECODE Args[0]) is less than or equal to
 * $(D_INLINECODE Args[1]) according to $(D_PARAM cmp).
 *
 * $(D_PARAM cmp) can evaluate to:
 * $(UL
 *  $(LI $(D_KEYWORD bool): $(D_KEYWORD true) means
 *       $(D_INLINECODE Args[0] < Args[1]).)
 *  $(LI $(D_KEYWORD int): a negative number means that
 *       $(D_INLINECODE Args[0] < Args[1]), a positive number that
 *       $(D_INLINECODE Args[0] > Args[1]), `0` if they equal.)
 * )
 *
 * Params:
 *  Args = Two aliases to compare for equality.
 *
 * Returns: $(D_KEYWORD true) if $(D_INLINECODE Args[0]) is less than or equal
 *          to $(D_INLINECODE Args[1]), $(D_KEYWORD false) otherwise.
 */
template isLessEqual(alias cmp, Args...)
if (Args.length == 2)
{
    private enum result = cmp!(Args[1], Args[0]);
    static if (is(typeof(result) == bool))
    {
        enum bool isLessEqual = !result;
    }
    else
    {
        enum bool isLessEqual = result >= 0;
    }
}

///
pure nothrow @safe @nogc unittest
{
    enum bool boolCmp(T, U) = T.sizeof < U.sizeof;
    static assert(isLessEqual!(boolCmp, byte, int));
    static assert(isLessEqual!(boolCmp, uint, int));
    static assert(!isLessEqual!(boolCmp, long, int));

    enum ptrdiff_t intCmp(T, U) = T.sizeof - U.sizeof;
    static assert(isLessEqual!(intCmp, byte, int));
    static assert(isLessEqual!(intCmp, uint, int));
    static assert(!isLessEqual!(intCmp, long, int));
}

/**
 * Tests whether $(D_INLINECODE Args[0]) is greater than or equal to
 * $(D_INLINECODE Args[1]) according to $(D_PARAM cmp).
 *
 * $(D_PARAM cmp) can evaluate to:
 * $(UL
 *  $(LI $(D_KEYWORD bool): $(D_KEYWORD true) means
 *       $(D_INLINECODE Args[0] < Args[1]).)
 *  $(LI $(D_KEYWORD int): a negative number means that
 *       $(D_INLINECODE Args[0] < Args[1]), a positive number that
 *       $(D_INLINECODE Args[0] > Args[1]), `0` if they equal.)
 * )
 *
 * Params:
 *  Args = Two aliases to compare for equality.
 *
 * Returns: $(D_KEYWORD true) if $(D_INLINECODE Args[0]) is greater than or
 *          equal to $(D_INLINECODE Args[1]), $(D_KEYWORD false) otherwise.
 */
template isGreaterEqual(alias cmp, Args...)
if (Args.length == 2)
{
    private enum result = cmp!Args;
    static if (is(typeof(result) == bool))
    {
        enum bool isGreaterEqual = !result;
    }
    else
    {
        enum bool isGreaterEqual = result >= 0;
    }
}

///
pure nothrow @safe @nogc unittest
{
    enum bool boolCmp(T, U) = T.sizeof < U.sizeof;
    static assert(!isGreaterEqual!(boolCmp, byte, int));
    static assert(isGreaterEqual!(boolCmp, uint, int));
    static assert(isGreaterEqual!(boolCmp, long, int));

    enum ptrdiff_t intCmp(T, U) = T.sizeof - U.sizeof;
    static assert(!isGreaterEqual!(intCmp, byte, int));
    static assert(isGreaterEqual!(intCmp, uint, int));
    static assert(isGreaterEqual!(intCmp, long, int));
}

/**
 * Tests whether $(D_INLINECODE Args[0]) is less than
 * $(D_INLINECODE Args[1]) according to $(D_PARAM cmp).
 *
 * $(D_PARAM cmp) can evaluate to:
 * $(UL
 *  $(LI $(D_KEYWORD bool): $(D_KEYWORD true) means
 *       $(D_INLINECODE Args[0] < Args[1]).)
 *  $(LI $(D_KEYWORD int): a negative number means that
 *       $(D_INLINECODE Args[0] < Args[1]), a positive number that
 *       $(D_INLINECODE Args[0] > Args[1]), `0` if they equal.)
 * )
 *
 * Params:
 *  Args = Two aliases to compare for equality.
 *
 * Returns: $(D_KEYWORD true) if $(D_INLINECODE Args[0]) is less than
 *          $(D_INLINECODE Args[1]), $(D_KEYWORD false) otherwise.
 */
template isLess(alias cmp, Args...)
if (Args.length == 2)
{
    private enum result = cmp!Args;
    static if (is(typeof(result) == bool))
    {
        enum bool isLess = result;
    }
    else
    {
        enum bool isLess = result < 0;
    }
}

///
pure nothrow @safe @nogc unittest
{
    enum bool boolCmp(T, U) = T.sizeof < U.sizeof;
    static assert(isLess!(boolCmp, byte, int));
    static assert(!isLess!(boolCmp, uint, int));
    static assert(!isLess!(boolCmp, long, int));

    enum ptrdiff_t intCmp(T, U) = T.sizeof - U.sizeof;
    static assert(isLess!(intCmp, byte, int));
    static assert(!isLess!(intCmp, uint, int));
    static assert(!isLess!(intCmp, long, int));
}

/**
 * Tests whether $(D_INLINECODE Args[0]) is greater than
 * $(D_INLINECODE Args[1]) according to $(D_PARAM cmp).
 *
 * $(D_PARAM cmp) can evaluate to:
 * $(UL
 *  $(LI $(D_KEYWORD bool): $(D_KEYWORD true) means
 *       $(D_INLINECODE Args[0] < Args[1]).)
 *  $(LI $(D_KEYWORD int): a negative number means that
 *       $(D_INLINECODE Args[0] < Args[1]), a positive number that
 *       $(D_INLINECODE Args[0] > Args[1]), `0` if they equal.)
 * )
 *
 * Params:
 *  Args = Two aliases to compare for equality.
 *
 * Returns: $(D_KEYWORD true) if $(D_INLINECODE Args[0]) is greater than
 *          $(D_INLINECODE Args[1]), $(D_KEYWORD false) otherwise.
 */
template isGreater(alias cmp, Args...)
if (Args.length == 2)
{
    private enum result = cmp!Args;
    static if (is(typeof(result) == bool))
    {
        enum bool isGreater = !result && cmp!(Args[1], Args[0]);
    }
    else
    {
        enum bool isGreater = result > 0;
    }
}

///
pure nothrow @safe @nogc unittest
{
    enum bool boolCmp(T, U) = T.sizeof < U.sizeof;
    static assert(!isGreater!(boolCmp, byte, int));
    static assert(!isGreater!(boolCmp, uint, int));
    static assert(isGreater!(boolCmp, long, int));

    enum ptrdiff_t intCmp(T, U) = T.sizeof - U.sizeof;
    static assert(!isGreater!(intCmp, byte, int));
    static assert(!isGreater!(intCmp, uint, int));
    static assert(isGreater!(intCmp, long, int));
}

/**
 * Tests whether $(D_INLINECODE Args[0]) is equal to $(D_INLINECODE Args[1]).
 *
 * $(D_PSYMBOL isEqual) checks first if $(D_PARAM Args) can be compared directly. If not, they are compared as types:
 * $(D_INLINECODE is(Args[0] == Args[1])). It it fails, the arguments are
 * considered to be not equal.
 *
 * Params:
 *  Args = Two aliases to compare for equality.
 *
 * Returns: $(D_KEYWORD true) if $(D_INLINECODE Args[0]) is equal to
 *          $(D_INLINECODE Args[1]), $(D_KEYWORD false) otherwise.
 */
template isEqual(Args...)
if (Args.length == 2)
{
    static if ((is(typeof(Args[0] == Args[1])) && (Args[0] == Args[1]))
            || is(Args[0] == Args[1]))
    {
        enum bool isEqual = true;
    }
    else
    {
        enum bool isEqual = false;
    }
}

///
pure nothrow @safe @nogc unittest
{
    static assert(isEqual!(int, int));
    static assert(!isEqual!(5, int));
    static assert(!isEqual!(5, 8));
}

/**
 * Tests whether $(D_INLINECODE Args[0]) isn't equal to
 * $(D_INLINECODE Args[1]).
 *
 * $(D_PSYMBOL isNotEqual) checks first if $(D_PARAM Args) can be compared directly. If not, they are compared as types:
 * $(D_INLINECODE is(Args[0] == Args[1])). It it fails, the arguments are
 * considered to be not equal.
 *
 * Params:
 *  Args = Two aliases to compare for equality.
 *
 * Returns: $(D_KEYWORD true) if $(D_INLINECODE Args[0]) isn't equal to
 *          $(D_INLINECODE Args[1]), $(D_KEYWORD false) otherwise.
 */
template isNotEqual(Args...)
if (Args.length == 2)
{
    enum bool isNotEqual = !isEqual!Args;
}

///
pure nothrow @safe @nogc unittest
{
    static assert(!isNotEqual!(int, int));
    static assert(isNotEqual!(5, int));
    static assert(isNotEqual!(5, 8));
}

/**
 * Creates an alias for $(D_PARAM T).
 *
 * In contrast to the $(D_KEYWORD alias)-keyword $(D_PSYMBOL Alias) can alias
 * any kind of D symbol that can be used as argument to template alias
 * parameters.
 *
 * $(UL
 *  $(LI Types)
 *  $(LI Local and global names)
 *  $(LI Module names)
 *  $(LI Template names)
 *  $(LI Template instance names)
 *  $(LI Literals)
 * )
 *
 * Params:
 *  T = A symbol.
 *
 * Returns: An alias for $(D_PARAM T).
 *
 * See_Also: $(LINK2 https://dlang.org/spec/template.html#aliasparameters,
 *                   Template Alias Parameters).
 */
alias Alias(alias T) = T;

/// Ditto.
alias Alias(T) = T;

///
pure nothrow @safe @nogc unittest
{
    static assert(is(Alias!int));

    static assert(is(typeof(Alias!5)));
    static assert(is(typeof(Alias!(() {}))));

    int i;
    static assert(is(typeof(Alias!i)));
}

/**
 * Params:
 *  Args = List of symbols.
 *
 * Returns: An alias for sequence $(D_PARAM Args).
 *
 * See_Also: $(D_PSYMBOL Alias).
 */
alias AliasSeq(Args...) = Args;

///
pure nothrow @safe @nogc unittest
{
    static assert(is(typeof({ alias T = AliasSeq!(short, 5); })));
    static assert(is(typeof({ alias T = AliasSeq!(int, short, 5); })));
    static assert(is(typeof({ alias T = AliasSeq!(() {}, short, 5); })));
    static assert(is(typeof({ alias T = AliasSeq!(); })));

    static assert(AliasSeq!().length == 0);
    static assert(AliasSeq!(int, short, 5).length == 3);
}

/**
 * Tests whether all the items of $(D_PARAM L) satisfy the condition
 * $(D_PARAM F).
 *
 * $(D_PARAM F) is a template that accepts one parameter and returns a boolean,
 * so $(D_INLINECODE F!([0]) && F!([1])) and so on, can be called.
 *
 * Params:
 *  F = Template predicate. 
 *  L = List of items to test.
 *
 * Returns: $(D_KEYWORD true) if all the items of $(D_PARAM L) satisfy
 *          $(D_PARAM F), $(D_KEYWORD false) otherwise.
 */
template allSatisfy(alias F, L...)
{
    static if (L.length == 0)
    {
        enum bool allSatisfy = true;
    }
    else static if (F!(L[0]))
    {
        enum bool allSatisfy = allSatisfy!(F, L[1 .. $]);
    }
    else
    {
        enum bool allSatisfy = false;
    }
}

///
pure nothrow @safe @nogc unittest
{
    static assert(allSatisfy!(isSigned, int, short, byte, long));
    static assert(!allSatisfy!(isUnsigned, uint, ushort, float, ulong));
}

/**
 * Tests whether any of the items of $(D_PARAM L) satisfy the condition
 * $(D_PARAM F).
 *
 * $(D_PARAM F) is a template that accepts one parameter and returns a boolean,
 * so $(D_INLINECODE F!([0]) && F!([1])) and so on, can be called.
 *
 * Params:
 *  F = Template predicate. 
 *  L = List of items to test.
 *
 * Returns: $(D_KEYWORD true) if any of the items of $(D_PARAM L) satisfy
 *          $(D_PARAM F), $(D_KEYWORD false) otherwise.
 */
template anySatisfy(alias F, L...)
{
    static if (L.length == 0)
    {
        enum bool anySatisfy = false;
    }
    else static if (F!(L[0]))
    {
        enum bool anySatisfy = true;
    }
    else
    {
        enum bool anySatisfy = anySatisfy!(F, L[1 .. $]);
    }
}

///
pure nothrow @safe @nogc unittest
{
    static assert(anySatisfy!(isSigned, int, short, byte, long));
    static assert(anySatisfy!(isUnsigned, uint, ushort, float, ulong));
    static assert(!anySatisfy!(isSigned, uint, ushort, ulong));
}

private template indexOf(ptrdiff_t i, Args...)
if (Args.length > 0)
{
    static if (Args.length == 1)
    {
        enum ptrdiff_t indexOf = -1;
    }
    else static if (isEqual!(Args[0 .. 2]))
    {
        enum ptrdiff_t indexOf = i;
    }
    else
    {
        enum ptrdiff_t indexOf = indexOf!(i + 1,
                                          AliasSeq!(Args[0], Args[2 .. $]));
    }
}

/**
 * Returns the index of the first occurrence of $(D_PARAM T) in $(D_PARAM L).
 * `-1` is returned if $(D_PARAM T) is not found.
 *
 * Params:
 *  T = The type to search for.
 *  L = Type list.
 *
 * Returns: The index of the first occurrence of $(D_PARAM T) in $(D_PARAM L).
 */
template staticIndexOf(T, L...)
{
    enum ptrdiff_t staticIndexOf = indexOf!(0, AliasSeq!(T, L));
}

/// Ditto.
template staticIndexOf(alias T, L...)
{
    enum ptrdiff_t staticIndexOf = indexOf!(0, AliasSeq!(T, L));
}

///
pure nothrow @safe @nogc unittest
{
    static assert(staticIndexOf!(int) == -1);
    static assert(staticIndexOf!(int, int) == 0);
    static assert(staticIndexOf!(int, float, double, int, real) == 2);
    static assert(staticIndexOf!(3, () {}, uint, 5, 3) == 3);
}

/**
 * Instantiates the template $(D_PARAM T) with $(D_PARAM ARGS).
 *
 * Params:
 *  T    = Template.
 *  Args = Template parameters.
 *
 * Returns: Instantiated template.
 */
alias Instantiate(alias T, Args...) = T!Args;

/**
 * Combines multiple templates with logical AND. So $(D_PSYMBOL templateAnd)
 * evaluates to $(D_INLINECODE Preds[0] && Preds[1] && Preds[2]) and so on.
 *
 * Empty $(D_PARAM Preds) evaluates to $(D_KEYWORD true).
 *
 * Params:
 *  Preds = Template predicates.
 *
 * Returns: The constructed template.
 */
template templateAnd(Preds...)
{
    template templateAnd(T...)
    {
        static if (Preds.length == 0)
        {
            enum bool templateAnd = true;
        }
        else static if (Instantiate!(Preds[0], T))
        {
            alias templateAnd = Instantiate!(.templateAnd!(Preds[1 .. $]), T);
        }
        else
        {
            enum bool templateAnd = false;
        }
    }
}

///
pure nothrow @safe @nogc unittest
{
    alias isMutableInt = templateAnd!(isIntegral, isMutable);
    static assert(isMutableInt!int);
    static assert(!isMutableInt!(const int));
    static assert(!isMutableInt!float);

    alias alwaysTrue = templateAnd!();
    static assert(alwaysTrue!int);

    alias isIntegral = templateAnd!(.isIntegral);
    static assert(isIntegral!int);
    static assert(isIntegral!(const int));
    static assert(!isIntegral!float);
}

/**
 * Combines multiple templates with logical OR. So $(D_PSYMBOL templateOr)
 * evaluates to $(D_INLINECODE Preds[0] || Preds[1] || Preds[2]) and so on.
 *
 * Empty $(D_PARAM Preds) evaluates to $(D_KEYWORD false).
 *
 * Params:
 *  Preds = Template predicates.
 *
 * Returns: The constructed template.
 */
template templateOr(Preds...)
{
    template templateOr(T...)
    {
        static if (Preds.length == 0)
        {
            enum bool templateOr = false;
        }
        else static if (Instantiate!(Preds[0], T))
        {
            enum bool templateOr = true;
        }
        else
        {
            alias templateOr = Instantiate!(.templateOr!(Preds[1 .. $]), T);
        }
    }
}

///
pure nothrow @safe @nogc unittest
{
    alias isMutableOrInt = templateOr!(isIntegral, isMutable);
    static assert(isMutableOrInt!int);
    static assert(isMutableOrInt!(const int));
    static assert(isMutableOrInt!float);
    static assert(!isMutableOrInt!(const float));

    alias alwaysFalse = templateOr!();
    static assert(!alwaysFalse!int);

    alias isIntegral = templateOr!(.isIntegral);
    static assert(isIntegral!int);
    static assert(isIntegral!(const int));
    static assert(!isIntegral!float);
}

/**
 * Params:
 *  pred = Template predicate.
 *
 * Returns: Negated $(D_PARAM pred).
 */
template templateNot(alias pred)
{
    enum bool templateNot(T...) = !pred!T;
}

///
pure nothrow @safe @nogc unittest
{
    alias isNotIntegral = templateNot!isIntegral;
    static assert(!isNotIntegral!int);
    static assert(isNotIntegral!(char[]));
}

/**
 * Tests whether $(D_PARAM L) is sorted in ascending order according to
 * $(D_PARAM cmp).
 *
 * $(D_PARAM cmp) can evaluate to:
 * $(UL
 *  $(LI $(D_KEYWORD bool): $(D_KEYWORD true) means
 *       $(D_INLINECODE a[i] < a[i + 1]).)
 *  $(LI $(D_KEYWORD int): a negative number means that
 *       $(D_INLINECODE a[i] < a[i + 1]), a positive number that
 *       $(D_INLINECODE a[i] > a[i + 1]), `0` if they equal.)
 * )
 *
 * Params:
 *  cmp = Sorting template predicate.
 *  L   = Elements to be tested.
 *
 * Returns: $(D_KEYWORD true) if $(D_PARAM L) is sorted, $(D_KEYWORD false)
 *          if not.
 */
template staticIsSorted(alias cmp, L...)
{
    static if (L.length <= 1)
    {
        enum bool staticIsSorted = true;
    }
    else
    {
        // `L` is sorted if the both halves and the boundary values are sorted.
        enum bool staticIsSorted = isLessEqual!(cmp, L[$ / 2 - 1], L[$ / 2])
                                && staticIsSorted!(cmp, L[0 .. $ / 2])
                                && staticIsSorted!(cmp, L[$ / 2 .. $]);
    }
}

///
pure nothrow @safe @nogc unittest
{
    enum cmp(T, U) = T.sizeof < U.sizeof;
    static assert(staticIsSorted!(cmp));
    static assert(staticIsSorted!(cmp, byte));
    static assert(staticIsSorted!(cmp, byte, ubyte, short, uint));
    static assert(!staticIsSorted!(cmp, long, byte, ubyte, short, uint));
}

private pure nothrow @safe @nogc unittest
{
    enum cmp(int x, int y) = x - y;
    static assert(staticIsSorted!(cmp));
    static assert(staticIsSorted!(cmp, 1));
    static assert(staticIsSorted!(cmp, 1, 2, 2));
    static assert(staticIsSorted!(cmp, 1, 2, 2, 4));
    static assert(staticIsSorted!(cmp, 1, 2, 2, 4, 8));
    static assert(!staticIsSorted!(cmp, 32, 2, 2, 4, 8));
    static assert(staticIsSorted!(cmp, 32, 32));
}

private pure nothrow @safe @nogc unittest
{
    enum cmp(int x, int y) = x < y;
    static assert(staticIsSorted!(cmp));
    static assert(staticIsSorted!(cmp, 1));
    static assert(staticIsSorted!(cmp, 1, 2, 2));
    static assert(staticIsSorted!(cmp, 1, 2, 2, 4));
    static assert(staticIsSorted!(cmp, 1, 2, 2, 4, 8));
    static assert(!staticIsSorted!(cmp, 32, 2, 2, 4, 8));
    static assert(staticIsSorted!(cmp, 32, 32));
}

/**
 * Params:
 *  T    = A template.
 *  Args = The first arguments for $(D_PARAM T).
 *
 * Returns: $(D_PARAM T) with $(D_PARAM Args) applied to it as its first
 *          arguments.
 */
template ApplyLeft(alias T, Args...)
{
    alias ApplyLeft(U...) = T!(Args, U);
}

///
pure nothrow @safe @nogc unittest
{
    alias allAreIntegral = ApplyLeft!(allSatisfy, isIntegral);
    static assert(allAreIntegral!(int, uint));
    static assert(!allAreIntegral!(int, float, uint));
}

/**
 * Params:
 *  T    = A template.
 *  Args = The last arguments for $(D_PARAM T).
 *
 * Returns: $(D_PARAM T) with $(D_PARAM Args) applied to it as itslast
 *          arguments.
 */
template ApplyRight(alias T, Args...)
{
    alias ApplyRight(U...) = T!(U, Args);
}

///
pure nothrow @safe @nogc unittest
{
    alias intIs = ApplyRight!(allSatisfy, int);
    static assert(intIs!(isIntegral));
    static assert(!intIs!(isUnsigned));
}

/**
 * Params:
 *  n = The number of times to repeat $(D_PARAM L).
 *  L = The sequence to be repeated.
 *
 * Returns: $(D_PARAM L) repeated $(D_PARAM n) times.
 */
template Repeat(size_t n, L...)
if (n > 0)
{
    static if (n == 1)
    {
        alias Repeat = L;
    }
    else
    {
        alias Repeat = AliasSeq!(L, Repeat!(n - 1, L));
    }
}

///
pure nothrow @safe @nogc unittest
{
    static assert(is(Repeat!(1, uint, int) == AliasSeq!(uint, int)));
    static assert(is(Repeat!(2, uint, int) == AliasSeq!(uint, int, uint, int)));
    static assert(is(Repeat!(3) == AliasSeq!()));
}

private template ReplaceOne(L...)
{
    static if (L.length == 2)
    {
        alias ReplaceOne = AliasSeq!();
    }
    else static if (isEqual!(L[0], L[2]))
    {
        alias ReplaceOne = AliasSeq!(L[1], L[3 .. $]);
    }
    else
    {
        alias ReplaceOne = AliasSeq!(L[2], ReplaceOne!(L[0], L[1], L[3 .. $]));
    }
}

/**
 * Replaces the first occurrence of $(D_PARAM T) in $(D_PARAM L) with
 * $(D_PARAM U).
 *
 * Params:
 *  T = The symbol to be replaced.
 *  U = Replacement.
 *  L = List of symbols.
 *
 * Returns: $(D_PARAM L) with the first occurrence of $(D_PARAM T) replaced.
 */
template Replace(T, U, L...)
{
    alias Replace = ReplaceOne!(T, U, L);
}

/// Ditto.
template Replace(alias T, U, L...)
{
    alias Replace = ReplaceOne!(T, U, L);
}

/// Ditto.
template Replace(T, alias U, L...)
{
    alias Replace = ReplaceOne!(T, U, L);
}

/// Ditto.
template Replace(alias T, alias U, L...)
{
    alias Replace = ReplaceOne!(T, U, L);
}

///
pure nothrow @safe @nogc unittest
{
    static assert(is(Replace!(int, uint, int) == AliasSeq!(uint)));
    static assert(is(Replace!(int, uint, short, int, int, ushort)
               == AliasSeq!(short, uint, int, ushort)));

    static assert(Replace!(5, 8, 1, 2, 5, 5) == AliasSeq!(1, 2, 8, 5));
}

private template ReplaceAllImpl(L...)
{
    static if (L.length == 2)
    {
        alias ReplaceAllImpl = AliasSeq!();
    }
    else
    {
        private alias Rest = ReplaceAllImpl!(L[0], L[1], L[3 .. $]);
        static if (isEqual!(L[0], L[2]))
        {
            alias ReplaceAllImpl = AliasSeq!(L[1], Rest);
        }
        else
        {
            alias ReplaceAllImpl = AliasSeq!(L[2], Rest);
        }
    }
}

/**
 * Replaces all occurrences of $(D_PARAM T) in $(D_PARAM L) with $(D_PARAM U).
 *
 * Params:
 *  T = The symbol to be replaced.
 *  U = Replacement.
 *  L = List of symbols.
 *
 * Returns: $(D_PARAM L) with all occurrences of $(D_PARAM T) replaced.
 */
template ReplaceAll(T, U, L...)
{
    alias ReplaceAll = ReplaceAllImpl!(T, U, L);
}

/// Ditto.
template ReplaceAll(alias T, U, L...)
{
    alias ReplaceAll = ReplaceAllImpl!(T, U, L);
}

/// Ditto.
template ReplaceAll(T, alias U, L...)
{
    alias ReplaceAll = ReplaceAllImpl!(T, U, L);
}

/// Ditto.
template ReplaceAll(alias T, alias U, L...)
{
    alias ReplaceAll = ReplaceAllImpl!(T, U, L);
}

///
pure nothrow @safe @nogc unittest
{
    static assert(is(ReplaceAll!(int, uint, int) == AliasSeq!(uint)));
    static assert(is(ReplaceAll!(int, uint, short, int, int, ushort)
               == AliasSeq!(short, uint, uint, ushort)));

    static assert(ReplaceAll!(5, 8, 1, 2, 5, 5) == AliasSeq!(1, 2, 8, 8));
}

/**
 * Params:
 *  L = List of symbols.
 *
 * Returns: $(D_PARAM L) with elements in reversed order.
 */
template Reverse(L...)
{
    static if (L.length == 0)
    {
        alias Reverse = AliasSeq!();
    }
    else
    {
        alias Reverse = AliasSeq!(L[$ - 1], Reverse!(L[0 .. $ - 1]));
    }
}

///
pure nothrow @safe @nogc unittest
{
    static assert(is(Reverse!(byte, short, int) == AliasSeq!(int, short, byte)));
}

/**
 * Applies $(D_PARAM F) to all elements of $(D_PARAM T).
 *
 * Params:
 *  F = Template predicate.
 *  T = List of symbols.
 *
 * Returns: Elements $(D_PARAM T) after applying $(D_PARAM F) to them.
 */
template staticMap(alias F, T...)
{
    static if (T.length == 0)
    {
        alias staticMap = AliasSeq!();
    }
    else
    {
        alias staticMap = AliasSeq!(F!(T[0]), staticMap!(F, T[1 .. $]));
    }
}

///
pure nothrow @safe @nogc unittest
{
    static assert(is(staticMap!(Unqual, const int, immutable short)
               == AliasSeq!(int, short)));
}

/**
 * Sorts $(D_PARAM L) in ascending order according to $(D_PARAM cmp).
 *
 * $(D_PARAM cmp) can evaluate to:
 * $(UL
 *  $(LI $(D_KEYWORD bool): $(D_KEYWORD true) means
 *       $(D_INLINECODE a[i] < a[i + 1]).)
 *  $(LI $(D_KEYWORD int): a negative number means that
 *       $(D_INLINECODE a[i] < a[i + 1]), a positive number that
 *       $(D_INLINECODE a[i] > a[i + 1]), `0` if they equal.)
 * )
 *
 * Merge sort is used to sort the arguments.
 *
 * Params:
 *  cmp = Sorting template predicate.
 *  L   = Elements to be sorted.
 *
 * Returns: Elements of $(D_PARAM L) in ascending order.
 *
 * See_Also: $(LINK2 https://en.wikipedia.org/wiki/Merge_sort, Merge sort).
 */
template staticSort(alias cmp, L...)
{
    private template merge(size_t A, size_t B)
    {
        static if (A + B == L.length)
        {
            alias merge = AliasSeq!();
        }
        else static if (B >= Right.length
                     || (A < Left.length && isLessEqual!(cmp, Left[A], Right[B])))
        {
            alias merge = AliasSeq!(Left[A], merge!(A + 1, B));
        }
        else
        {
            alias merge = AliasSeq!(Right[B], merge!(A, B + 1));
        }
    }

    static if (L.length <= 1)
    {
        alias staticSort = L;
    }
    else
    {
        private alias Left = staticSort!(cmp, L[0 .. $ / 2]);
        private alias Right = staticSort!(cmp, L[$ / 2 .. $]);
        alias staticSort = merge!(0, 0);
    }
}

///
pure nothrow @safe @nogc unittest
{
    enum cmp(T, U) = T.sizeof < U.sizeof;
    static assert(is(staticSort!(cmp, long, short, byte, int)
               == AliasSeq!(byte, short, int, long)));
}

private pure nothrow @safe @nogc unittest
{
    enum cmp(int T, int U) = T - U;
    static assert(staticSort!(cmp, 5, 17, 9, 12, 2, 10, 14)
               == AliasSeq!(2, 5, 9, 10, 12, 14, 17));
}

private enum bool DerivedToFrontCmp(A, B) = is(A : B);

/**
 * Returns $(D_PARAM L) sorted in such a way that the most derived types come
 * first.
 *
 * Params:
 *  L = Type tuple.
 *
 * Returns: Sorted $(D_PARAM L).
 */
template DerivedToFront(L...)
{
    alias DerivedToFront = staticSort!(DerivedToFrontCmp, L);
}

///
pure nothrow @safe @nogc unittest
{
    class A
    {
    }
    class B : A
    {
    }
    class C : B
    {
    }
    static assert(is(DerivedToFront!(B, A, C) == AliasSeq!(C, B, A)));
}

/**
 * Returns the type from the type tuple $(D_PARAM L) that is most derived from
 * $(D_PARAM T).
 *
 * Params:
 *  T = The type to compare to.
 *  L = Type tuple.
 *
 * Returns: The type most derived from $(D_PARAM T).
 */
template MostDerived(T, L...)
{
    static if (L.length == 0)
    {
        alias MostDerived = T;
    }
    else static if (is(T : L[0]))
    {
        alias MostDerived = MostDerived!(T, L[1 .. $]);
    }
    else
    {
        alias MostDerived = MostDerived!(L[0], L[1 .. $]);
    }
}

///
pure nothrow @safe @nogc unittest
{
    class A
    {
    }
    class B : A
    {
    }
    class C : B
    {
    }
    static assert(is(MostDerived!(A, C, B) == C));
}

private template EraseOne(L...)
if (L.length > 0)
{
    static if (L.length == 1)
    {
        alias EraseOne = AliasSeq!();
    }
    else static if (isEqual!(L[0 .. 2]))
    {
        alias EraseOne = AliasSeq!(L[2 .. $]);
    }
    else
    {
        alias EraseOne = AliasSeq!(L[1], EraseOne!(L[0], L[2 .. $]));
    }
}

/**
 * Removes the first occurrence of $(D_PARAM T) from the alias sequence
 * $(D_PARAL L).
 *
 * Params:
 *  T = The item to be removed.
 *  L = Alias sequence.
 *
 * Returns: $(D_PARAM L) with the first occurrence of $(D_PARAM T) removed.
 */
template Erase(T, L...)
{
    alias Erase = EraseOne!(T, L);
}

/// Ditto.
template Erase(alias T, L...)
{
    alias Erase = EraseOne!(T, L);
}

///
pure nothrow @safe @nogc unittest
{
    static assert(is(Erase!(int, short, int, int, uint) == AliasSeq!(short, int, uint)));
    static assert(is(Erase!(int, short, uint) == AliasSeq!(short, uint)));
}

private template EraseAllImpl(L...)
{
    static if (L.length == 1)
    {
        alias EraseAllImpl = AliasSeq!();
    }
    else static if (isEqual!(L[0 .. 2]))
    {
        alias EraseAllImpl = EraseAllImpl!(L[0], L[2 .. $]);
    }
    else
    {
        alias EraseAllImpl = AliasSeq!(L[1], EraseAllImpl!(L[0], L[2 .. $]));
    }
}

/**
 * Removes all occurrences of $(D_PARAM T) from the alias sequence $(D_PARAL L).
 *
 * Params:
 *  T = The item to be removed.
 *  L = Alias sequence.
 *
 * Returns: $(D_PARAM L) with all occurrences of $(D_PARAM T) removed.
 */
template EraseAll(T, L...)
{
    alias EraseAll = EraseAllImpl!(T, L);
}

/// Ditto.
template EraseAll(alias T, L...)
{
    alias EraseAll = EraseAllImpl!(T, L);
}

///
pure nothrow @safe @nogc unittest
{
    static assert(is(EraseAll!(int, short, int, int, uint) == AliasSeq!(short, uint)));
    static assert(is(EraseAll!(int, short, uint) == AliasSeq!(short, uint)));
    static assert(is(EraseAll!(int, int, int) == AliasSeq!()));
}

/**
 * Returns an alias sequence which contains only items that satisfy the
 * condition $(D_PARAM pred).
 *
 * Params:
 *  pred = Template predicate.
 *  L    = Alias sequence.
 *
 * Returns: $(D_PARAM L) filtered so that it contains only items that satisfy
 *          $(D_PARAM pred).
 */
template Filter(alias pred, L...)
{
    static if (L.length == 0)
    {
        alias Filter = AliasSeq!();
    }
    else static if (pred!(L[0]))
    {
        alias Filter = AliasSeq!(L[0], Filter!(pred, L[1 .. $]));
    }
    else
    {
        alias Filter = Filter!(pred, L[1 .. $]);
    }
}

///
pure nothrow @safe @nogc unittest
{
    static assert(is(Filter!(isIntegral, real, int, bool, uint) == AliasSeq!(int, uint)));
}

/**
 * Removes all duplicates from the alias sequence $(D_PARAM L).
 *
 * Params:
 *  L = Alias sequence.
 *
 * Returns: $(D_PARAM L) containing only unique items.
 */
template NoDuplicates(L...)
{
    static if (L.length == 0)
    {
        alias NoDuplicates = AliasSeq!();
    }
    else
    {
        private alias Rest = NoDuplicates!(EraseAll!(L[0], L[1 .. $]));
        alias NoDuplicates = AliasSeq!(L[0], Rest);
    }
}

///
pure nothrow @safe @nogc unittest
{
    alias Types = AliasSeq!(int, uint, int, short, short, uint);
    static assert(is(NoDuplicates!Types == AliasSeq!(int, uint, short)));
}

/**
 * Converts an input range $(D_PARAM range) into an alias sequence.
 *
 * Params:
 *  range = Input range.
 *
 * Returns: Alias sequence with items from $(D_PARAM range).
 */
template aliasSeqOf(alias range)
{
    static if (isArray!(typeof(range)))
    {
        static if (range.length == 0)
        {
            alias aliasSeqOf = AliasSeq!();
        }
        else
        {
            alias aliasSeqOf = AliasSeq!(range[0], aliasSeqOf!(range[1 .. $]));
        }
    }
    else
    {
        ReturnType!(typeof(&range.front))[] toArray(typeof(range) range)
        {
            typeof(return) result;
            foreach (r; range)
            {
                result ~= r;
            }
            return result;
        }
        alias aliasSeqOf = aliasSeqOf!(toArray(range));
    }
}

///
pure nothrow @safe @nogc unittest
{
    static assert(aliasSeqOf!([0, 1, 2, 3]) == AliasSeq!(0, 1, 2, 3));
}

/**
 * Produces a alias sequence consisting of every $(D_PARAM n)th element of
 * $(D_PARAM Args), starting with the first.
 *
 * Params:
 *  n    = Step.
 *  Args = The items to stride.
 *
 * Returns: Alias sequence of every $(D_PARAM n)th element of $(D_PARAM Args).
 */
template Stride(size_t n, Args...)
if (n > 0)
{
    static if (Args.length > n)
    {
        alias Stride = AliasSeq!(Args[0], Stride!(n, Args[n .. $]));
    }
    else static if (Args.length > 0)
    {
        alias Stride = AliasSeq!(Args[0]);
    }
    else
    {
        alias Stride = AliasSeq!();
    }
}

///
pure nothrow @safe @nogc unittest
{
    static assert(Stride!(3, 1, 2, 3, 4, 5, 6, 7, 8) == AliasSeq!(1, 4, 7));
    static assert(Stride!(2, 1, 2, 3) == AliasSeq!(1, 3));
    static assert(Stride!(2, 1, 2) == AliasSeq!(1));
    static assert(Stride!(2, 1) == AliasSeq!(1));
    static assert(Stride!(1, 1, 2, 3) == AliasSeq!(1, 2, 3));
    static assert(is(Stride!3 == AliasSeq!()));
}

/**
 * Aliases itself to $(D_INLINECODE T[0]) if $(D_PARAM cond) is $(D_KEYWORD true),
 * to $(D_INLINECODE T[1]) if $(D_KEYWORD false).
 *
 * Params:
 *  cond = Template predicate.
 *  T    = Two arguments.
 *
 * Returns: $(D_INLINECODE T[0]) if $(D_PARAM cond) is $(D_KEYWORD true),
 * $(D_INLINECODE T[1]) otherwise.
 */
template Select(bool cond, T...)
if (T.length == 2)
{
    static if (condition)
    {
        alias Select = L[0];
    }
    else
    {
        alias Select = L[1];
    }
}
