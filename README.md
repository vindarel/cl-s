[![Quicklisp](http://quickdocs.org/badge/cl-str.svg)](http://quickdocs.org/cl-str)
# A modern and consistent Common Lisp string manipulation library

    (ql:quickload "str")

also on [Ultralisp](http://ultralisp.org/).

Why ?

* modernity, simplicity and discoverability:

  - `(str:trim s)` instead of `  (string-trim '(#\Space #\Newline #\Backspace #\Tab #\Linefeed #\Page #\Return #\Rubout) s))`,
or `str:concat strings` instead of an unusual `format` construct; one discoverable library instead of many;

* consistence and composability, where `s` is always the last argument, which makes it
  easier to feed pipes and arrows.

* fixing built-in surprises: `(string-downcase nil`)  => `"nil"` the string, whereas `(str:downcase nil)` => `nil`.


The only dependency is `cl-ppcre`.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [A modern and consistent Common Lisp string manipulation library](#a-modern-and-consistent-common-lisp-string-manipulation-library)
    - [Install](#install)
    - [Global parameters](#global-parameters)
    - [Functions](#functions)
        - [Tweak whitespace](#tweak-whitespace)
            - [trim `(s)`](#trim-s)
            - [collapse-whitespaces `(s)`](#collapse-whitespaces-s)
        - [To longer strings](#to-longer-strings)
            - [join `(separator list-of-strings)`](#join-separator-list-of-strings)
            - [concat `(&rest strings)`](#concat-rest-strings)
            - [insert `(string/char index s)`](#insert-stringchar-index-s)
            - [repeat `(count s)`](#repeat-count-s)
            - [add-prefix, add-suffix `(items s)`](#add-prefix-add-suffix-items-s)
            - [pad `(len s &key (pad-side :right) (pad-char #\Space))`, pad-left, pad-right, pad-center (new in 0.16, 2019/12)](#pad-len-s-key-pad-side-right-pad-char-space-pad-left-pad-right-pad-center-new-in-016-201912)
        - [To shorter strings](#to-shorter-strings)
            - [substring `(start end s)`](#substring-start-end-s)
            - [s-first `(s)`](#s-first-s)
            - [s-last `(s)`](#s-last-s)
            - [s-rest `(s)`](#s-rest-s)
            - [s-nth `(n s)`](#s-nth-n-s)
            - [shorten `(len s &key ellipsis)`](#shorten-len-s-key-ellipsis)
        - [To and from lists](#to-and-from-lists)
            - [words `(s)`](#words-s)
            - [unwords `(strings)`](#unwords-strings)
            - [lines `(s &key omit-nulls)`](#lines-s-key-omit-nulls)
            - [unlines `(strings)`](#unlines-strings)
            - [split `(separator s &key omit-nulls limit start end)`](#split-separator-s-key-omit-nulls-limit-start-end)
            - [split-omit-nulls](#split-omit-nulls)
        - [To and from files](#to-and-from-files)
            - [from-file `(filename)`](#from-file-filename)
            - [to-file `(filename s)`](#to-file-filename-s)
        - [Predicates](#predicates)
            - [empty?, emptyp `(s)`](#empty-emptyp-s)
            - [blank?, blankp `(s)`](#blank-blankp-s)
            - [starts-with?, starts-with-p `(start s &key ignore-case)`](#starts-with-starts-with-p-start-s-key-ignore-case)
            - [ends-with?, ends-with-p `(end s &key ignore-case)`](#ends-with-ends-with-p-end-s-key-ignore-case)
            - [contains?, containsp `(substring s &key (ignore-case nil))`](#contains-containsp-substring-s-key-ignore-case-nil)
            - [prefix?, prefixp and suffix?, suffixp `(items s)`](#prefix-prefixp-and-suffix-suffixp-items-s)
        - [Case](#case)
            - [Functions to change case: camel-case, snake-case,... (new in 0.15, 2019/11)](#functions-to-change-case-camel-case-snake-case-new-in-015-201911)
            - [downcase, upcase, capitalize `(s)` fixing a built-in suprise. (new in 0.11)](#downcase-upcase-capitalize-s-fixing-a-built-in-suprise-new-in-011)
            - [downcasep, upcasep `(s)`](#downcasep-upcasep-s)
            - [alphap, lettersp `(s)`](#alphap-lettersp-s)
            - [alphanump, lettersnump `(s)`](#alphanump-lettersnump-s)
            - [digitp `(s)`](#digitp-s)
            - [has-alpha-p, has-letters-p, has-alphanum-p `(s)`](#has-alpha-p-has-letters-p-has-alphanum-p-s)
        - [Others](#others)
            - [replace-first `(old new s)`](#replace-first-old-new-s)
            - [replace-all `(old new s)`](#replace-all-old-new-s)
            - [remove-punctuation (s &key replacement)](#remove-punctuation-s-key-replacement)
            - [prefix `(list-of-strings)` (renamed in 0.9)](#prefix-list-of-strings-renamed-in-09)
            - [suffix `(list-of-strings)`](#suffix-list-of-strings)
            - [count-substring `(substring s &key start end)`](#count-substring-substring-s-key-start-end)
            - [s-assoc-value `(alist key)`](#s-assoc-value-alist-key)
    - [Macros](#macros)
        - [string-case](#string-case)
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

Don't have a full Common Lisp development environment yet ? Get
[Portacle](https://shinmera.github.io/portacle/), a portable and
multiplatform development environment shipping Emacs, Quicklisp, SBCL
and Git. See also [editor
support](https://lispcookbook.github.io/cl-cookbook/editor-support.html)
(Vim, Lem, Atom, Eclipse,…).

## Global parameters

Some parameters are common to various functions and often used:
`:ignore-case` and `:omit-nulls`.

Consequently we can also manage them with global parameters:

~~~lisp
(let ((str:*ignore-case* t))
  (str:ends-with? "BAR" "foobar"))
~~~

is equivalent to

~~~lisp
(str:ends-with? "BAR" "foobar" :ignore-case t)
~~~

## Functions

### Tweak whitespace

#### trim `(s)`
Remove whitespaces at the beginning and end of `s`.

```lisp
(trim "  rst  ") ;; => "rst"
```

Also `trim-left` and `trim-right`.

Uses the built-in
[string-trim](https://lispcookbook.github.io/cl-cookbook/strings.html#trimming-blanks-from-the-ends-of-a-string)
where whitespaces are `'(#\Space #\Newline #\Backspace #\Tab #\Linefeed #\Page #\Return #\Rubout)`.

#### collapse-whitespaces `(s)`

Ensure there is only one space character between words. Remove newlines.

~~~lisp
(collapse-whitespaces "foo  bar


  baz")
;; "foo bar baz"
;;T
~~~


### To longer strings

#### join `(separator list-of-strings)`

Join strings in list `list-of-strings` with `separator` (either a string or a char) in between.

```lisp
(join " " '("foo" "bar" "baz")) ;; => "foo bar baz"
(join #\Space '("foo" "bar" "baz")) ;; => "foo bar baz"
```

It uses the `{` iteration [format](http://jtra.cz/stuff/lisp/sclr/format.html) directive. See also this [quick reference](http://clqr.boundp.org/download.html):

    (format nil "~{~a+~}" '(:a :b :c))  ;; the + is the separator
    ;; => "A+B+C+"

We use the caret directive ("escape upward") to not print the
separator in the end:

    (format nil "~{~a~^+~}" '(:a :b :c))
    ;; => "A+B+C"


#### concat `(&rest strings)`

Join strings into one.

```lisp
(concat "f" "o" "o") ;; => "foo"
```

Simple call of the built-in [concatenate](https://lispcookbook.github.io/cl-cookbook/strings.html#concatenating-strings).

We actually also have `uiop:strcat`.


#### insert `(string/char index s)`

Insert the given string (or character) at the index `index` into `s` and return a
new string.

If `index` is out of bounds, just return `s`.

```lisp
(str:insert "l" 2 "helo") ; => "hello"

(str:insert "o" 99 "hell") : => "hell"
```

#### repeat `(count s)`

Make a string of `s` repeated `count` times.

```lisp
(repeat 3 "foo") ;; => "foofoofoo"
```

#### add-prefix, add-suffix `(items s)`

Respectively prepend or append `s` to the front of each item.


#### pad `(len s &key (pad-side :right) (pad-char #\Space))`, pad-left, pad-right, pad-center (new in 0.16, 2019/12)

Fill `s` with characters until it is of the given length. By default,
add spaces on the right:

~~~lisp
(str:pad 10 "foo")
"foo       "
~~~

* `pad-side`: one of `:right` (the default), `:left` or `:center`. See `*pad-side*`.
* `pad-char`: the padding character (or string of one character). Defaults to a space. See `*pad-char*`.

~~~lisp
(str:pad 10 "foo" :pad-side :center :pad-char "+")
"+++foo++++"
~~~

If the given length is smaller than the length o `s`, return `s`.

Filling with spaces can easily be done with format:

~~~lisp
(format nil "~va" len s) ;; => "foo       "
(format nil "~v@a" 10 "foo") ;; => "       foo" (with @)
~~~


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

#### slice `(start end s &optional sharedp)`

Same as substring, except the result might share storage with s.
More precisely, if sharedp is true or if *SHAREDP* is true, the slice might be s itself
or an array displaced to s.

Examples:

```lisp
  (is "abcd" (slice 1 -1 ">abcd<"))
```

#### s-first `(s)`

Return the first letter of `s`.

Examples:

```lisp
  (s-first "foobar") ;; => "f"
  (s-first "") ;; => ""
```

#### s-last `(s)`

Return the last letter of `s`.


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

You could also use

~~~lisp
(elt "test" 1)
;; => #\e
(string (elt "test" 1))
;; => "e"
~~~

#### shorten `(len s &key ellipsis)`

If `s` is longer than `len`, truncate it and add an ellipsis at the
end (`...` by default). `s` is cut down to `len` minus the length of
the ellipsis (3 by default).

Optionally, give an `:ellipsis` keyword argument. Also set it globally
with `*ellipsis*`.

~~~lisp
(shorten 8 "hello world")
;; => "hello..."
(shorten 3 "hello world")
;; => "..."
(shorten 8 "hello world" :ellipsis "-")
;; => "hello w-"
(let ((*ellipsis* "-"))
  (shorten 8 "hello world"))
;; => "hello w-"
~~~


### To and from lists

#### words `(s)`

Return list of words, which were delimited by whitespace.

#### unwords `(strings)`

Join the list of strings with a whitespace.

#### lines `(s &key omit-nulls)`

Split string by newline character and return list of lines.

A terminal newline character does *not* result in an extra empty string
(new in **v0.14**, october 2019).


#### unlines `(strings)`

Join the list of strings with a newline character.

#### split `(separator s &key omit-nulls limit start end)`

Split into subtrings (unlike cl-ppcre, without a regexp). If
`omit-nulls` is non-nil, zero-length substrings are omitted.

```lisp
(split "+" "foo++bar") ;; => ("foo" "" "bar")
(split #\+ "foo++bar") ;; => ("foo" "" "bar")
(split "+" "foo++bar" :omit-nulls t) ;; => ("foo" "bar")
```

cl-ppcre has an inconsistency such that when the separator appears at
the end, it doesn't return a trailing empty string. But we do **since
v0.14** (october, 2019).

~~~lisp
(cl-ppcre:split " " "a b c ")
("a" "b" "c")

(str:split " " "a b c ")
("a" "b" "c" "")
~~~


#### split-omit-nulls

Because it is a common pattern and it can be clearer than an option
coming after many parenthesis.


### To and from files

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

```lisp
  (empty? nil) ;; => T
  (empty? "")  ;; => T
  (empty? " ") ;; => NIL
```

See also `str:non-empty-string-p`, which adds a `stringp` check.

#### blank?, blankp `(s)`

True if `s` is empty or only contains whitespaces.

    (blankp "") ;; => T
    (blankp " ") ;; => T
    (emptyp " ") ;; => NIL

See also `str:non-blank-string-p`.

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

#### prefix?, prefixp and suffix?, suffixp `(items s)`

Return `s` if it is a common prefix (or suffix) between items.

See also `uiop:string-prefix-p prefix s`, which returns `t` if
`prefix` is a prefix of `s`,

and `uiop:string-enclosed-p prefix s suffix`, which returns `t` if `s`
begins with `prefix` and ends with `suffix`.

### Case

#### Functions to change case: camel-case, snake-case,... (new in 0.15, 2019/11)

We use
[cl-change-case](https://github.com/rudolfochrist/cl-change-case/) (go
thank him and star the repo!).

The available functions are:

```
:no-case (s &key replacement)
:camel-case (s &key merge-numbers)
:dot-case
:header-case
:param-case
:pascal-case
:path-case
:sentence-case
:snake-case
:swap-case
:title-case
:constant-case
```

More documentation and examples are there.


#### downcase, upcase, capitalize `(s)` fixing a built-in suprise. (new in 0.11)

The functions `str:downcase`, `str:upcase` and `str:capitalize` return
a new string. They call the built-in `string-downcase`,
`string-upcase` and `string-capitalize` respectively, but they fix
something surprising. When the argument is `nil`, the built-ins return
"nil" or "NIL" or "Nil", a *string*. Indeed, they work on anything:

    (string-downcase nil) ;; => "nil" the string !
    (str:downcase nil) ;; nil

    (string-downcase :FOO) ;; => "foo"

#### downcasep, upcasep `(s)`

These functions return `t` if the given string contains at least one
letter and all its letters are lowercase or uppercase, respectively.

```lisp
(is (downcasep " a+,. ") t "downcasep with one letter and punctuation is true.")
(is (downcasep " +,. ") nil "downcasep with only punctuation or spaces is false")
```

#### alphap, lettersp `(s)`

`alphap` returns t if `s` contains at least one character and all characters are
  alpha (as in `"^[a-zA-Z]+$"`).

`lettersp` works for unicode letters too.

~~~lisp
(is (alphap "abcdeé") nil "alphap is nil with accents")
(is (lettersp "éß") t "lettersp is t with accents and ß")
~~~

#### alphanump, lettersnump `(s)`

`alphanump` returns t if `s` contains at least one character and all characters are alphanumeric (as in `^[a-zA-Z0-9]+$`).

`lettersnump` also works on unicode letters (as in `^[\\p{L}a-zA-Z0-9]+$`).

#### digitp `(s)`

Returns t if `s` contains at least one character and all characters are numerical (as for `digit-char-p`).

#### has-alpha-p, has-letters-p, has-alphanum-p `(s)`

Return t if `s` has at least one alpha, letter, alphanum character (as with `alphanumericp`).

### Others

#### replace-first `(old new s)`

Replace the first occurence of `old` by `new` in `s`. Arguments are not regexs.


```lisp
(replace-first "a" "o" "faa") ;; => "foa"
```

Uses
[cl-ppcre:regex-replace](http://weitz.de/cl-ppcre/#regex-replace)
but quotes the user input to not treat it as a regex.

#### replace-all `(old new s)`

Replace all occurences of `old` by `new` in `s`. Arguments are not regexs.

```lisp
(replace-all "a" "o" "faa") ;; => "foo"
```

Uses
[cl-ppcre:regex-replace-all](http://weitz.de/cl-ppcre/#regex-replace-all)
but quotes the user input to not treat it as a regex.

#### replace-using `(plist s)`

Replace all associations given by pairs in a plist and return a new string.

The plist is a list alternating a string to replace (case sensitive) and its replacement.

Example:

```lisp
(replace-using (list "%phone%" "987")
               "call %phone%")
;; "call 987"
```

#### remove-punctuation (s &key replacement)

Remove the punctuation characters from `s`, replace them with
`replacement` (defaults to a space) and strip continuous whitespace.

~~~lisp
(str:remove-punctuation "I say: - 'Hello, world?'") ;; => "I say Hello world"
~~~

Use `str:no-case` to remove punctuation and return the string as lower-case.


#### prefix `(list-of-strings)` (renamed in 0.9)

(renamed from `common-prefix` in v0.9)

Find the common prefix between strings.

Example: `(str:prefix '(\"foobar\" \"foozz\"))` => \"foo\"

Uses the built-in `mismatch`, that returns the position at which
the strings fail to match.

Return a string or nil when the input is the void list.


#### suffix `(list-of-strings)`

Find the common suffix between strings.

#### count-substring `(substring s &key start end)`
Counts the non-overlapping occurrences of `substring` in `s`.
You could also count only the ocurrencies between `start` and `end`.

Examples:
~~~ lisp
(count-substring "abc" "abcxabcxabc")
;; => 3
~~~
~~~lisp
(count-substring "abc" "abcxabcxabc" :start 3 :end 7)
;; => 1
~~~

#### s-assoc-value `(alist key)`

Returns the value of a cons cell in `alist` with key `key`, when `key` is a string.
The second return value is the cons cell, if any was matched.

The arguments are in the opposite order of `cl:assoc`'s, but are consistent
with `alexandria:assoc-value` (and `str`).

```lisp
(s-assoc-value '(("hello" . 1) ("world" . 2)) "world")
;; => 1
;;    ("world" . 2)

(alexandria:assoc-value '(("hello" . 1)) "hello")
;; NIL
(alexandria:assoc-value '(("hello" . 1)) "hello" :test #'string=)
;; 1
;; ("hello" . 1)

(assoc "hello" '(("hello" . 1)))
;; NIL
(assoc "hello" '(("hello" . 1)) :test #'string=)
;; ("hello" . 1)
(cdr *)
;; 1
```

## Macros

### string-case

A case-like macro that works with strings (CL case's test function is
`eql`, and that isn't enough for strings).

Example:


~~~lisp
(str:string-case input
  ("foo" (do something))
  (nil (print "input is nil")
  (otherwise (print "non of the previous forms was caught.")))
~~~

You might also like pattern matching. The example below with
[trivia](https://github.com/guicho271828/trivia/) is very similar:

~~~lisp
(trivia:match "hey"
  ("hey" (print "it matched"))
  (otherwise :nothing))
~~~

Note that there is also http://quickdocs.org/string-case/.


## Changelog

*0.18.1, September, 2020: fix replace-all edge case when the replacement string ends with two backslashes and a single quote.
* 0.18, June, 2020: added `replace-using`.
* 0.17, April 2020:
  - added `collapse-whitespaces`
  - `join` and `split` also accept a char as separator
  - fixed `remove-punctuation` that did not respect the case. Use `no-case` for this
  - fixed `from-file` "odd number of arguments" error.
* 0.16, November 2019: added `pad`, `pad-[left, right, center]`.
* 0.15, October 2019: added functions to change case (based on cl-change-case).
  added remove-punctuation.
* 0.14, October, 2019: fixed the cl-ppcre inconsistency in `split` and `lines`. A trailing separator now returns a trailing empty string.

Before:

~~~lisp
(str:split " " "a b c ")
("a" "b" "c")  ;; like cl-ppcre:split
~~~

Now:

~~~lisp
(str:split " " "a b c ")
("a" "b" "c" "")
~~~

* august, 2019: deprecated `prune`, renamed to `shorten`.
* added `:limit` to `split`.
* 0.13 june, 2019
  - added `insert`
* 0.12
  - added case predicates (`downcasep`, `alphap`, `has-x` and friends).
* 0.11 (Quicklisp end of march, 2019, also in Ultralisp)
  - added `str:downcase`, `str:upcase` and `str:capitalize`, that fix the `nil` argument surprise.
* 0.10
  - `split` doesn't fix cl-ppcre's inconsistency anymore (when the separator appears at the end). See issue #18. So `(str:split "xx" "fooxxbarxx")` doesn't return a trailing `""`.
  - added `s-last`
  - `s-first` and friends return `nil` when appropriate, not `""`.
* 0.9
  - added `s-first` , `s-rest` and `s-nth`
  - added `prefix` and `suffix` functions and predicates.
  - added `prune`.
* 0.8 added `string-case`
* 0.7 added `version`
* 0.6 added `split-omit-nulls` (QL, january 2018)
* 0.5 added `common-prefix`
* 0.4 added `from-file` and `to-file`.
* 0.3 added `substring`.

## Dev and test

Test with [prove](https://github.com/fukamachi/prove).

  (ql:quickload :str.test)
  (load "test/test-str.lisp")


## See also

* the [Common Lisp Cookbook](https://lispcookbook.github.io/cl-cookbook/strings.html), strings page.

Inspired by the famous Emacs Lisp's [s.el](https://github.com/magnars/s.el).
