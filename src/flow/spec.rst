What
====

This is a specification for programming language Flow.

The general idea behind Flow is that many problems may be represented as parsing (matching) streams of data. Here both parsing and streams a


Author: Sergey Shepelev temotor@gmail.com
Huge thanks to Ryah Dahl (http://tinyclouds.org/) for early discussions on this.
Written in August 2009.


Types
=====

Data type declaration syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

"type" Name Par* "=" constructor+"|"
constructor = Name Par* | atom | magic-number | magic-string | list-comprehension | something-else? # TODO

    type bool = true | false

    type BooList a = BL-false | [a]

For convenience, type constructors may claim some atoms without special `:` syntax. When names clash, consider using `:atom` syntax in constructors.

In any syntax, when some atom is claimed by data type constructor, it obviously, can not be used in other data type constructor, and the atom becomes typed.

* bool
* int
* long
* char
* byte
* bucket a
  Unordered container of `a`.

    interface bucket a is Len a
        self.peek :: Maybe a
        self.put :: a -> self
        self.remove :: a -> self
        self.take :: a
        (+) :: self -> self -> self
        (-) :: self -> self -> self
        (|) :: self -> self -> self
        (&) :: self -> self -> self
        (in) :: self -> a -> bool

* list a
  Ordered sequence of `a`

    interface list a is bucket a
        self.append :: a -> self
        self.insert :: int -> a -> self
        self.find :: a -> Maybe int
        self.remove-at :: int -> self

* string = list char
* bytes = list byte
* set a
  Unordered unique bucket of `a`

    interface set a is bucket a

  That is, sets and buckets differ only in implementation.

* dict a b
  Unordered bucket of `a to b` mappings, unique and indexed by `a`.
* Any - special type for type parameters
  When declaring your functions, parsers and streams, use this type parameter, unless you're sure what type you want.

* Stream a (InStream a, OutStream a)
  Parameterized stream of data of type `a`.
  InStream and OutStream have `queue` interface.
  Stream has `dequeue` interface.

Transformers
^^^^^^^^^^^^

Transformers are convert-constructors to types.

Transformer is a function that converts value of one type into same or close value of another type. I.e. string encoding is done by transformer.

`(trans) :: a -> b` (sometimes more arguments) is a declaration of transformer that takes value of type `a` and returns the same or close value of `B`.

Transformers correspond to type casts in other programming languages. Exception is that Flow transformers may have additional arguments. All type casts are explicit. You must write `if bool size`. But `if size > 0` is clearer and less error-prone.

`Any -> Any` is a pretty much utopian transformer. Would be great to have one.

`int -> bool` transformer is defined as::

    implement bool
        (trans) :: int -> bool
                   0 = false
                   _ = true

Backwards `int -> bool` transformer is defined as::

    implement int
        (trans) :: bool -> int
                   false = 0
                   true = 1

Obviously, `string -> bytes` and vice versa transformer requires an encoding. You may set a global encoding (although, global state is evil, default encoding of UTF-8 is good) or pass encoding to transformer::

    do global.string.set-encoding cp1251
    bs = bytes "Unicode foo bar"

    bs = bytes "Unicode foo bar" ascii

`string -> bytes` is defined as::

    implement bytes
        (trans) :: string -> bytes
                s = bytes s global.string.get-encoding
        (trans) :: string -> atom -> bytes
                s enc = map bytes s

So it iterates `char -> bytes` transformer. Note that one character may be converted into one or several bytes, depending on encoding (i.e. char in UTF-8 may be more than 1 byte, while char in UTF-16 is always at least two bytes).

There may be transformers `char -> byte` for some encodings. If character requires more than one byte, that transformer will fail.

Parsers
=======

`Parser a` is a parametrized state machine that works with values of type `a`. Usually, you want either `Parser char` or `Parser byte`. Be careful: `Parser string` sounds better, but it would expect stream of strings, while, for example, stdin is a stream of bytes. Of course, transformers from one stream to another are possible.

There is a bunch of built-in parsers::

    any :: Parser Any

`any` is a no-op state machine that accepts infinite number of values of any type.

    alpha :: Parser char = [A-Za-z]*

`alpha` is a no-op parser that accepts infinite number of alphabet letters. Given pseudo-code is not full, since only English letters are listed. In fact, since `char` type represents a Unicode character, `alpha` parser recognizes any number of Unicode characters.

When parser meets unexpected value, it fails. See parsing failures.

Every 'parsing' (streaming data through parser) instantiates a new state - storage for internal and exposed variables of parser. In all other ways, parser is just a pure function. Simple parsers like `any`, `alpha` don't need to hold any state so they don't instantiate one and so they are pure functions.

Interfaces
==========

Interface (type class in Haskell) is a declaration-only of complete set of functionality. For example, interface `bool` declares a data type and operators to work with boolean values.

Modules declare and implement interfaces. Single module may declare and/or define one or more interfaces.
Formal module-interface relationship (note, this doesn't mean that module may only consist of interfaces)::

    module = (interface-decl | interface-def)*

Interface declaration syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    "interface" Name Par* inheritance? declaration*
    inheritance = "is" Interface-Name+","
    declaration = newline indent (Self-Name ".")? function-decl

    interface Eq a
        (==) :: a -> a -> bool
        (!=) :: a -> a -> bool

    interface Len a
        # these two are equivalent
        len :: Len a -> int
        self.len :: int

Interface definition syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^

    "implement" Interface-Name declaration? definition*
    definition = newline indent (Self-Name ".")? function-def

    implement Eq bool
        (==) true true   = true
             false false = true
             _           = false

Dot-syntax
^^^^^^^^^^

In either declaration or definition of interface it is possible to use dot-syntax with any leading name, but "self" or "this" is preferred for convenience. `self.func :: arg-type -> result-type` is equivalent for `func :: self -> arg-type -> result-type`. `self` is expanded to interface name. So it means, that `func` is declared with implicit first argument of type [current interface].

Accordingly, calling, i.e. `"foo".length` is same as string.length "foo". This allows to use same function names in multiple interfaces without clashes because each interface is a separate namespace.

Data types - interface relation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Data types and interfaces are closely related. Interfaces describe set of operations that are possible on some data. Interfaces are meant to supply final set of functionality (despite it can be extended in your program), so they must be self-contained, ready to use. But making too bloated interfaces is as bad for extensibility as too small ones. Make small, narrow, featured interfaces. I.e. interface 'Len a' has only one function.

Each data type is an implicit interface::

    type Foo = F | B

implies

    interface Foo
        F :: Foo
        B :: Foo

This means that both `data` type definition and interface inherited from other type effectively create new type interface::

    type Foo = true | false

    interface Foo is bool

here, both lines create interface `Foo`. But first line creates both new data type *and* interface. Choosing between two, you should select data type when you have some set (or range) of values to hold; select interface when you define a set of operations on data.

`int`, `bool`, etc are interfaces. You may reimplement any, including built-in interface in some other way and tell compiler to prefer new implementation. You may also, extend declaration of your type's interface: add inheritance from other interfaces or just add some operations::

    type TriBool = TriTrue | TriFalse | Unsure

    interface TriBool is bool
        # implied
        # TriTrue :: TriBool
        # TriFalse :: TriBool
        # Unsure :: TriBool

        (trans) :: TriBool -> bool
        is-unsure :: TriBool -> bool

Type interfaces usually include transformers to and from its type. But you may also declare and implement new transformer outside of type interface, right in your program. Flow will use it.

Inheritance
^^^^^^^^^^^

    interface Foo is Bar

declares interface `Foo` which inherits functions declarations from `Bar`. Implementation is inherited through dispatching: if child doesn't override parent functions, parent functions are used. Note, this is implicit cast to more generic (base) interface. This may not be always what you want.

Inheritance from type interfaces is a bit special: no parent constructors are inherited. All other functions are inherited. Same function names in child interface hide parent functions (like Python methods, like `virtual` methods in C++).

Calling parent functions is as simple as, well, calling functions::

    interface WrongLenString is string

    implement WrongLenString
        self.len = (string.len self) + 2

Stream
======

Stream is a special type of interface. There are 3 types of streams: `InStream` (read-only), `OutStream` (write-only) and `Stream` (read-write). Streams are used together with Parsers to process flow of data. Many real world tasks may be framed as parsing flow of data. I.e. UNIX utility *head*. It looks for newline chars in input stream and puts first n lines to output stream.

    interface InStream a
        self.get :: a
        self.peek :: Maybe a

    interface OutStream a
        self.put :: a -> bool
        self.flush :: bool
        self.copy :: InStream a -> OutStream a

    interface Stream a is InStream a, OutStream a

Built-in `<<` operator is used to apply a parser to `InStream`::

    (<<) :: Parser a -> InStream a -> OutStream Any

this is very similar to Haskell's `liftM` function. What it does is parses input stream with parser and produces `OutStream` with results of parsing.

Execution model
===============

Flow compiles modules into directed graphs of expressions, i.e. this code::

    print x = pipe x id stdout
    main = do print "foo"

May be compiled to following graph:

      /-> "foo" -\
main -            -> copy stdout "foo"
      \-> stdout /

Here string "foo" and expression `stdout` are evaluated first, then `copy stdout "foo"` is evaluated. First two may be parallelized because both are pure, but compiler would host constant string in first place so there's nothing to evaluate for it. `stdout` is opened by parent shell, there's nothing to do for that expression either. All useful job will happen only in `copy` function.

`do` keyword blocks current thread (light) until following expression is fully evaluated. Without it, a pipe between string and stdout would be established, but probably, no bytes will be transfered because program has nothing else to do and finishes so fast.

Questions
=========

`list` looks very similar to `Stream`. Is there a point to create a new type?
