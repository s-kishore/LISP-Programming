;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname pretty) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ())))
(require "extras.rkt")
(require racket/string)
(require rackunit)


(provide expr-to-strings
         make-sum-exp
         sum-exp-exprs
         make-mult-exp
         mult-exp-exprs)


;;tests are below 

;;pretty.rkt:
;;pretty is a program which takes an expression and a width and
;;returns a representation of the expression as a sequence of lines, with
;;each line represented as a string of length not greater than the width


;;sum-exp
(define-struct sum-exp (exprs))
;;a sum-exp is a (make-sum-exp NELOExpr)
;;exprs is the list of non empty expressions in the sum expresion

;;template:
;;sum-exp-fn: sum-exp -> ?
;;(define (sum-exp-fn sum-exp)
;;  (...(neloexpr-fn (sum-exp-exprs sum-exp))))

;;mult-exp
(define-struct mult-exp (exprs))
;;a mult-exp is a (make-mult-exp NELOExpr)
;;exprs is the list of non empty expressions in the mult expresion

;;template:
;;mult-exp-fn: mult-exp -> ?
;;(define (mult-exp-fn mult-exp)
;;  (...(neloexpr-fn (mult-exp-exprs mult-exp))))

;; An Expr is one of
;; -- Integer
;; -- (make-sum-exp NELOExpr)
;; -- (make-mult-exp NELOExpr)
;; Interpretation: a sum-exp represents a sum and a mult-exp
;; represents a multiplication. 

;;Destructor Template
;; expr-fn: Expr -> ??
;(define (expr-fn expr)
;  (cond
;    [(integer? expr) ...]
;    [(mult-exp? expr)...(mult-exp-fn (mult-exp-exprs expr))]
;    [(sum-exp? expr) ...(sum-exp-fn (sum-exp-exprs expr))]))


;; A LOExpr is one of
;; -- empty
;; -- (cons Expr LOExpr)
;;template:
;;loexpr-fn:loexpr -> ?
;;(define (loexpr-fn loexpr)
;;  (cond
;;    [(empty? loexpr) ...]
;;    [else (...
;;           (first loexpr)
;;           (rest loexpr))]))


;; A NELOExpr is a non-empty LOExpr and is one of
;;--(cons Expr NELOExpr)
;;--(cons Expr empty)


;(or)
; A NELOExprOther is a
; -- (cons Expr NELOExpr)

;;template:
;;(define (neloexpr-other-fn exprs)
;;  (... (first exprs) 
;;       (neloexpr-other-fn(rest exprs))))

;;template:
;;neloexpr-fn: neloexpr -> ?
;;(define (neloexpr-fn neloexpr)
;;  (cond
;;    [(empty? (rest neloexpr)) (expr-fn (first neloexpr))]
;;    [else (...
;;           (expr-fn (first neloexpr))
;;           (neloexpr-fn (rest neloexpr)))]))

;;a ListOfString (LOS) is one of
;;--empty
;;--(cons String LOS)

;;template
;;los-fn: los -> ?
;;(define (los-fn los)
;;  (cond
;;    [(empty? los) ...]
;;    [else (... (first los)
;;               (los-fn (rest los)))]))

;; a NestedString is one of
;;--String
;;--(cons String ListOf<String>)

;;template:
;;nested-string-fn: NestedString ->
;;(define (nested-string-fn ns)
;;  (cond
;;    [(string? ns) ...]
;;    [(list? ns) ...(los-fn ns)]))

;;a NELOS is a Non Empty LOS
;;--(cons String NELOS)
;;--(cons String empty)

