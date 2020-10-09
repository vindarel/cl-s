(in-package :cl-user)
(defpackage test-str
  (:use :cl
        :prove
        :str))

(in-package :test-str)

(setf prove:*enable-colors* t)
(plan nil)

(subtest "Index"
  (is (loop
         for i from -7 upto 7
         collect (index "abcde" i))
      '(0 0 0 1 2 3 4 0 1 2 3 4 5 5 5)
      "index wraps and saturates"))

(subtest "Slice"
  (is (slice -2 nil "abcdef" t) "ef"))

(subtest "Trim"
  (is "rst " (trim-left "   rst "))
  (is " rst" (trim-right " rst   "))
  (is "rst" (trim "  rst  "))
  (is nil (trim-left nil))
  (is nil (trim-right nil))
  (is nil (trim nil)))

(subtest "Collapse whitespaces"
  (is "foo bar baz" (collapse-whitespaces "foo  bar


  baz")
      "collapse whitespaces"))


(subtest "Concat"
  (is "foo" (concat "f" "o" "o"))
  (is "" (concat)))

(subtest "Replace"
  (is "foo" (replace-all "a" "o" "faa"))
  (is "foo" (replace-all "^a" "o" "fo^a"))
  (is "foo" (replace-all "^aa+" "o" "fo^aa+"))
  (is "foo'\\'bar" (replace-all "+" "'\\'" "foo+bar")
      "Edge case with a double backslash and a single quote.")
  (is "fooaa" (replace-first "aa" "oo" "faaaa")))

(subtest "Replace using"
  (is "foo" (replace-using (list "a" "o") "faa"))
  (is "fooAA" (replace-using (list "a" "o") "faaAA"))
  (is "faa" (replace-using (list "a") "faa"))
  (is "fooAA" (replace-using (list "a" "o" "A") "faaAA"))
  (is "faa" (replace-using nil "faa")))

(subtest "Join"
  (is "foo bar baz" (join " " '("foo" "bar" "baz")))
  (is "foo+++bar+++baz" (join "+++" '("foo" "bar" "baz")))
  (is "foo~bar" (join "~" '("foo" "bar")))
  (is "foo~~~bar" (join "~" '("foo~" "~bar")))
  (is "foo,bar" (join #\, '("foo" "bar"))))

(subtest "Insert"
  (is "hello" (insert "o" 4 "hell"))
  (is "hello" (insert "h" 0 "ello"))
  (is "helll" (insert "l" 200 "hell") "large index")
  (is "hell_" (insert "_" -1 "hell") "negative index last")
  (is "_hell" (insert "_" -5 "hell") "negative index first")
  (is "hell_" (insert "_" 4 "hell") "positive index last")
  (is "_hell" (insert "_" 0 "hell") "positive index first")
  (is "hell" (insert nil 2 "hell") "insert nil: do nothing")
  (is "hell" (insert "l" nil "hell") "index nil: do nothing")
  (is nil (insert "l" 2 nil) "s nil: nil")
  (is "hello" (insert #\o 4 "hell") "with a char"))

(subtest "Split"
  (is '("foo" "bar") (split " " "foo bar"))
  (is '("foo" "bar") (split "+" "foo+bar") "separator is a regexp")
  (is '("foo" "" "bar") (split "+" "foo++bar"))
  (is '("foo" "bar+car+dar") (split "+" "foo+bar+car+dar" :limit 2))
  (is '("foo" "bar") (split "+" "foo+bar"))
  (is '("foo" "bar") (split "x" "fooxbar") "split with string x")
  (is '("foo" "bar") (split #\x "fooxbar") "split with character")
  (is '("fooxbarx") (split "xx" "fooxbarx") "split with xx, end in x")
  (is '("foo" "barx") (split "xx" "fooxxbarx") "split with xx")
  (is '("fooxbar" "x") (split "xx" "fooxbarxxx") "split with xx, end in xxx")
  (is '("foo" "bar") (split "(*)" "foo(*)bar"))
  (is '("foo" "bar" "") (split "NO" "fooNObarNO") "separator at the end (cl-ppcre doesn't return an empty string), but we do.")
  (is '("foo" "bar" "") (split "NO" "fooNObarNO" :limit 10) "but cl-ppcre does return trailing empty strings if limit is provided")
  (is '("foo" "bar") (split "+" "foo+++bar++++" :omit-nulls t) "omit-nulls argument")
  (is '("foo" "   ") (split "+" "foo+++   ++++" :omit-nulls t) "omit-nulls and blanks")
  (is '("foo" "bar") (let ((*omit-nulls* t)) (split "+" "foo+++bar++++")) "omit-nulls argument")
  (is '("foo" "   ") (let ((*omit-nulls* t)) (split "+" "foo+++   ++++")) "omit-nulls and blanks")
  (is '("foo" "bar") (split #\, "foo,bar")))

(subtest "substring"
  (is "abcd" (substring 0 4 "abcd") "normal case")
  (is "ab" (substring 0 2 "abcd") "normal case substing")
  (is "bc" (substring 1 3 "abcd") "normal case substing middle")
  (is "" (substring 4 4 "abcd") "normal case")
  (is "" (substring 0 0 "abcd") "normal case")
  (is "d" (substring 3 4 "abcd") "normal case")
  (is "abcd" (substring 0 t "abcd") "end is t")
  (is "abcd" (substring 0 nil "abcd") "end is nil")
  (is "abcd" (substring 0 100 "abcd") "end is too large")
  (is "abc" (substring 0 -1 "abcd") "end is negative")
  (is "b" (substring 1 -2 "abcd") "end is negative")
  (is "" (substring 2 1 "abcd") "start is bigger than end")
  (is "" (substring 0 -100 "abcd") "end is too low")
  (is "" (substring 100 1 "abcd") "start is too big")
  (is "abcd" (substring -100 4 "abcd") "start is too low")
  (is "abcd" (substring -100 100 "abcd") "start and end are too low and big")
  (is "" (substring 100 -100 "abcd") "start and end are too big and low"))

(subtest "Repeat"
  (is "" (repeat 10 ""))
  (is "foofoofoo" (repeat 3 "foo")))

(subtest "Empty-p"
  (ok (empty? nil))
  (ok (emptyp ""))
  (is nil (empty? " ")))

(subtest "non-empty string"
  (is nil (non-empty-string-p 8))
  (is nil (non-empty-string-p nil))
  (is nil (non-empty-string-p #\x))
  (is nil (non-empty-string-p ""))
  (ok (non-empty-string-p "  "))
  (ok (non-empty-string-p "foo"))
  (ok (non-empty-string-p "8")))

(subtest "non-blank string"
  (is nil (non-blank-string-p 8))
  (is nil (non-blank-string-p ""))
  (is nil (non-blank-string-p "  "))
  (is nil (non-blank-string-p "

  "))
  (ok (non-blank-string-p "foo"))
  (ok (non-blank-string-p "8")))

(subtest "Blank string"
  (ok (blankp "  "))
  (ok (blank? "  "))
  (is nil (blank? "   rst ")))

(subtest "Shorten"
  (is "hello..." (shorten 8 "hello foobar")
      "default case.")
  (is "foo" (shorten 10 "foo")
      "long, no change")
  (is "..." (shorten 1 "foo")
      "short, only ellipsis")
  (is "-" (shorten 1 "foo" :ellipsis "-")
      "custom ellipsis")
  (is "-"
      (let ((str:*ellipsis* "-"))
        (shorten 1 "foo"))
      "custom ellipsis with let")
  (is "hello-" (shorten 6 "hello foobar" :ellipsis "-")
      "shorter ellipsis")
  (is "foo" (shorten nil "foo")
      "length is nil")
  (is "..." (shorten -1 "foo")
      "length is negative")
  (is nil (shorten 10 nil)
      "s is nil"))

(subtest "Words"
  (is nil (words nil))
  (is nil (words ""))
  (is '("foo") (words "foo"))
  (is '("foo" "bar") (words "foo bar"))
  (is '("foo" "bar") (words "  foo   bar   "))
  (is '("foo" "bar  ") (words " foo bar  " :limit 2))
  (is '("foo" "bar baz ") (words " foo bar baz " :limit 2))
  (is '("foo" "bar" "baz" "?") (words "  foo bar  baz ?"))
  (is '("foo" "bar" "baz" "?") (words "  foo
 bar  baz ?")))

(subtest "Unwords"
  (is "" (unwords nil))
  (is "" (unwords '()))
  (is "" (unwords '("")))
  (is "foo" (unwords '("foo")))
  (is "foo bar baz" (unwords '("foo bar baz"))))


(subtest "Lines"
  (is nil (lines nil))
  (is nil (lines ""))
  (is '("") (lines "
"))
  (is '("1" "2" " 3") (lines "1
2
 3"))
  (is '("1" "2" " 3") (lines "1
2
 3
"))
  (is '("1" "2" "" "3") (str:lines "1
2

3"))
  (is '("1" "2" "3") (str:lines "1
2


3" :omit-nulls t)))

(subtest "Unlines"
  (is "" (unlines nil))
  (is "" (unlines '("")))
  (is "
" (unlines '("" "")))
  (is "1
2
" (unlines '("1" "2" ""))))

(subtest "starts-with?"
  (ok (starts-with? "foo" "foobar") "default case")
  (ok (starts-with? "" "foo") "with blank start")
  (ok (not (starts-with? "rs" "")) "with blank s")
  (ok (not (starts-with? "foobar" "foo")) "with shorter s")
  (ok (starts-with? "" "") "with everything blank")
  (ok (not (starts-with? "FOO" "foobar")) "don't ignore case")
  (ok (starts-with-p "f" "foo") "starts-with-p alias")
  (ok (starts-with? "FOO" "foobar" :ignore-case t) "ignore case")
  (ok (let ((*ignore-case* t)) (starts-with? "FOO" "foobar")) "ignore case"))

(subtest "ends-with?"
  (ok (ends-with? "bar" "foobar") "default case")
  (ok (ends-with-p "bar" "foobar") "ends-with-p alias")
  (ok (not (ends-with? "BAR" "foobar")) "don't ignore case")
  (ok (ends-with? "BAR" "foobar" :ignore-case t) "ignore case")
  (ok (let ((*ignore-case* t)) (ends-with? "BAR" "foobar")) "ignore case"))

(subtest "prefix"
  (is (prefix '("foobar" "footeam")) "foo" "default case")
  (is (prefix '("foobar" "barfoo")) "" "no common prefix")
  (is (prefix '("foobar" "")) "" "with empty string")
  (is (prefix '("foobar" nil)) "" "with a nil")
  (is (prefix '()) nil "with void list"))

(subtest "prefix?"
  (is (prefix? '("foobar" "footeam") "foo") "foo" "default case")
  (is (prefix?'("foobar" "barfoo") "") "" "no common prefix")
  (is (prefix? '("foobar" "") "") "" "with empty string")
  (is (prefix? '("foobar" nil) "") "" "with a nil")
  (is (prefix? '() nil) nil "with void list"))

(subtest "suffix"
  (is (suffix '("foobar" "teambar")) "bar" "default case")
  (is (suffix '("foobar" "barfoo")) "" "no common suffix")
  (is (suffix '("foobar" "")) "" "with empty string")
  (is (suffix '("foobar" nil)) "" "with a nil")
  (is (suffix '()) nil "with void list"))

(subtest "suffix?"
  (is (suffix? '("foobar" "teambar") "bar") "bar" "default case")
  (is (suffix?'("foobar" "barfoo") "") "" "no common suffix")
  (is (suffix? '("foobar" "") "") "" "with empty string")
  (is (suffix? '("foobar" nil) "") "" "with a nil")
  (is (suffix? '() nil) nil "with void list"))

(subtest "add-prefix"
  (is (add-prefix '("bar" "team") "foo") '("foobar" "footeam") "default case")
  (is (add-prefix '("bar" nil) "foo") '("foobar" "foo") "with a nil")
  (is (add-prefix '() "foo") '() "with void list"))

(subtest "add-suffix"
  (is (add-suffix '("foo" "team") "bar") '("foobar" "teambar") "default case")
  (is (add-suffix '("foo" nil) "bar") '("foobar" "bar") "with a nil")
  (is (add-suffix '() "foo") '() "with void list"))

(subtest "pad left, right, center"
  (is (pad 10 "foo") "foo       "
      "pad adds spaces on the right by default.")
  (is (pad-right 10 "foo") (pad 10 "foo")
      "pad-right is equivalent to pad")
  (is (pad 10 "foo" :pad-side :left) "       foo"
      "pad-left")
  (is (pad 10 "foo" :pad-side :center) "   foo    "
      "pad with pad-side :center")
  (is (pad-center 10 "foo") (pad 10 "foo" :pad-side :center)
      "pad-center")
  (is (pad 10 "foo" :pad-char #\+) "foo+++++++"
      "pad with a custom padding character.")
  (is (pad -1 "foo") "foo"
      "pad with a short length returns the string."))

(subtest "contains?"
  (ok (contains? "foo" "blafoobar") "default")
  (ok (not (contains? "foo" "")) "with no string")
  (ok (not (contains? "" nil)) "a blank substring in a nil str")
  (ok (not (contains? "foo" nil)) "with string nil")
  (ok (not (contains? "Foo" "blafoobar")) "with case")
  (ok (contains? "Foo" "blafoobar" :ignore-case t) "ignore case")
  (ok (containsp "Foo" "blafoobar" :ignore-case t) "containsp alias")
  (ok (let ((*ignore-case* t)) (contains? "Foo" "blafoobar")) "ignore case"))

(subtest "string-case"
  (ok (string-case "hello"
        ("hello" (format nil "yes"))
        (otherwise nil))
      "string-case base case")
  (ok (not (string-case "no"
             ("hello" t)
             (otherwise nil)))
      "otherwise form")
  (is :otherwise (string-case :no-str
                   ("hello" t)
                   (otherwise :otherwise))
      "matching with a symbol: otherwise"))

(subtest "s-first"
  (is (s-first nil) nil)
  (is (s-first "foobar") "f")
  (is (s-first "") ""))

(subtest "s-last"
  (is (s-last nil) nil)
  (is (s-last "b") "b")
  (is (s-last "bar") "r")
  (is (s-last "") ""))

(subtest "s-rest"
  (is (s-rest nil) nil)
  (is (s-rest "foobar") "oobar")
  (is (s-rest "") ""))

(subtest "s-nth"
  (is (s-nth 1 nil) nil)
  (is (s-nth 3 "foobar") "b")
  (is (s-nth -1 "foobar") "")
  (is (s-nth 6 "foobar") "")
  (is (s-nth 3 "") ""))

(subtest "s-assoc-value"
  (let ((alist '(("test" . 1) ("another test" . 2))))
    (is (s-assoc-value alist "test") (values 1 (first alist)))
    (is (s-assoc-value alist "another test") (values 2 (second alist)))
    (is (s-assoc-value alist "a third test") (values nil nil))))

(subtest "count-substring"
  (is (count-substring nil nil) nil)
  (is (count-substring "" "abc") nil)
  (is (count-substring "aba" "ababab") 1)
  (is (count-substring "aba" "abababa") 2)
  (is (count-substring "ab" "abxabxab") 3)
  (is (count-substring "cd" "abxabxab") 0)
  (is (count-substring "abcd" "abcd") 1)
  (is (count-substring "abcde" "abcd") 0)
  (is (count-substring "ab" "abxabxab" :start 3 :end 7) 1))

(subtest "case"
  (is (downcase nil) nil
      "downcase nil returns nil, not a string.")
  (is (downcase "Foo") "foo")
  (is (downcase :foo) "foo"
      "Built-in functions also work on symbols.")
  (is (upcase nil) nil
      "upcase nil returns nil, not a string.")
  (is (upcase "foo") "FOO")
  (is (capitalize nil) nil
      "capitalize nil returns nil, not a string.")
  (is (capitalize "foo") "Foo"))

(subtest "case predicates"
  (is (downcasep nil) nil "downcasep nil")
  (is (downcasep "") nil "downcasep empty string")
  (is (downcasep " ") nil "downcasep blank string")
  (is (downcasep " e ") t "downcasep ok with spaces")
  (is (downcasep "rst") t "downcasep default")
  (is (downcasep " A ") nil "downcasep false default")
  (is (downcasep " aiue tsuie+- Aa ") nil "downcasep false default")
  (is (downcasep " +,. ") nil "downcasep only punctuation")
  (is (downcasep "123") nil "downcasep only digits")
  (is (downcasep " a+,. ") t "downcasep with punctuation (python api)")
  (is (downcasep " +,é. ") t "downcasep with accent")

  (is (upcasep nil) nil "upcasep nil")
  (is (upcasep "") nil "upcasep empty")
  (is (upcasep "   ") nil "upcasep blank")
  (is (upcasep "rst") nil "upcasep lowercase letters")
  (is (upcasep "??+,") nil "upcasep only punctuation")
  (is (upcasep "123") nil "upcasep only digits")
  (is (upcasep " ++YES-- ") t "upcasep default")
  (is (upcasep " ++YÉÈS-- ") t "upcasep with accent")
  (is (upcasep " ++NO ñ-- ") nil "upcasep with lower non-alpha ñ")
  (is (upcasep " ++YES Ñ-- ") t "upcasep with non-alpha Ñ")
  (is (upcasep " ++Ñ-- ") t "upcasep with only non-alpha")

  (ok (alphanump "rst124ldv") "alphanump default")
  (is (alphanump " rst123ldv ") nil "alphanump no space")
  (is (alphanump "rst,123+ldv") nil "alphanump no punctuation")
  (is (alphanump ",+") nil "alphanump no punctuation")
  (is (alphanump "abcéß") nil "alphanump no accents")

  (ok (alphap "abcDEf") "alphap default")
  (is (alphap "abc,de") nil "alphap no punctuation")
  (is (alphap "abcdeé") nil "alphap no accents")
  (is (alphap "abc de") nil "alphap no space")
  (is (alphap " ") nil "alphap blank")

  (is (digitp "abc") nil "digitp letters")
  (is (digitp "123") t "digitp default")
  (is (digitp "123,456") nil "digitp no punctuation")
  (is (digitp "123 456") nil "digitp no space")

  (is (has-alpha-p "-+,A-") t "has-alpha-p default")
  (is (has-alpha-p "-é-") nil "has-alpha-p no accents")
  (is (has-alphanum-p "-+, 1 ") t "has-alphanum-p with digit"))

(subtest "letters"
  (is (lettersp "éß") t "letters with accents and ß")
  (is (lettersp " e é,") nil "no letters")
  (is (has-letters-p " e é ß") t "has-letters-p default")
  (is (has-letters-p " +,-") nil "has-letters-p default nil")
  (is (lettersnump "abcéß123") t "lettersnump default"))

;; prove end
(finalize)
