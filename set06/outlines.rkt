;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname outlines) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ())))
; outlines.rkt

; In this problem, we change an outline of text from nested format to flat
; format. We could represent such an outline as a list with one element per 
; section or subsection. Each element of the list consists of two members: 
; the section number, represented as a list of natural numbers, and a string. 
; This is the flat-list representation.
; A different representation would represent an outline as a list of sections
; where a section contains a title, which is a string, and a list of subsections
; This is a nested-list representation.

(require rackunit)
(require "extras.rkt")

; PROVIDE FUNCTIONS
(provide nested-rep?
         nested-to-flat)
;_______________________________________________________________________________
; DATA DEFINITIONS

;An Sexp is one of the following
;-- a String
;-- a NonNegInt
;-- a ListOfSexp

; INTERPRETATION:
;   a Sexp represents an element which is either a String or a NonNegInt or a 
;   ListOfSexp

; TEMPLATE: 
; sexp-fn : Sexp -> ??
; (define (sexp-fn s)
;   (cond
;     [(string? s) ...]
;     [(nonnegint? s) ...]
;     [else (... (los-fn s))]))

;A ListOfSexp is one of
;-- empty
;-- (cons Sexp ListOfSexp)

; INTERPRETATION:
; the ListOfSexp can either be empty or contain a list made of Sexp and a list
;  ListOfSexp

; TEMPLATE:
; los-fn : ListOfSexp -> ??
; (define (los-fn los)
;   (cond
;     [(empty? los) ...]
;     [else (... (sexp-fn (first los))
;                (los-fn (rest los)))]))

;_______________________________________________________________________________
; A NestedRep is either of
;  -- (cons NestedOutLine NestedRep)    
;       INTERPRETATION: a list representing a NestedOutLine and a NestedRep 
;                       representing the rest of the nested outlines.
;  -- (cons NestedOutLine empty)
;       INTERPRETATION: a list containing an NestedOutLine 

;  .
; Template:
; nestedrep-fn : NestedRep -> ??
; (define (nestedrep-fn nrep)  CHEK FORMAT
;     (cond
;       [(empty? nresp) empty]
;       [else
;        (...
;         (nestedoutline-fn (first nrep))
;         (nestedrep-fn (rest nrep)))]))
;
; A NestedOutLine is either of
; -- (cons String Empty)            interps: Represents a single outline.
; -- (cons String NestedOutLine)    interps: A list containing an outline and a 
;                                            nested outline.           

; Template:                                             
; nestedoutline-fn : NestedOutLine -> ??
;(define (nestedoutline-fn nol) CHECK FORMAT
;    (cond
;      [(empty? (rest nol)) (string? (first nol))]
;      [else
;       (...
;        (string? (first nol))
;        (nestedoutline-fn (rest nol)))]))

;_______________________________________________________________________________
; A FlatRep is either of
; -- (cons FlatOutLine FlatRep)
;    interp: a list containing  an outline in flat representation and a 
;             FlatRep which represents the rest of the outlines.
;    
; -- (cons FlatOutLine empty)
;    interp: a list containing an outline represented in flat representation.

; Template:
; flatrep-fn : FlatRep -> ??
; (define (flatrep-fn frep)
;   (cond
;     [(empty? (rest frep))
;      (flatoutline-fn (first frep))]
;     [(else
;         (...
;          (flatoutline-fn (first frep))
;          (flatrep-fn (rest frep))))]))

; A FlatOutLine is either of
; -- (cons ListOf<PosInteger> String)
;  interps: a list containing a list of natural numbers 
;           and a string representing an outline.

; Template:
; flatoutline-fn : FlatOutLine -> ??
; (define (flatoutline-fn fol)
;     (... (first fol))
;      (flatrep-fn (rest fol)))
;_______________________________________________________________________________

;CONSTANTS
(define ONE 1)

; TEST CONSTANTS
(define VALID-INPUT1
  '(
    ("The first section"
     ("A subsection with no subsections")
     ("Another subsection"
      ("This is a subsection of 1.2")
      ("This is another subsection of 1.2"))
     ("The last subsection of 1"))
    ("Another section"
     ("More stuff")
     ("Still more stuff"))))

(define INVALID-INPUT
  '(
    ("The first section"
     (123 "A subsection with no subsections")
    ("Another section"
     ("More stuff")
     ("Still more stuff")))))

(define INPT2
  '(
    ("The first section"
     ("A subsection with no subsections")
     ("Another subsection"
      ("This is a subsection of 1.2")
      (12))
     (555))
    ("Another section"
     ("More stuff")
     ("Still more stuff"))))

