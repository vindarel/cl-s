(in-package :cl-user)

(defpackage str
  (:use :cl)
  (:import-from :cl-change-case
                :no-case
                :camel-case
                :dot-case
                :header-case
                :param-case
                :pascal-case
                :path-case
                :sentence-case
                :snake-case
                :swap-case
                :title-case
                :constant-case)
  (:export
   ;; cl-change-case functions:
   ;; (we could use cl-reexport but we don't want Alexandria in the dependencies list)
   :no-case
   :camel-case
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

   ;; ours:
   :remove-punctuation
   :contains?
   :containsp
   :trim-left
   :trim-right
   :trim
   :collapse-whitespaces
   :join
   :insert
   :split
   :split-omit-nulls
   :slice
   :substring
   :shorten
   :prune ;; "deprecated" in favor of shorten
   :repeat
   :replace-first
   :replace-all
   :replace-using
   :concat
   :empty?
   :emptyp
   :non-empty-string-p
   :non-blank-string-p
   :blank?
   :blankp
   :blank-str-p
   :blank-str?
   :words
   :unwords
   :lines
   :starts-with?
   :starts-with-p
   :ends-with?
   :ends-with-p
   :common-prefix
   :prefix
   :suffix
   :prefix?
   :prefixp
   :suffix?
   :suffixp
   :add-prefix
   :add-suffix
   :pad
   :pad-left
   :pad-right
   :pad-center
   :unlines
   :from-file
   :to-file
   :string-case
   :s-first
   :s-last
   :s-rest
   :s-nth
   :s-assoc-value
   :count-substring

   :downcase
   :upcase
   :capitalize
   :downcasep
   :downcase?
   :upcasep
   :upcase?
   :has-alphanum-p
   :has-alpha-p
   :has-letters-p
   :alphanump
   :alphanum?
   :alphap
   :lettersp
   :letters?
   :lettersnump
   :alpha?
   :digitp
   :digit?
   :whitespacep
   :whitespace?

   :*ignore-case*
   :*omit-nulls*
   :*ellipsis*
   :*pad-char*
   :*pad-side*
   :*sharedp*
   :*negative-wrap*
   :version
   :+version+
   :?

   :base-displacement
   :negative-index
   :index
   :with-indices

   ))

(in-package :str)


(defparameter *ignore-case* nil)
(defparameter *omit-nulls* nil)
(defparameter *pad-char* #\Space
  "Padding character to use with `pad'. It can be a string of one character.")
(defparameter *pad-side* :right
  "The side of the string to add padding characters to. Can be one of :right, :left and :center.")
(defparameter *sharedp* nil
  "When NIL, functions always return fresh strings; otherwise, they may share storage with their inputs.")
(defparameter *negative-wrap* nil
  "Negative indices wrap around")

;; FIXME? not the same as CL-PPCRE, which is
;;        '(#\Space #\Tab #\Linefeed #\Return #\Page)
;;        Some functions use *WHITESPACES* (trim) while other
;;        functions use a regex "\\s+" (e.g. collapse-whitespaces),
;;        a.k.a. implicitly the above list
(defvar *whitespaces* '(#\Space #\Newline #\Backspace #\Tab
                        #\Linefeed #\Page #\Return #\Rubout))

(defvar +version+ "0.18.1")

(defun version ()
  (print +version+))

;; as a dedicated condition to help detect it in tests
;; (up to 0.18.1 a negative index would mean zero)
(define-condition negative-index (warning) ()
  (:report
   "STR possible breaking change: negative index means 'from end' now"))

(declaim (inline index))

(defun index (string/length index
              &key
                (warnp t)
                (negative-wrap *negative-wrap*))
  ""
  (declare (type (or null fixnum) index)
           (type (or vector array-total-size) string/length))
  (let ((length (etypecase string/length
                  (string (length string/length))
                  (array-total-size string/length))))
    (cond
      ((member index '(nil t)) length)
      ((= 0 length) 0)
      (t
       (locally (declare (type (and fixnum (not (eql 0))) length))
         (cond
           (negative-wrap
            (when (and warnp (< index 0))
              (warn 'negative-index))
            (multiple-value-bind (quotient mod) (floor index length)
              (if (<= -1 quotient 0)
                  ;; wrap when index is between -length and length
                  mod
                  ;; otherwise clamp to either side
                  (if (< quotient 0) 0 length))))
           (t (min (max index 0) length))))))))

(defmacro with-indices ((&rest indices) length-designator
                        &body body)
  "Ensure INDICES are computed by function INDEX in BODY.

LENGTH-DESIGNATOR is a string or a non-negative integer.

INDICES is a list of either a symbol NAME or a couple (NAME VALUE); if
only NAME is provided, NAME is expected to be bound in the current
context to the VALUE associated with NAME.

Inside BODY, each NAME is bound by LET* to (INDEX STRING VALUE).

    (with-indices ((x (or x 0)) y) \"abc\" ...)

is equivalent to:

    (let* ((x (index \"abc\" (or x 0)))
           (y (index \"abc\" y)))
      ...)

"
  (let ((length-var (gensym "LENGTH-")))
    `(let ((,length-var ,length-designator))
       ,(flet ((let-binding (index)
                 (let ((index (if (listp index) index (list index))))
                   (destructuring-bind (name &optional value) index
                     (let ((index-expr (or value name)))
                       `(,name (index ,length-var ,index-expr)))))))
          `(let* ,(mapcar #'let-binding indices)
             ,@body)))))

(declaim (inline unsafe-slice))

(defun unsafe-slice (start end s sharedp)
  "START and END are expected to be valid indices for string S"
  (let ((length (- end start)))
    (cond
      ((<= length 0) "")
      ((not sharedp) (subseq s start end))
      (t (make-array length
                     :element-type (array-element-type s)
                     :displaced-to s
                     :displaced-index-offset start)))))

(defun slice (start end s &key (sharedp *sharedp*))
  (when s
    (with-indices ((start (or start 0)) end) (s :warnp nil)
      (unsafe-slice start end s sharedp))))

(defun whitespacep (char)
  (member char *whitespaces*))

(setf (fdefinition 'whitespace?) #'whitespacep)

;; internal
(defun trim-left-if (p s)
  (let ((beg (position-if-not p s)))
    (if beg
        (slice beg nil s)
        "")))

;; internal
(defun trim-right-if (p s)
  (let ((end (position-if-not p s :from-end t)))
    (if end
        (slice 0 (1+ end) s)
        "")))

;; internal
(defun trim-if (p s)
  (let ((beg (position-if-not p s))
        (end (position-if-not p s :from-end t)))
    (if (and beg end)
        (slice beg (1+ end) s)
        "")))

(defun trim-left (s)
  "Remove whitespaces at the beginning of s. "
  (when s
    (trim-left-if #'whitespacep s)))

(defun trim-right (s)
  "Remove whitespaces at the end of s."
  (when s
    (trim-right-if #'whitespacep s)))

(defun trim (s)
  "Remove whitespaces at the beginning and end of s.
@begin[lang=lisp](code)
(trim \"  foo \") ;; => \"foo\"
@end(code)"
  (when s
    (trim-if #'whitespacep s)))

(defun collapse-whitespaces (s)
  "Ensure there is only one space character between words.
  Remove newlines."
  ;; FIXME? use \\s everywhere we need whitespace? trim could be based
  ;; on regexes too; OR, match against
  ;; '(:greedy-repetition 1 NIL (:char-class #.*WHITESPACES*))
  ;; (is *WHITESPACES* supposed to be constant?)
  (ppcre:regex-replace-all "\\s+" s " "))

(defun concat (&rest strings)
  "Join all the string arguments into one string."
  (apply #'concatenate 'string strings))

(defun join (separator strings)
  "Join all the strings of the list with a separator."
  (let ((separator (replace-all "~" "~~" (string separator))))
    (format nil (concat "~{~a~^" separator "~}") strings)))

(defun insert (string/char index s &key (wrap nil))
  "Insert the given string (or character) at the `index' into `s' and return a new string.

   If `index' or `string/char' is NIL, ignore and return `s'."
  (cond
    ((and s index string/char)
     ;; insert _ in "abcd" at -1 means "abcd_", not "abc_d"
     (with-indices (index) ((1+ (length s)) :negative-wrap wrap)
       (concat (slice 0 index s :sharedp t)
               (string string/char)
               (slice index t s :sharedp t))))
    (t s)))

(defun split (separator s &key (omit-nulls *omit-nulls*) limit (start 0) end)
  "Split s into substring by separator (cl-ppcre takes a regex, we do not).

  `limit' limits the number of elements returned (i.e. the string is
  split at most `limit' - 1 times)."
  ;; cl-ppcre:split doesn't return a null string if the separator appears at the end of s.
  (let* ((limit (or limit (1+ (length s))))
         (res (cl-ppcre:split (cl-ppcre:quote-meta-chars (string separator))
                              s :limit limit :start start :end end :sharedp *sharedp*)))
    (if omit-nulls
        (delete-if #'empty? res)
        res)))

(defun split-omit-nulls (separator s)
  "Call split with :omit-nulls to t.

   Can be clearer in certain situations.
  "
  (split separator s :omit-nulls t))

(defun substring (start end s)
  "Return the substring of `s' from `start' to `end'.

It uses `subseq' with differences:
- argument order, s at the end
- `start' and `end' can be lower than 0 or bigger than the length of s.
- for convenience `end' can be nil or t to denote the end of the string.
"
  (let* ((s-length (length s))
         (end (cond
                ((null end) s-length)
                ((eq end t) s-length)
                (t end))))
    (setf start (max 0 start))
    (if (> start s-length)
        ""
        (progn
          (setf end (min end s-length))
          (when (< end (- s-length))
            (setf end 0))
          (when (< end 0)
            (setf end (+ s-length end)))
          (if (< end start)
              ""
              (subseq s start end))))))

(defparameter *ellipsis* "..."
  "Ellipsis to add to the end of a truncated string (see `shorten').")

(defun prune (len s &key (ellipsis *ellipsis*))
  "Old name for `shorten'."
  (shorten len s :ellipsis ellipsis))

(defun shorten (len s &key (ellipsis *ellipsis*))
  "If s is longer than `len', truncate it to this length and add the `*ellipsis*' at the end (\"...\" by default). Cut it down to `len' minus the length of the ellipsis."
  (when (and len
             (< len
                (length s)))
    (let ((end (max (- len (length ellipsis))
                    0)))
      (setf s (concat
               (unsafe-slice 0 end s t)
               ellipsis))))
  s)

(defun words (s &key (limit 0))
  "Return list of words, which were delimited by white space. If the optional limit is 0 (the default), trailing empty strings are removed from the result list (see cl-ppcre)."
  (when s
    (cl-ppcre:split "\\s+" (trim-left s) :limit limit :sharedp *sharedp*)))

(defun unwords (strings)
  "Join the list of strings with a whitespace."
  (join " " strings))

(defun lines (s &key (omit-nulls *omit-nulls*))
  "Split the string by newline characters and return a list of lines. A terminal newline character does NOT result in an extra empty string."
  (when (and s (> (length s) 0))
    (let ((end (if (eql #\Newline (elt s (1- (length s))))
                   (1- (length s))
                   nil)))
     (split #\NewLine s :omit-nulls omit-nulls :end end))))

(defun unlines (strings)
  "Join the list of strings with a newline character."
  (join (make-string 1 :initial-element #\Newline) strings))

(defun repeat (count string/char)
  "Make a string of S repeated COUNT times."
  (etypecase string/char
    (character (make-string count :initial-element string/char))
    (string (apply #'concat (make-list count :initial-element string/char)))))

(defun replace-first (old new s)
  "Replace the first occurence of `old` by `new` in `s`. Arguments are not regexs."
  (let* ((cl-ppcre:*allow-quoting* t)
         (old (concatenate 'string  "\\Q" old))) ;; treat metacharacters as normal.
    (cl-ppcre:regex-replace old s new)))

(defun replace-all (old new s)
  "Replace all occurences of `old` by `new` in `s`. Arguments are not regexs."
  (let* ((cl-ppcre:*allow-quoting* t)
         (old (concatenate 'string  "\\Q" old))) ;; treat metacharacters as normal.
    ;; We need the (list new): see !52
    (cl-ppcre:regex-replace-all old s (list new))))

;; About the (list new) above:
#+nil
(progn
  ;; This is wrong:
  (format t "~&This replacement is wrong: ~a~&" (ppcre:regex-replace-all "8" "foo8bar" "\\'"))
  ;; => foobarbar
  (format t "and this is OK: ~a~&" (ppcre:regex-replace-all "8" "foo8bar" (list "\\'")))
  ;; foo\'bar
  )

(defun replace-using (plist s)
  "Replace all associations given by pairs in a plist and return a new string.

  The plist is a list alternating a string to replace (case sensitive) and its replacement.

  Example:
  (replace-using (list \"{{phone}}\" \"987\")
                 \"call {{phone}}\")
  =>
  \"call 987\"

  It calls `replace-all' as many times as there are replacements to do."
  (check-type plist list)
  (dotimes (i (- (length plist)
                 1))
    (setf s (str:replace-all (nth i plist) (nth (incf i) plist) s)))
  s)

(defun empty? (s)
  "Is s nil or the empty string ?"
  (or (null s) (string-equal "" s)))

(defun emptyp (s)
  "Is s nil or the empty string ?"
  (empty? s))

(defun non-empty-string-p (s)
  "Return t if `s' is a string and is non-empty.

  Like `(not (empty? s))', with a `stringp' check. Useful in context."
  (and (stringp s)
       (not (emptyp s))))

(defun blank? (s)
  "Is s nil or only contains whitespaces ?"
  (or (null s) (string-equal "" (trim s))))

(defun blankp (s)
  "Is s nil or only contains whitespaces ?"
  (blank? s))

(defun non-blank-string-p (s)
  "Return t if `s' is a string and is non blank (it doesn't exclusively contain whitespace characters).

  Like `(not (blank? s))', with a `stringp' check. Useful in context."
  (and (stringp s)
       (not (blankp s))))

(defun starts-with? (start s &key (ignore-case *ignore-case*))
  "Return t if s starts with the substring 'start', nil otherwise."
  (when (>= (length s) (length start))
    (let ((fn (if ignore-case #'string-equal #'string=)))
      (funcall fn s start :start1 0 :end1 (length start)))))

;; An alias:
(setf (fdefinition 'starts-with-p) #'starts-with?)

(defun ends-with? (end s &key (ignore-case *ignore-case*))
  "Return t if s ends with the substring 'end', nil otherwise."
  (when (>= (length s) (length end))
    (let ((fn (if ignore-case #'string-equal #'string=)))
      (funcall fn s end :start1 (- (length s) (length end))))))

(setf (fdefinition 'ends-with-p) #'ends-with?)

(defun contains? (substring s &key (ignore-case *ignore-case*))
  "Return `t` if `s` contains `substring`, nil otherwise. Ignore the case with `:ignore-case t`.
A simple call to the built-in `search` (which returns the position of the substring)."
  (let ((a (if ignore-case
               (string-downcase substring)
               substring))
        (b (if ignore-case
               (string-downcase s)
               s)))
    ;; weird case: (search "" nil) => 0
    (if (and (blank? substring)
             (null s))
        nil
        (if (search a b)
            t))))

(setf (fdefinition 'containsp) #'contains?)

(defun base-displacement (array)
  "Flatten the displacement chain from ARRAY up to a base array.

Return either ARRAY or a new array displaced to a non-displaced array."
  (labels ((recurse (array origin)
             (multiple-value-bind (parent index) (array-displacement array)
               (if parent
                   (recurse parent (+ origin index))
                   (values array origin)))))
    (multiple-value-bind (base offset) (recurse array 0)
      (if (or (eq base array)
              (eq base (array-displacement array)))
          array
          (make-array (length array)
                      :element-type (array-element-type base)
                      :displaced-to base
                      :displaced-index-offset offset)))))

(defun prefix-1 (item1 item2)
  (slice 0 (mismatch item1 item2) item1))

(defun prefix (items)
  "Find the common prefix between strings.

   Uses the built-in `mismatch', that returns the position at which
   the strings fail to match.

   Example: `(str:prefix '(\"foobar\" \"foozz\"))` => \"foo\"

   - items: list of strings
   - Return: a string.

  "
  (when items
    (base-displacement (reduce #'prefix-1 items))))

(defun common-prefix (items)
  (warn "common-prefix is deprecated, use prefix instead.")
  (prefix items))

(defun suffix-1 (item1 item2)
  (slice (mismatch item1 item2 :from-end t) nil item1))

(defun suffix (items)
  "Find the common suffix between strings.

   Uses the built-in `mismatch', that returns the position at which
   the strings fail to match.

   Example: `(str:suffix '(\"foobar\" \"zzbar\"))` => \"bar\"

   - items: list of strings
   - Return: a string.

  "
  (when items
    (base-displacement (reduce #'suffix-1 items))))

;; FIXME? Is (prefix? '("boo" "boomerang") "bo") T or NIL?
(defun prefix? (items s)
  "Return s if s is common prefix between items."
  (when (string= s (prefix items)) s))

(setf (fdefinition 'prefixp) #'prefix?)

;; FIXME? Same as prefix?
(defun suffix? (items s)
  "Return s if s is common suffix between items."
  (when (string= s (suffix items)) s))

(setf (fdefinition 'suffixp) #'suffix?)

(defun add-prefix (items s)
  "Prepend s to the front of each items."
  (mapcar #'(lambda (item) (concat s item)) items))

(defun add-suffix (items s)
  "Append s to the end of eahc items."
  (mapcar #'(lambda (item) (concat item s)) items))

(defun pad (len s &key (pad-side *pad-side*) (pad-char *pad-char*))
  "Fill `s' with characters until it is of the given length. By default, add spaces on the right.

Filling with spaces can be done with format:

    (format nil \"~v@a\" len s) ;; with or without the @ directive

`pad-side': to pad `:right' (the default), `:left' or `:center'.
`pad-char': padding character (or string of one character). Defaults to a space."
  (if (< len (length s))
      s
      (flet ((pad-left (len s &key (pad-char *pad-char*))
               (concat (repeat (- len (length s)) pad-char) s))
             (pad-right (len s &key (pad-char *pad-char*))
               (concat s (repeat (- len (length s)) pad-char)))
             (pad-center (len s &key (pad-char *pad-char*))
               (multiple-value-bind (q r)
                   (floor (- len (length s)) 2)
                 (concat (repeat q pad-char)
                         s
                         (repeat (+ q r) pad-char)))))

        (unless (characterp pad-char)
          (if (>= (length pad-char) 2)
              (error "pad-char must be a character or a string of one character.")
              (setf pad-char (coerce pad-char 'character))))
        (case pad-side
          (:right
           (pad-right len s :pad-char pad-char))
          (:left
           (pad-left len s :pad-char pad-char))
          (:center
           (pad-center len s :pad-char pad-char))
          (t
           (error "str:pad: unknown padding side with ~a" pad-side))))))

(defun pad-left (len s &key (pad-char *pad-char*))
  (pad len s :pad-side :left :pad-char pad-char))

(defun pad-right (len s &key (pad-char *pad-char*))
  (pad len s :pad-side :right :pad-char pad-char))

(defun pad-center (len s &key (pad-char *pad-char*))
  (pad len s :pad-side :center :pad-char pad-char))

(defun from-file (pathname &rest keys)
  "Read the file and return its content as a string.

It simply uses uiop:read-file-string. There is also uiop:read-file-lines.

Example: (str:from-file \"path/to/file.txt\" :external-format :utf-8)

- external-format: if nil, the system default. Can be bound to :utf-8.
"
  (apply #'uiop:read-file-string pathname keys))

(defun to-file (pathname s &key (if-exists :supersede) (if-does-not-exist :create))
  "Write string `s' to file `pathname'. If the file does not exist, create it (use `:if-does-not-exist'), if it already exists, replace its content (`:if-exists').

Returns the string written to file."
  (with-open-file (f pathname :direction :output :if-exists if-exists :if-does-not-exist if-does-not-exist)
    (write-sequence s f)))

(defmacro string-case (str &body forms)
  "A case-like macro that works with strings (case works only with symbols).

  Example:

  (str:string-case input
    (\"foo\" (do something))
    (nil (print \"input is nil\")
    (otherwise (print \"none of the previous forms was caught\")))

  You might also like pattern matching. The example below with optima is very similar:

  (optima:match \"hey\"
    (\"hey\" (print \"it matched\"))
    (otherwise :nothing))

  Note that there is also http://quickdocs.org/string-case/.
  "
  ;; thanks koji-kojiro/cl-repl
  (let ((test (gensym)))
    `(let ((,test ,str))
       (cond
         ,@(loop :for (s  f) :in forms
              :if (stringp s) :collect `((string= ,test ,s) ,f)
              :else :if (string= s 'otherwise) :collect `(t ,f)
              :else :collect `((eql ,test ,s) ,f))))))

(defun s-first (s)
  "Return the first substring of `s'."
  (if (null s)
      nil
      (if (empty? s)
          ""
          (slice 0 1 s))))

(defun s-last (s)
  "Return the last substring of `s'."
  (if (null s)
      nil
      (if (empty? s)
          ""
          (slice (1- (length s)) nil s))))

(defun s-rest (s)
  "Return the rest substring of `s'."
  (if (null s)
      nil
      (if (empty? s)
          ""
          (slice 1 nil s))))

(defun s-nth (n s)
  "Return the nth substring of `s'.

   You could also use
   (string (elt \"test\" 1))
   ;; => \"e\""
  (cond ((null s) nil)
        ;; TODO negative index
        ((or (empty? s) (minusp n)) "")
        ((= n 0) (s-first s))
        (t (s-nth (1- n) (s-rest s)))))

(defun s-assoc-value (alist key)
  "Return the value of a cons cell in `alist' with key `key', tested
with `string='.
  The second return value is the cons cell."
  (let ((cons (assoc key alist :test #'string-equal)))
    (values (cdr cons) cons)))

(defun count-substring (substring s &key (start 0) (end nil))
  "Return the non-overlapping occurrences of `substring' in `s'.
  You could also count only the ocurrencies between `start' and `end'.

  Examples:
  (count-substring \"abc\" \"abcxabcxabc\")
  ;; => 3

  (count-substring \"abc\" \"abcxabcxabc\" :start 3 :end 7)
  ;; => 1"
  (unless (or (null s)
              (null substring)
              (empty? substring))
    (with-indices ((start (or start 0)) end) s
      (loop :with substring-length := (length substring)
         :for position := (search substring s :start2 start :end2 end)
         :then (search substring s :start2 (+ position substring-length) :end2 end)
         :while (not (null position))
         :summing 1))))


;;; Case

;; Small wrappers around built-ins, but they fix surprises.

(defun downcase (s)
  "Return the lowercase version of `s'.
  Calls the built-in `string-downcase', but returns nil if `s' is
  nil (instead of the string \"nil\")."
  (unless (null s)
    (string-downcase s)))

(defun upcase (s)
  "Return the uppercase version of `s'.
  Call the built-in `string-upcase', but return nil if `s' is
  nil (instead of the string \"NIL\")."
  (unless (null s)
    (string-upcase s)))

(defun capitalize (s)
  "Return the capitalized version of `s'.
  Calls the built-in `string-capitalize', but returns nil if `s' is
  nil (instead of the string \"Nil\")."
  (unless (null s)
    (string-capitalize s)))

;;; Case predicates.

(defun alphanump (s)
  "Return t if `s' contains at least one character and all characters are alphanumeric.
  See also `lettersnump' which also works on unicode letters."
  (ppcre:scan "^[a-zA-Z0-9]+$" s))

(defun alphanum? (s)
  (alphanump s))

(defun alphap (s)
  "Return t if `s' contains at least one character and all characters are alpha (in [a-zA-Z]).
  See also `lettersp', which checks for unicode letters."
  (ppcre:scan-to-strings "^[a-zA-Z]+$" s)
  ;; TODO: this regexp accepts é and ß: in lettersp like cuerdas ?
  ;; and like in python, so definitely yes.
  ;; (ppcre:scan-to-strings "^\\p{L}+$" s)
  )

(defun alpha? (s)
  (alphap s))

(defun lettersp (s)
  "Return t if `s' contains only letters (including unicode letters).

   (alphap \"éß\") ;; => nil
   (lettersp \"éß\") ;; => t"
  (when (ppcre:scan "^\\p{L}+$" s)
    t))

(defun letters? (s)
  (lettersp s))

(defun lettersnump (s)
  "Return t if `s' contains only letters (including unicode letters) and digits."
  (when (ppcre:scan "^[\\p{L}a-zA-Z0-9]+$" s)
    t))

(defun digitp (s)
  "Return t if `s' contains at least one character and all characters are numerical."
  (unless (emptyp s)
    ;; regex ? Check sign and exponents.
    (every (lambda (char)
             (digit-char-p char))
           s)))

(defun digit? (s)
  (digitp s))


(defun numericp (s)
  "alias for `digitp'."
  (digitp s))

(defun numeric? (s)
  (numericp s))

(defun has-alphanum-p (s)
  "Return t if `s' has at least one alphanumeric character."
  (unless (emptyp s)
    (some (lambda (char)
            (alphanumericp char))
          s)))

(defun has-alpha-p (s)
  "Return t if `s' has at least one alpha character ([a-zA-Z])."
  (when (ppcre:scan "[a-zA-Z]" s)
    t))

(defun has-letters-p (s)
  "Return t if `s' contains at least one letter (considering unicode, not only alpha characters)."
  (when (ppcre:scan "\\p{L}" s)
    t))

(defun downcasep (s)
  "Return t if all alphabetical characters of `s' are lowercase, and `s' contains at least one letter."
  (if (has-letters-p s)
      (every (lambda (char)
               (if (alpha-char-p char)
                   (lower-case-p char)
                   t))
             s)))

(defun downcase? (s)
  "alias for `downcasep'."
  (downcasep s))

(defun upcasep (s)
  "Return t if all alphabetical characters of `s' are uppercase."
  (if (has-letters-p s)
    (every (lambda (char)
             (if (alpha-char-p char)
                 (upper-case-p char)
                 t))
           s)))

(defun upcase? (s)
  "alias for `upcasep'."
  (upcasep s))

(defun remove-punctuation (s &key (replacement " "))
  "Remove the punctuation characters from `s', replace them with `replacement' (defaults to a space) and strip continuous whitespace."
  (flet ((replace-non-word (string)
           (ppcre:regex-replace-all
            "[^\\p{L}\\p{N}]+"
            string
            (lambda (target start end match-start match-end reg-starts reg-ends)
              (declare (ignore target start reg-starts reg-ends))
              ;; completely remove trailing and leading non-word chars
              (if (or (zerop match-start)
                      (= match-start (- end (- match-end match-start))))
                  ""
                  ;; use replacement kwarg for non-space chars inbetween
                  replacement)))))
    (if (null s)
        ""
        (replace-non-word s))))
