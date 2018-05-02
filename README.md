# A modern and consistent Common Lisp string manipulation library

    (ql:quickload "str")

Why ?

* modernity, simplicity and discoverability:

  - `(str:trim s)` instead of `  (string-trim '(#\Space #\Newline #\Backspace #\Tab #\Linefeed #\Page #\Return #\Rubout) s))`,
or `str:concat strings` instead of an unusual `format` construct; one discoverable library instead of many;

* consistance and composability, where `s` is always the last argument, which makes it
  easier to feed pipes and arrows.

The only dependency is `cl-ppcre`.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->

**Table of Contents**

- [A modern and consistent Common Lisp string manipulation library](#a-modern-and-consistent-common-lisp-string-manipulation-library)
    - [Install](#install)
    - [Functions](#functions)
        - [Tweak whitespace](#tweak-whitespace)
            - [trim `(s)`](#trim-s)
        - [To longer strings](#to-longer-strings)
            - [join `(separator list-of-strings)`](#join-separator-list-of-strings)
            - [concat `(&rest strings)`](#concat-rest-strings)
            - [repeat `(count s)`](#repeat-count-s)
            - [add-prefix, add-suffix `(items s)` (new in 0.9)](#add-prefix-add-suffix-items-s-new-in-09)
        - [To shorter strings](#to-shorter-strings)
            - [substring `(start end s)`](#substring-start-end-s)
            - [s-first `(s)`](#s-first-s)
            - [s-rest `(s)`](#s-rest-s)
            - [s-nth `(n s)`](#s-nth-n-s)
        - [To and from lists](#to-and-from-lists)
            - [words `(s)`](#words-s)
            - [unwords `(strings)`](#unwords-strings)
            - [lines `(s)`](#lines-s)
            - [unlines `(strings)`](#unlines-strings)
            - [split `(separator s &key omit-nulls)`](#split-separator-s-key-omit-nulls)
            - [split-omit-nulls  (in v0.6, QL january 2018)](#split-omit-nulls--in-v06-ql-january-2018)
        - [To and from files (experimental in v0.4)](#to-and-from-files-experimental-in-v04)
            - [from-file `(filename)`](#from-file-filename)
            - [to-file `(filename s)`](#to-file-filename-s)
        - [Predicates](#predicates)
            - [empty?, emptyp `(s)`](#empty-emptyp-s)
            - [blank?, blankp `(s)`](#blank-blankp-s)
            - [starts-with?, starts-with-p `(start s &key ignore-case)`](#starts-with-starts-with-p-start-s-key-ignore-case)
            - [ends-with?, ends-with-p `(end s &key ignore-case)`](#ends-with-ends-with-p-end-s-key-ignore-case)
            - [contains?, containsp `(substring s &key (ignore-case nil))`](#contains-containsp-substring-s-key-ignore-case-nil)
            - [prefix?, prefixp and suffix?, suffixp `(items s)` (new in 0.9)](#prefix-prefixp-and-suffix-suffixp-items-s-new-in-09)
        - [Others](#others)
            - [replace-all `(old new s)`](#replace-all-old-new-s)
            - [prefix `(list-of-strings)` (renamed in 0.9)](#prefix-list-of-strings-renamed-in-09)
            - [suffix `(list-of-strings)` (new in 0.9)](#suffix-list-of-strings-new-in-09)
    - [Macros](#macros)
        - [string-case (new in v0.8, Quicklisp end of february 2018)](#string-case-new-in-v08-quicklisp-end-of-february-2018)
    - [Changelog](#changelog)
    - [Dev and test](#dev-and-test)
    - [See also](#see-also)

<!-- markdown-toc end -->

## Install

Install with [Quicklisp](https://www.quicklisp.org/beta/):

    (ql:quickload :str)

Check its version:

    (str:version)

To get a newer version, you need to update the Quicklisp dist (think
of QL as Debian's apt rather than pip/npm/etc):

    (ql:update-dist "quicklisp")

beware, this is a young and unstable library. (update v0.7) The
functions implementation may change, but we shouldn't change the api.

(don't have a full Common Lisp development environment yet ? Get
[Portacle](https://shinmera.github.io/portacle/), a portable and
multiplatform development environment shipping Emacs, Quicklisp, SBCL
and Git).

## Functions

### Tweak whitespace

#### trim `(s)`
Remove whitespaces at the beginning and end of `s`.

```cl
(trim "  rst  ") ;; => "rst"
```

Also `trim-left` and `trim-right`.

Uses the built-in
[string-trim](https://lispcookbook.github.io/cl-cookbook/strings.html#trimming-blanks-from-the-ends-of-a-string)
where whitespaces are `'(#\Space #\Newline #\Backspace #\Tab #\Linefeed #\Page #\Return #\Rubout)`.

### To longer strings

#### join `(separator list-of-strings)`

Join strings in list `list-of-strings` with `separator` in between.

```cl
(join " " '("foo" "bar" "baz")) ;; => "foo bar baz"
```

Uses a specific [format](http://jtra.cz/stuff/lisp/sclr/format.html) syntax.

#### concat `(&rest strings)`

Join strings into one.

```cl
(concat "f" "o" "o") ;; => "foo"
```

Simple call of the built-in [concatenate](https://lispcookbook.github.io/cl-cookbook/strings.html#concatenating-strings).

#### repeat `(count s)`

Make a string of `s` repeated `count` times.

```cl
(repeat 3 "foo") ;; => "foofoofoo"
```

#### add-prefix, add-suffix `(items s)` (new in 0.9)

Respectively prepend or append `s` to the front of each item.


### To shorter strings

#### substring `(start end s)`

Return the substring of `s` from `start` to `end`.

It uses `subseq` with differences:

* argument order, s at the end
* `start` and `end` can be lower than 0 or bigger than the length of s.
* for convenience `end` can be nil or t to denote the end of the string.

Examples:

```lisp
  (is "abcd" (substring 0 t "abcd") "t denotes the end of the string")
  (is "abcd" (substring 0 nil "abcd") "nil too")
  (is "abcd" (substring 0 100 "abcd") "end can be too large")
  (is "abc" (substring 0 -1 "abcd") "end can be negative. Counts from the end.")
  (is "" (substring 0 -100 "abcd") "end can be negative and too low")
  (is "" (substring 100 1 "abcd") "start can be too big")
  (is "abcd" (substring -100 4 "abcd") "start can also be too low")
  (is "" (substring 2 1 "abcd") "start is bigger than end")
```

#### s-first `(s)`

Return the first letter of `s`.


Examples:

```lisp
  (s-first "foobar") ;; => "f"
  (s-first "") ;; => ""
```

#### s-rest `(s)`

Return the rest substring of `s`.

Examples:

```lisp
  (s-rest "foobar") ;; => "oobar"
  (s-rest "") ;; => ""
```

#### s-nth `(n s)`

Return the nth letter of `s`.

Examples:

```lisp
  (s-nth 3 "foobar") ;; => "b"
  (s-nth 3 "") ;; => ""
```

### To and from lists

#### words `(s)`

Return list of words, which were delimited by whitespace.

#### unwords `(strings)`

Join the list of strings with a whitespace.

#### lines `(s)`

Split string by newline character and return list of lines.

#### unlines `(strings)`

Join the list of strings with a newline character.

#### split `(separator s &key omit-nulls)`

Split into subtrings (unlike cl-ppcre, without a regexp). If
`omit-nulls` is non-nil, zero-length substrings are omitted.

```cl
(split "+" "foo++bar") ;; => ("foo" "" "bar")
(split "+" "foo++bar" :omit-nulls t) ;; => ("foo" "bar")
```

Wrapper around [cl-ppcre:split](http://weitz.de/cl-ppcre/#split) but:

- our separator is a simple string, where cl-ppcre takes a regexp,
- we fix an inconsistency:

```
(cl-ppcre:split "," ",a,b,,c,") ;; => ("" "a" "b" "" "c")
```

and we return a trailing `""`:

    (split "," ",a,b,,c,") ;; => ("" "a" "b" "" "c" "")

#### split-omit-nulls  (in v0.6, QL january 2018)

Because it is a common pattern and it can be clearer than an option
coming after many parenthesis.


### To and from files (experimental in v0.4)

#### from-file `(filename)`

Read the file and return its content as a string.

Example: `(str:from-file "path/to/file.txt")`.

`:external-format`: if nil, the system default. Can be bound to `:utf-8`.

But you might just call
[uiop's `uiop:read-file-string`](https://github.com/fare/asdf/blob/master/uiop/stream.lisp#L445)
directly.

There is also `uiop:read-file-lines`.

#### to-file `(filename s)`

Write the string `s` to the file `filename`. If the file does not
exist, create it, if it already exists, replace it.

Options:

* `:if-does-not-exist`: `:create` (default), `:error`
* `:if-exists`: `:supersede` (default), `:append`, `:overwrite`, `:rename`, `:error`,...

Returns the string written to file.


### Predicates

#### empty?, emptyp `(s)`

True if `s` is nil or the empty string:

```cl
  (empty? nil) ;; => T
  (empty? "")  ;; => T
  (empty? " ") ;; => NIL
```

#### blank?, blankp `(s)`

True if `s` is empty or only contains whitespaces.

    (blankp "") ;; => T
    (blankp " ") ;; => T
    (emptyp " ") ;; => NIL

#### starts-with?, starts-with-p `(start s &key ignore-case)`

True if `s` starts with the substring `start`, nil otherwise. Ignore
case by default.

    (starts-with? "foo" "foobar") ;; => T
    (starts-with? "FOO" "foobar") ;; => NIL
    (starts-with? "FOO" "foobar" :ignore-case t) ;; => T

Calls `string=` or `string-equal` depending on the case, with their
`:start` and `:end` delimiters.

#### ends-with?, ends-with-p `(end s &key ignore-case)`

True if `s` ends with the substring `end`. Ignore case by default.

    (ends-with? "bar" "foobar") ;; => T

#### contains?, containsp `(substring s &key (ignore-case nil))`

Return true if `s` contains `substring`, nil otherwise. Ignore the
case with `:ignore-case t` (don't ignore by default).

Based on a simple call to the built-in `search` (which returns the
position of the substring).

#### prefix?, prefixp and suffix?, suffixp `(items s)` (new in 0.9)

Return `s` if it is a common prefix (or suffix) between items.

### Others

#### replace-all `(old new s)`

Replace `old` by `new` (no regexs) in `s`.

```cl
(replace-all "a" "o" "faa") ;; => "foo"
```

Uses
[cl-ppcre:regex-replace-all](http://weitz.de/cl-ppcre/#regex-replace-all)
but quotes the user input to not treat it as a regex.


#### prefix `(list-of-strings)` (renamed in 0.9)

(renamed from `common-prefix` in v0.9)

Find the common prefix between strings.

Example: `(str:prefix '(\"foobar\" \"foozz\"))` => \"foo\"

Uses the built-in `mismatch`, that returns the position at which
the strings fail to match.

Return a string or nil when the input is the void list.


#### suffix `(list-of-strings)` (new in 0.9)

Find the common suffix between strings.



## Macros

### string-case (new in v0.8, Quicklisp end of february 2018)

A case-like macro that works with strings (CL's case only works with symbols).

Example:


~~~lisp
(str:string-case input
  ("foo" (do something))
  (nil (print "input is nil")
  (otherwise (print "non of the previous forms was caught.")))
~~~

You might also like pattern matching. The example below with
[optima](https://github.com/m2ym/optima) is very similar:

~~~lisp
(optima:match "hey"
  ("hey" (print "it matched"))
  (otherwise :nothing))
~~~

Note that there is also http://quickdocs.org/string-case/.


## Changelog

* 0.9 (Quicklisp end of may, 2018)
  - added `s-first` , `s-rest` and `s-nth`
  - added `prefix` and `suffix` functions and predicates.
* 0.8 added `string-case`
* 0.7 added `version`
* 0.6 added `split-omit-nulls` (QL, january 2018)
* 0.5 added `common-prefix`
* 0.4 added `from-file` and `to-file`.
* 0.3 added `substring`.

## Dev and test

Test with [prove](https://github.com/fukamachi/prove).


## See also

* [cl-strings](https://github.com/diogoalexandrefranco/cl-strings), a
  similar (discovered afterwards), maybe more complete library, that
  does not use established libraries as dependencies as we do (with
  *potential* implementation
  [issues](https://github.com/diogoalexandrefranco/cl-strings/issues/2)).
* [cl-change-case](https://github.com/rudolfochrist/cl-change-case) to
  convert strings between camelCase, param-case, snake_case and more.
* the [Common Lisp Cookbook](https://lispcookbook.github.io/cl-cookbook/strings.html), strings page.

Inspired by the famous Emacs Lisp's [s.el](https://github.com/magnars/s.el).