(define  OUTPUT1
(list
 (list (list 1) "The first section")
 (list (list 1 1) "A subsection with no subsections")
 (list (list 1 2) "Another subsection")
 (list (list 1 2 1) "This is a subsection of 1.2")
 (list (list 1 2 2) "This is another subsection of 1.2")
 (list (list 1 3) "The last subsection of 1")
 (list (list 2) "Another section")
 (list (list 2 1) "More stuff")
 (list (list 2 2) "Still more stuff")))

(define FLAT-REP-PARA1-INPT1
  (list
   (list (list 1) "The first section")
   (list (list 1 1) "A subsection with no subsections")
   (list (list 1 2) "Another subsection")
   (list (list 1 2 1) "This is a subsection of 1.2")
   (list (list 1 2 2) "This is another subsection of 1.2")
   (list (list 1 3) "The last subsection of 1")))

(define LINEITEM-OUTPUT
  (list (list (list 1) "The first section")))


;_______________________________________________________________________________
; nested-rep? : Sexp -> Boolean
;    GIVEN: an Sexp
;  RETURNS: true iff it is the nested representation of some outline
; EXAMPLES: (nested-rep? 123) => false
;           (nested-rep? "#\C") => false
;           (nested-rep? INPT2) => true
; STRATEGY: Function Composition

(define (nested-rep? inpt)
  (cond [(is-string-intgr? inpt) false]
        [else (is-losexp? inpt)]))

;_______________________________________________________________________________
; is-losexp? : Sexp -> Boolean
;    GIVEN: an Sexp
;  RETURNS: true iff it's a nested representation is a list of strings or
;            integers else false
; EXAMPLES: (is-losexp? "#\C") => false
;           (is-losexp? (first VALID-INPUT1)) => true
; STRATEGY: Higher Order Function Composition 

(define (is-losexp? inpt)                   
  (andmap 
   ; Sexp -> Boolean
   ;   Given: a simple expression
   ; Returns: true iff the given list is made of sexp
   nested-format?
          inpt))

;_______________________________________________________________________________
; nested-format? : Sexp -> Boolean
;    GIVEN: an Sexp
;  RETURNS: true iff the input is either a string or an integer
; EXAMPLES: (nested-format? empty) => false
;           (nested-format? "String") => true
;           (nested-format? 123) => true
; STRATEGY: Function Composition

(define (nested-format? inpt)
  (cond [(is-string-intgr? inpt) false]
        [else (nested-sub-list? inpt)]))

;_______________________________________________________________________________
; nested-sub-list? : Sexp -> Boolean
;    GIVEN: an Sexp
;  RETURNS: true iff the input is either a string or an integer
; EXAMPLES: (nested-format? 123) => true
; STRATEGY: Function Composition

(define (nested-sub-list? inpt)
  (cond
    [(empty? inpt) false]
    [else (nested-sub-list-helper inpt)]))

;_______________________________________________________________________________
; nested-sub-list-helper : Sexp -> Boolean
;    GIVEN: an Sexp
;  RETURNS: true iff the input is either a string or an integer
; EXAMPLES: (nested-sub-list-helper "String") => true
; STRATEGY: Structural Decomposition on inpt: Sexp

(define (nested-sub-list-helper inpt)
  (if (is-string-intgr? (first inpt))
      (is-losexp? (rest inpt))
      false))
;_______________________________________________________________________________
; is-string-intgr? : Sexp -> Boolean
;    GIVEN: an Sexp
;  RETURNS: true iff the input is either a string or an integer
; EXAMPLES: (nested-sub-list-helper "String") => true
; STRATEGY: Function Composition

(define (is-string-intgr? inpt)
  ( or (string? inpt)
       (integer? inpt)))

;TEST CASES:

