/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Type constructors.
 *
 * This module contains templates that allow to build new types from the
 * available ones.
 *
 * Copyright: Eugene Wissner 2017-2020.
 * License: $(LINK2 https://www.mozilla.org/en-US/MPL/2.0/,
 *                  Mozilla Public License, v. 2.0).
 * Authors: $(LINK2 mailto:info@caraus.de, Eugene Wissner)
 * Source: $(LINK2 https://github.com/caraus-ecms/tanya/blob/master/source/tanya/typecons.d,
 *                 tanya/typecons.d)
 */
module tanya.typecons;

import tanya.format;
import tanya.memory.lifetime;
import tanya.meta.metafunction;
import tanya.meta.trait;

/**
 * $(D_PSYMBOL Tuple) can store two or more heterogeneous objects.
 *
 * The objects can by accessed by index as `obj[0]` and `obj[1]` or by optional
 * names (e.g. `obj.first`).
 *
 * $(D_PARAM Specs) contains a list of object types and names. First
 * comes the object type, then an optional string containing the name.
 * If you want the object be accessible only by its index (`0` or `1`),
 * just skip the name.
 *
 * Params:
 *  Specs = Field types and names.
 *
 * See_Also: $(D_PSYMBOL tuple).
 */
template Tuple(Specs...)
{
    template parseSpecs(size_t fieldCount, Specs...)
    {
        static if (Specs.length == 0)
        {
            alias parseSpecs = AliasSeq!();
        }
        else static if (is(Specs[0]) && fieldCount < 2)
        {
            static if (is(typeof(Specs[1]) == string))
            {
                alias parseSpecs
                    = AliasSeq!(Pack!(Specs[0], Specs[1]),
                                parseSpecs!(fieldCount + 1, Specs[2 .. $]));
            }
            else
            {
                alias parseSpecs
                    = AliasSeq!(Pack!(Specs[0]),
                                parseSpecs!(fieldCount + 1, Specs[1 .. $]));
            }
        }
        else
        {
            static assert(false, "Invalid argument: " ~ Specs[0].stringof);
        }
    }

    alias ChooseType(alias T) = T.Seq[0];
    alias ParsedSpecs = parseSpecs!(0, Specs);

    static assert(ParsedSpecs.length > 1, "Invalid argument count");

    private string formatAliases(size_t n, Specs...)()
    {
        static if (Specs.length == 0)
        {
            return "";
        }
        else
        {
            string fieldAlias;
            static if (Specs[0].length == 2)
            {
                char[21] buffer;
                fieldAlias = "alias " ~ Specs[0][1] ~ " = expand["
                           ~ integral2String(n, buffer).idup ~ "];";
            }
            return fieldAlias ~ formatAliases!(n + 1, Specs[1 .. $])();
        }
    }

    struct Tuple
    {
        /// Field types.
        alias Types = Map!(ChooseType, ParsedSpecs);

        // Create field aliases.
        mixin(formatAliases!(0, ParsedSpecs[0 .. $])());

        /// Represents the values of the $(D_PSYMBOL Tuple) as a list of values.
        Types expand;

        alias expand this;
    }
}

///
@nogc nothrow pure @safe unittest
{
    auto pair = Tuple!(int, "first", string, "second")(1, "second");
    assert(pair.first == 1);
    assert(pair[0] == 1);
    assert(pair.second == "second");
    assert(pair[1] == "second");
}

/**
 * Creates a new $(D_PSYMBOL Tuple).
 *
 * Params:
 *  Names = Field names.
 *
 * See_Also: $(D_PSYMBOL Tuple).
 */
template tuple(Names...)
{
    /**
     * Creates a new $(D_PSYMBOL Tuple).
     *
     * Params:
     *  Args = Field types.
     *  args = Field values.
     *
     * Returns: Newly created $(D_PSYMBOL Tuple).
     */
    auto tuple(Args...)(auto ref Args args)
    if (Args.length >= Names.length && isTypeTuple!Args)
    {
        alias Zipped = ZipWith!(AliasSeq, Pack!Args, Pack!Names);
        alias Nameless = Args[Names.length .. $];

        return Tuple!(Zipped, Nameless)(forward!args);
    }
}

///
@nogc nothrow pure @safe unittest
{
    auto t = tuple!("one", "two")(20, 5);
    assert(t.one == 20);
    assert(t.two == 5);
}
