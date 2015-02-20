;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname regexp) (read-case-sensitive #t) (teachpacks ((lib "image.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ((lib "image.rkt" "teachpack" "2htdp")))))
(require "extras.rkt")
(require 2htdp/universe)
(require rackunit)
(provide 
       initial-state
       next-state
       accepting-state?
       error-state?)
       
;The final state machine (FSM) takes input & traverse through the states if the 
; given inputs follow the pattern (a | b)* (c | d)* e
;___________________________________________________________________________
;DATA DEFINITION:
; STATE can be 
; F1- Initial state    Interpretation: Intial state of the FSM
; F2- second state     Interpretation: State after initial state on (a|b)* input
; F3- third state      Interpretation: State after F2 on (c|d)* input
; F4- Accepting state  Interpretation: State after F3 on "e" input
; ER- error state      Interpretation: State in which FSM is on any illegal 
;                                      input
; state-fn : State -> ?? 
; (define (state-fn state) 
;     (cond   [(string=? state F0) ...] 
;             [(string=? state F1) ...] 
;             [(string=? state F2) ...] 
;             [(string=? state F3) ...]))
;____________________________________________________________________________
; A key-event represents keyboard activity.
; KeyEvent : string?
;  "a"  stands for the a key;
;  "b"  stands for the b key;
;  "c"  stands for the c key;
;  "d " stands for the d key;
;  "\t" stands for the tab key (#\tab); 
;  "\b" stands for the backspace key (#\backspace).
;  "\u007F" stands for delete key
;____________________________________________________________________________
; initital-state Number -> string
; GIVEN:  a number
; RETURN: a FSM in initial state
; EXAMPLE: 
;      (initial-state 10) => "F0"
;      (initial-state 45) => "F0"
;; STRATEGY: Functional composition

(define (initial-state x)
  "F0")

;TEST CASES:
    (check-equal? (initial-state 5) "F0"
              "Incorrect state. Should be F0")
    
    (check-equal? (initial-state 8) "F0"
              "Incorrect state. Should be F0")
;____________________________________________________________________________
; next-state string string -> string
; GIVEN:  current state of the FSM
; RETURN: state of the FSM after accepting input
; EXAMPLE: 
;      (next-state "F0" "a") => "F1"
;      (next-state "F1" "a") => "F1"

;; STRATEGY: Functional composition

(define (next-state fsm inpt)
  (if (> (string-length inpt) 1)
      fsm
      (cond [(and (or (string=? fsm "F0") (string=? fsm "F1")) 
                  (or (key=? "a" inpt) (key=? "b" inpt))) 
            "F1"]
            [(and (or (string=? fsm "F1") (string=? fsm "F2"))
                  (or (key=? "c" inpt) (key=? "d" inpt))) 
            "F2"]
            [(and (string=? fsm "F2") (key=? "e" inpt)) 
            "F3"]
            [ else "ER"])))

;TEST CASES:
    (check-equal? (next-state (next-state (initial-state 5) "a") "a") "F1"
          "Incorrect state. Should be F1")
    (check-equal? (next-state (next-state (initial-state 5) "a") "b") "F1"
          "Incorrect state. Should be F2")
    (check-equal? (next-state (next-state (next-state (next-state
                                           (initial-state 5) 
                                           "a") "b") "c") "e") "F3"
          "Incorrect state. Should be F3")
    (check-equal? (next-state (initial-state 5) "m") "ER"
          "Incorrect state. Should be ER")
;____________________________________________________________________________
; state-state? String -> Boolean
; GIVEN: current state of the FSM
; RETURN: True if FSM is in Accepting state or else false
; EXAMPLE: 
;      (accepting-state? (initial-state 3)) => false
;      (accepting-state? (next-state (initial-state 3) "a") => false

;; STRATEGY: Functional composition

(define (accepting-state? fsm)
  (if (string=? fsm "F3")
      "true"
      "false"))

;TEST CASES:
    (check-equal? (accepting-state? 
                   (next-state (next-state (initial-state 5) "a") "b")) "false"
          "Incorrect value. Should be false")
    
    (check-equal? (accepting-state? 
                   (next-state (next-state (next-state (next-state
                                           (initial-state 5)
                                           "a") "b") "c") "e")) "true"
          "Incorrect value. Should be true")   
    
;____________________________________________________________________________
; error-state? String -> Boolean
; GIVEN: current state of the FSM
; RETURN: True if FSM is in error state or else false
; EXAMPLE: 
;      (error-state (next-state (next-state 
;                                 (next-state (next-state mac "b") "c")
;                                                             "e") "m"))=> true
;      (error-state? (next-state (next-state mac "b") "c")) => false

;; STRATEGY: Functional composition


(define (error-state? fsm)
  (if (string=? fsm "ER")
      "true"
      "false"))

;TEST CASES:
(check-equal? (error-state? (next-state (next-state (next-state (next-state
                                           (initial-state 5)
                                           "a") "b") "c") "f")) "true"
          "Incorrect value. Should be true")   
(check-equal? (error-state? (next-state (next-state (next-state (next-state
                                           (initial-state 5)
                                           "a") "b") "c") "e")) "false"
          "Incorrect value. Should be false")  