(begin-for-test
  (check-equal? (nested-rep? VALID-INPUT1)
                #t
                "Inccorect output. Should be true since inputed value is a valid
                 Nested expression")
  (check-equal? (nested-sub-list? empty)
                #f
                "Incorrect Output. Should be false input value is invalid")
  
  (check-equal? (nested-format? "HI")
                #f
                "Incorrect Output. Should be false input value is invalid")
  
  (check-equal? (nested-rep? "HI")
                #f
                "Incorrect Output. Should be false input value is invalid")
    
  (check-equal? (nested-sub-list-helper '(s))
                #f
                "Inccorect output. Should be true since inputed value is a valid
                 Nested expression"))
;_______________________________________________________________________________
;nested-to-flat : NestedRep -> FlatRep
;    GIVEN: the representation of an outline as a nested list
;  RETURNS: the flat representation of the outline
; EXAMPLES: (nested-to-flat VALID-INPUT1) => OUTPUT1
; STRATEGY: Function Composition

(define (nested-to-flat inpt)
  (convert-to-flat inpt ONE empty))

;_______________________________________________________________________________
;convert-to-flat : NestedRep Integer Listof<Natural Numbers> -> FlatRep
;    GIVEN: the representation of an outline as a nested list, the current level
;           number and a list containing the parent level numbers
;  RETURNS: the flat representation of the outline
;    WHERE: x is a postive integer holding the position of a sublist
;           prevlev is a list containing numbers representing the node's 
;           parent's level from the base level
; EXAMPLES: (convert-to-flat VALID-INPUT1 ONE empty) => OUTPUT1
; STRATEGY: Structural Decomposition on sexp : Sexp

(define (convert-to-flat sexp x prevlev)
  (cond [(empty? sexp) empty]
        [else (append (convert-to-flat-helper (first sexp) x prevlev)
                    (convert-to-flat (rest sexp) (+ x ONE) empty))]))

;_______________________________________________________________________________
;convert-to-flat-helper : NestedRep Integer Listof<Natural Number> -> FlatRep
;    GIVEN: the representation of an outline as a nested list, the current level
;           number and a list containing parent level numbers
;  RETURNS: the flat representation of the outline
;    WHERE: x is a postive integer holding the position of a sublist
;           prevlev is a list containing numbers representing the node's 
;           parent's level from the base level
; EXAMPLES: (convert-to-flat-helper (first VALID-INPUT1) ONE empty) 
;                                                        => FLAT-REP-PARA1-INPT1
; STRATEGY: Structural Decomposition on sexp : Sexp

(define (convert-to-flat-helper sexp x prevlev)
  (if (empty? (rest sexp))
      (create-line-item (first sexp) x prevlev)
      (append (create-line-item (first sexp) x prevlev)
              (reduce-list-to-string (rest sexp) 
                                     ONE 
                                     (append prevlev (list x))))))

;_______________________________________________________________________________
;create-line-item : NestedOutLine Integer Listof<Natural Number> -> FlatOutLine
;    GIVEN: the representation of an outline as a nested list,the current level 
;           number and a list containing the parent level numbers
;  RETURNS: the flatotline representation of the NestedOutLine
;    WHERE: x is a postive integer holding the position of a sublist
;           prevlev is a list containing numbers representing the node's 
;           parent's level from the base level
; EXAMPLES: (create-line-item (first (first VALID-INPUT1)) ONE empty) 
;                                                        => LINEITEM-OUTPUT
; STRATEGY: Function Composition

(define (create-line-item sexp x prevlev)  
      (list (list(generate-para-no x prevlev)
                 sexp
                 )))

;_______________________________________________________________________________
;generate-para-no : Integer Listof<Natural Number> -> Listof<Natural Number>
;    GIVEN: the current level number and a list containing the current level and
;           sublevel numbers
;  RETURNS: a list containing the current level number along with the parent
;           level numbers
;    WHERE: x is a postive integer holding the position of a sublist
;           prevlev is a list containing numbers representing the node's 
;           parent's level from the base level
; EXAMPLES: (generate-para-no 5 (list 1 2)) => (list 1 2 5)
; STRATEGY: Function Composition

(define (generate-para-no x prevlev)
  (if (empty? prevlev)
                 (list x)
                 (append prevlev (list x))))

;_______________________________________________________________________________
;reduce-list-to-string: NestedOutLine Integer Listof<Natural No> -> FlatOutLine
;    GIVEN: the representation of an outline as a nested list
;  RETURNS: the flatotline representation of the NestedOutLine
;    WHERE: x is a postive integer holding the position of a sublist
;           prevlev is a list containing numbers representing the node's 
;           parent's level from the base level
; EXAMPLES: (reduce-list-to-string (rest (first VALID-INPUT1)) ONE (list 1))
;                                                        => FLAT-REP-PARA1-INPT1
; STRATEGY: Structural Decomposition on sexp : Sexp

(define (reduce-list-to-string sexp x prevlev)
  (cond [(empty? sexp) empty]
        [else (append (convert-to-flat-helper (first sexp) x prevlev)
                    (reduce-list-to-string (rest sexp) (+ x ONE) prevlev))]))
;_______________________________________________________________________________

;TEST CASES:
(begin-for-test
  (check-equal? (nested-to-flat VALID-INPUT1)
                OUTPUT1
                "Inccorect output. Output should have been OUTPUT1"))