;;template:
;;nelos-fn: nelos -> ?
;;(define (nelos-fn nelos)
;;  (cond
;;    [(empty? (rest nelos)) (string-fn (first nelos))]
;;    [else (...
;;           (string-fn (first nelos))
;;           (nelos-fn (rest nelos)))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Constants:

(define MULT-SYMBOL "(* ")
(define SUM-SYMBOL "(+ ")
(define SPACE " ")
(define CLOSE-BRACKET ")")
(define NEW-LINE-SPACE "   ")
(define INDENT-COUNT 3)
(define INCREASE-INDENT 3)
(define SYMBOL-SPACE 4)
(define TWO 2)
(define CLOSING-PARAN ")")
(define SPACE-CHAR #\ )
(define ERROR-MSG "not enough room")
(define EMPTY-STRING "")
(define PARAN-SPACE 1)


(define INPT1 (make-sum-exp (list 22 333 44)))

(define INPT2
  (make-sum-exp
   (list
    (make-mult-exp (list 22 3333 44))
    (make-mult-exp
     (list
      (make-sum-exp (list 66 67 68))
      (make-mult-exp (list 42 43))))
    (make-mult-exp (list 77 88)))))

(define INPT3
  (make-sum-exp
   (list
    (make-mult-exp (list 22 3333 44))
    (make-mult-exp
     (list
      (make-sum-exp (list 66 67 68))
      22
      (make-mult-exp (list 42 43))))
    (make-mult-exp (list 77 88)))))



(define ZERO 0)
(define STR-LIST1 (list "77 " "    88"))
(define STR-LIST2 (list "434 54 656 " "    88"))

(define INPT1-PRETTY-15 (list "(+ 22 333 44)"))

(define INPT2-PRETTY-15 '("(+ (* 22"
                          "      3333"
                          "      44)"
                          "   (* (+ 66"
                          "         67"
                          "         68)"
                          "      (* 42"
                          "         43))"
                          "   (* 77 88))"))

(define INPT2-PRETTY-20 '("(+ (* 22 3333 44)"
                          "   (* (+ 66 67 68)"
                          "      (* 42 43))"
                          "   (* 77 88))"))

(define INPT2-PRETTY-50 '("(+ (* 22 3333 44)"
                          "   (* (+ 66 67 68) (* 42 43))"
                          "   (* 77 88))" ))

(define INPT2-PRETTY-100
  '("(+ (* 22 3333 44) (* (+ 66 67 68) (* 42 43)) (* 77 88))"))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;expr-to-strings: Expr NonNegInt -> ListOfString
;;GIVEN: An expression and a width
;;RETURNS: A representation of the expression as a sequence of lines, with
;;each line represented as a string of length not greater than the width.If the
;;output is not possible within the given width, then it returns an error.
;;Examples: Refer test cases
;;Strategy: Functional Composition
(define (expr-to-strings exp width)
  (if (checked? (converted-expr-to-strings exp width ZERO) width)
  (removed-extra-spaces (converted-expr-to-strings exp width ZERO) )
  (error ERROR-MSG))
  )


;;checked? : ListOfString NonNegInt -> Boolean
;;Given: a list of strings and a width
;;Returns:Checks if each of the strings in the list are within the given width
;;Examples:
;;(checked? STR-LIST1 10) => true
;;(checked? STR-LIST1 5) => false
;;Strategy: Functional Composition
(define (checked? los width)
  (width-checked? (removed-extra-spaces los) width))


;;width-checked? ListOfString NonNegInt -> Boolean
;;Given: a list of strings and a width
;;Returns:Checks if each of the strings in the list are within the given width
;;Examples:
;;(width-checked? STR-LIST1 10) => true
;;(width-checked? STR-LIST1 5) => false
;;Strategy: HOFC
(define (width-checked? los width)
  (andmap 
   ;;String -> Boolean
   ;;Given: a String
   ;;Returns: true if the string fits with the parent width param
   (lambda (str) (<= (string-length str) width)) los))  

;;removed-extra-spaces: ListOfString -> ListOfString
;;Given: a ListOfString
;;Returns: a ListOfString with the ending space removed, if there is space at
;;the end of the string
;;Examples:
;;(removed-extra-spaces STR-LIST1) => (list "7" "    8")
;;(removed-extra-spaces STR-LIST2) => (list "434 54 656" "    8")
;;Strategy: HOFC
(define (removed-extra-spaces los)
  (map removed-last-space los))

;;last-integer? ListOfString -> Boolean
;;Given: a reversed ListOfString
;;Returns: true iff the last string in the list is an integer
;;Examples:
;;(last-integer? (list "23" "as")) => false
;;(last-integer? (list "23" "43")) => true
;;Stratgey: Structural Decomposition on los: ListOfString
(define (last-integer? los)
  (cond
    [(empty? los) empty]
    [else (integer? (string->number (first-of-string-list (string-split
                                                           (first los)))))]))

;;removed-last-space: String -> String
;;Given: a String
;;Returns: if the last string in a split string of the given string is an 
;;integer, then the given string is returned with the ending space removed
;;Examples:
;;(removed-last-space "as ewe 12 ") => "as ewe 12"
;;(removed-last-space "as ewe ygj) ") => "as ewe ygj) "
;;Strategy: Functional Composition
(define (removed-last-space str)
  (if (last-integer? (reverse(string-split str)))
      (substring str ZERO (sub1 (string-length str)))
      str))

;;converted-expr-to-strings: Expr NonNegInt NonNegInt -> ListOfString
;;Given: an Expr, the maximum width
;;Where: indent is the number of spaces that is added before the expression 
;;string
;;Returns: A representation of the expression as a sequence of lines, with
;;each line represented as a string of length not greater than the width.If the
;;output is not possible within the given width, then it returns an error.
;;Examples:refer test cases
;;Strategy:Structural Decomposition on exp: Expr
(define (converted-expr-to-strings exp width indent)
  (cond
    [(integer? exp) (int-exp-to-string exp width indent)]
    [(mult-exp? exp) (mult-expr-to-string (mult-exp-exprs exp) width indent)]
    [(sum-exp? exp) (sum-expr-to-string (sum-exp-exprs exp) width indent)]))


;;int-exp-to-string:  Expr NonNegInt NonNegInt -> ListOfString
;;Given: an integer expression, maximum width
;;Where: indent is the number of spaces that is added before the expression 
;;string
;;Returns: if the width is enough, it will return the expresion converted to
;;list of string
;;Examples: 
;;(int-exp-to-string 32 5 5)  => not enough room
;;(int-exp-to-string  121 10 2) => (list "121")
;;Strategy:Functional Composition
(define (int-exp-to-string exp width indent)
  (if (<= (+ indent (string-length (number->string exp))) width)
      (list  (string-append (number->string exp) SPACE ))
      (error ERROR-MSG)))


;;mult-expr-to-string:  NELOExpr NonNegInt NonNegInt -> ListOfString
;;Given: a list of expressions of a mult-exp, maximum width
;;Where: indent is the number of spaces that is added before the expression 
;;string
;;Returns: if the width is enough, it will return the expresion converted to
;;list of string
;;Examples: refer test cases
;;Strategy:Functional Composition 
(define (mult-expr-to-string exprs width indent)
  (if (<= (+ SYMBOL-SPACE indent (length-of-list exprs)) width)
      (list  (reduced-expr-to-string exprs MULT-SYMBOL width indent))
      (symbol-added-reduced-expr-to-string-list exprs width MULT-SYMBOL 
                                                (+ INCREASE-INDENT indent))))

;;sum-expr-to-string:  NELOExpr NonNegInt NonNegInt -> ListOfString
;;Given: a non-empty list of expressions of a sum-exp, maximum width
;;Where: indent is the number of spaces that is added before the expression 
;;string
;;Returns: if the width is enough, it will return the expresion converted to
;;list of string
;;Examples: refer test cases
;;Strategy:Functional Composition 
(define (sum-expr-to-string exprs width indent)
  (if (<= (+ SYMBOL-SPACE indent (length-of-list exprs)) width)
      (list  (reduced-expr-to-string exprs SUM-SYMBOL width indent))
      (symbol-added-reduced-expr-to-string-list exprs width SUM-SYMBOL
                                                (+ INCREASE-INDENT indent))))


;;reduced-expr-to-string: NELOExpr String NonNegInt -> String
;;Given:  a non-empty list of expressions, symbol 
;;Where: indent is the number of spaces that is added before the expression 
;;string
;;Returns: if the width is enough, it will return a list of string, converted
;;to a single string with the mult-symbl added in the beginning
;;Examples:refer test cases
(define (reduced-expr-to-string exprs symbol width indent)
  (converted-string-from-list (cons  symbol (expr-to-string-list exprs width
                                                                 indent))))

;;indented: String -> String
;;Given: a String
;;Returns: the given String indented with space'
;;Example:
;;(indented "friend") => "   friend"
;;(indented "22") => "   22"
;;Strategy: Functional Composition
(define (indented string-exp)
  (string-append (make-string INDENT-COUNT SPACE-CHAR ) string-exp))

;;indented-list: ListOfString -> ListOfString
;;Given: a list of String
;;Returns: the given list of strings with all the strings indented
;;Examples:
;;(indented-list (list "22" "33") => (list "   22" "   33")
;;(indented-list (list "ab" "cd") => (list "   ab" "   cd")
;;Strategy: HOFC
(define (indented-list los)
  (map indented los))

;;converted-string-from-list: ListOfString->String
;;Given: a list of string
;;Returns: the given list of strings converted to a single string
;;Examples:
;;(converted-string-from-list (list "22" "33")) => "2233"
;;(converted-string-from-list (list "ab " "cd")) => "ab cd"
;;Strategy:HOFC
(define (converted-string-from-list los)
  (foldr 
   ;;String String-> String
   ;;Given: a String and result of rest of list
   ;;Returns: the string appended to the string of the rest of list
   (lambda (str result-rest) (string-append (string-from str) result-rest)) 
   EMPTY-STRING 
   los))

;;string-from: NestedString -> String
;;Given: a NestedString
;;Returns: the String in the nested string
;;Examples:
;;(string-from "22") => "22"
;;(string-from (list "ab " "cd")) => "ab cd"
;;Strategy:Structural Decomposition on ns: NestedString
(define (string-from ns)
  (cond
    [(string? ns) ns]
    [(list? ns) (converted-string-from-list ns)]))

;;expr-to-string-list: NELOExpr NonNegInt NonNegInt => ListOfString
;;Given: a list of expressions of a mult-exp, maximum width
;;Where: indent is the number of spaces that is added before the expression 
;;string
;;Returns: if the width is enough, it will return the expresion converted to
;;list of string, and will add a space between expressions
;;Examples: refer test cases
;;Strategy: Structural Decomposition on exprs: NELOExpr
(define (expr-to-string-list exprs width indent)
  (cond
    [(empty? (rest exprs)) 
     (list (ending-string-list (first exprs) width indent) CLOSING-PARAN)]
    [else (if (check-expr-mult-sum? (first exprs))
              (cons (space-added 
                     (converted-expr-to-strings (first exprs) width indent))
                    (expr-to-string-list (rest exprs) width indent))
              (cons (converted-expr-to-strings (first exprs) width indent)
                    (expr-to-string-list (rest exprs) width indent)))]))

;;space-added:ListOfString ->ListOfString
;;Given: a list containing a single string
;;Returns: the given expression with space added to the string
;;Examples:
;;(space-added (list "(+ 22)")) => "(+ 22) "
;;(space-added (list "(+ 43 34)")) => "(+ 43 34) "
;;Stratgey:Structural Decomposition on los: ListOfString
(define (space-added los)
  (cond 
    [(empty? los) empty]
    [else (string-append (first los) SPACE)]))


;;(check-expr-mult-sum?: Expr -> Boolean
;;Given: an expression
;;Returns: true if the expression is a mult-exp or a sum-exp
;;Examples:
;;(check-expr-mult-sum? 22) => false
;;(check-expr-mult-sum? (make-mult-exp (list 12))) => true
;;Strategy: Structural Decomposition on exp: Expr
(define (check-expr-mult-sum? exp)
  (cond
  [(integer? exp) false]
  [(mult-exp? exp) true]
  [(sum-exp? exp) true]))

;;ending-string-list: Expr NonNegInt NonNegInt => ListOfString
;;Given: a list of expressions of a mult-exp, maximum width
;;Where: indent is the number of spaces that is added before the expression 
;;string
;;Returns: if the width is enough, it will return the expresion converted to
;;list of string, and will trim the space in string in case of integer
;;Examples: refer test cases
;;Strategy: Structural Decomposition on exp: Expr
(define (ending-string-list exp width indent)
  (cond
    [(integer? exp) (number->string exp)]
    [(mult-exp? exp) (converted-expr-to-strings exp width indent) ]
    [(sum-exp? exp) (converted-expr-to-strings exp width indent) ]))

;;symbol-added-reduced-expr-to-string-list: NELOExpr NonNegInt String NonNegInt
;;                                          => ListOfString
;;Given:a list of expressions of a mult-exp, a symbol and maximum width
;;Where: indent is the number of spaces that is added before the expression 
;;string
;;Returns: if the width is enough, it will return the expresion converted to
;;list of string, and will add the symbol in the first string
;;Examples: refer test cases
;;Strategy: Functional Composition
(define (symbol-added-reduced-expr-to-string-list exprs width symbol indent)
  (symbol-added-first-list-helper
   (reduced-expr-to-string-list exprs width indent) symbol))

;;symbol-added-first-list-helper: ListOfString String => ListOfString
;;Given: a list of strings, a symbol and indent value
;;Returns: the given list, with symbol added to first value and the rest of the 
;; strings are indented
;;Examples: refer test cases
;;Strategy:Structural Decomposition on los: ListOfString
(define (symbol-added-first-list-helper los symbol)
  (cond
    [(empty? los) empty]
    [else (append (list (string-append symbol 
                                       (first los)))
                  (indented-list (check-int (rest los))))]))

;;check-int: NELOS -> NELOS
;;Given: a Non empty list of String
;;Returns: the given non empty list of string, with space between bracket and
;;integer removed
;;Examples:refer test cases
;;Strategy:Structural Decomposition on los: NELOS
(define (check-int los)
  (cond
    [(empty? (rest los)) (removed-last-space-bracket (first los))]
    [else (cons (first los) (check-int (rest los)))]))

;;removed-last-space-bracket: String -> String
;;Given: a String
;;Returns: if the last string in a split string of the given string is an 
;;integer, then the given string is returned with the ending space removed
;;after integer and before bracket
;;Examples:
;;(removed-last-space-bracket "as ewe 12 )") => "as ewe 12)"
;;(removed-last-space "as ewe ygj) ") => "as ewe ygj) "
;;Strategy: Functional Composition
(define (removed-last-space-bracket str)
  (if (integer? (string->number (first-of-string-list (string-split str))))
      (list (string-append (substring str ZERO (- (string-length str) TWO))
                           CLOSING-PARAN)) 
      (list str)))

;;first-of-string-list: ListOfString -> String
;;Given: a List of String
;;Returns: the first string in the list of strings
;;Examples:
;;(first-of-string-list (list "21" "23") => "22"
;;(first-of-string-list (list "abs" "23") => "abs"
;;Strategy:Structural Decomposition on los: ListOfString
(define (first-of-string-list los)
  (cond
    [(empty? los) los]
    [else (first los)]))


;;reduced-expr-to-string-list: NELOExpr NonNegInt NonNegInt => ListOfString
;;Given: a list of expressions, maximum width
;;Where: indent is the number of spaces that is added before the expression 
;;string
;;Returns: if the width is enough, it will return the expresion converted to
;;list of string
;;Examples: refer test cases
;;Strategy: Structural Decomposition on exprs: NELOExpr
(define (reduced-expr-to-string-list exprs width indent)   
  (cond
    [(empty? (rest exprs)) (ending-string (first exprs) width indent)]
    [else 
     (append  (converted-expr-to-strings (first exprs) width indent)
              (reduced-expr-to-string-list (rest exprs) width indent))]))

;;ending-string: Expr NonNegInt NonNegInt => ListOfString
;;Given: an expression, maximum width
;;Where: indent is the number of spaces that is added before the expression 
;;string
;;Returns: if the width is enough, it will return the expresion converted to
;;list of string, with a bracket attached to the last string
;;Examples:refer test cases
;;Strategy:Functional Composition
(define (ending-string exp width indent)
  (bracket-attached (converted-expr-to-strings exp width indent)))

;;bracket-attached: NELOS ->  NELOS
;;Given: a list of String
;;Returns: the given list of strings, with a bracket attached to the last string
;;in the list
;;Examples:
;;(bracket-attached (list "22" "33")) => (list "22" "33)")
;;(bracket-attached (list "ab" "cd")) => (list "ab" "cd)")
;;Strategy:Structural Decomposition on los: NELOS
(define (bracket-attached los)
  (cond
    [(empty? (rest los))  (list (string-append (first los) ")"))]
    [else  (cons (first los) (bracket-attached (rest los)))]))

;;length-of-exp: Expr-> NonNegInt
;;Given: an expression
;;Returns: the length of the expression
;;Examples:refer test cases
;;Stratgy:Structural Decomposition on exp: Expr
(define (length-of-exp exp)
  (cond
    [(integer? exp)  (+ (string-length (number->string exp)) 1 )]
    [(mult-exp? exp) ( + SYMBOL-SPACE (length-of-list (mult-exp-exprs exp)))]
    [(sum-exp? exp) ( + SYMBOL-SPACE (length-of-list(sum-exp-exprs exp)))]))

;;length-of-list: NELOExpr-> NonNegInt
;;Given: a non empty list of expression
;;Returns: the length of the list of expression
;;Examples:refer test cases
;;Stratgy:Structural Decomposition on : NELOExpr
(define (length-of-list exprs)
  (cond
    [(empty? (rest exprs))  (+ PARAN-SPACE (length-of-exp (first exprs)))]
    [else (+ (length-of-exp (first exprs)) (length-of-list (rest exprs)) )]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;tests for pretty:

(begin-for-test
  ;;mult-expr-fns
  (check-equal? (mult-expr-to-string (list 23 34) 15 2) (list "(* 23 34)"))
  ;;sum-expr-fns
  (check-equal? (sum-expr-to-string (list 23 34) 15 2) (list "(+ 23 34)"))
  ;;neloexpr input fns
  (check-equal? (reduced-expr-to-string (list 23 34) MULT-SYMBOL 10 2) 
                "(* 23 34)")
  (check-equal? (expr-to-string-list (list 23 34) 5 2) 
                (list (list "23 ") "34" ")"))
  (check-equal? (symbol-added-first-list-helper
                 (list "22 " "   (+ 23 34))")  MULT-SYMBOL)
                (list "(* 22 " "      (+ 23 34))"))
  (check-equal? (symbol-added-reduced-expr-to-string-list 
                 (list 22 (make-sum-exp (list 23 34))) 15 MULT-SYMBOL 2)
                (list "(* 22 " "   (+ 23 34))"))
  (check-equal? (reduced-expr-to-string-list 
                 (list (make-sum-exp (list 23 34))) 15 2) 
                (list "(+ 23 34))") ) 
  ;;LOS-fns
  (check-equal? (last-integer? (list )) empty)
  (check-equal? (ending-string (make-sum-exp (list 23 34)) 15 2)
                (list "(+ 23 34))"))
  (check-equal? (bracket-attached (list "22" "33")) (list "22" "33)"))
  ;;Expr-fns
  (check-equal? (ending-string-list (make-sum-exp (list 23 34)) 15 2) 
                (list "(+ 23 34)"))
  (check-equal? (converted-expr-to-strings (make-sum-exp (list 23 34)) 15 2) 
                (list "(+ 23 34)"))
  (check-equal? (symbol-added-first-list-helper (list ) MULT-SYMBOL) empty)
  (check-equal? (first-of-string-list (list )) empty)
  (check-true (check-expr-mult-sum? (make-mult-exp (list 12))))  
  ;;length-fns
  (check-equal? (length-of-exp (make-sum-exp (list 23 34))) 11)
  (check-equal? (length-of-exp (make-mult-exp (list 23 34))) 11)
  (check-equal? (length-of-list (list (make-sum-exp (list 23 34)))) 12)
  ;; main function: expr-to-strings test cases
  (check-error (expr-to-strings INPT2 11)
                 ERROR-MSG)
  (check-equal? (expr-to-strings INPT2 15)
                INPT2-PRETTY-15
                "Inccorect Output. Should have been INPT2-PRETTY-15")
  (check-equal? (expr-to-strings INPT2 20)
                INPT2-PRETTY-20
                "Inccorect Output. Should have been INPT2-PRETTY-20")
  (check-equal? (expr-to-strings INPT2 50)
                INPT2-PRETTY-50
                "Inccorect Output. Should have been INPT2-PRETTY-50")
  (check-equal? (expr-to-strings INPT2 100)
                INPT2-PRETTY-100
                "Inccorect Output. Should have been INPT2-PRETTY-100"))









