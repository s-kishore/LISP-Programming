;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname snacks) (read-case-sensitive #t) (teachpacks ((lib "image.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ((lib "image.rkt" "teachpack" "2htdp")))))
(require rackunit)
(require "extras.rkt")

(provide 
  initial-machine 
  machine-next-state
  machine-chocolates 
  machine-carrots
  machine-bank)

; A snack vending machine has chocolate bars & carrot sticks.
; Chocolate bar cost $1.75 and carrot sticks cost $0.70. If the customer 
; deposits enough money and if the machine is not out of the selected item,it 
; will dispense the selcted item. The customer at anytime before choosing a item
; may press the release button to return the money. The machine has the 
; container called bank that collects all the money. 

;DATA DEFINITION:

(define-struct machine (choco carrot bnk custcash))

;A machine is a (make-machine choco carrot bnk custcash)
;INTERPRETATION:
;   choco  - Indicates the number of chocolates the machine has in stock
;   carrot - Indicates the number of carrot the machine has in stock
;   bank   - Indicates the amount of money in the machine after selling of 
;            items stock
; custcash - Indicates the amount of cash in cents the customer had put into 
;            the machine
;TEMPLATE
; (define machine-fn m)
;   (...
;      (machine-choco m)
;      (machine-carrot m)
;      (machine-bnk m)
;      (machine-custcash m))
;____________________________________________________________________________
;A CustomerInput is one of
;  PosInt           interp: insert the specified number of cents
; "chocolate"       interp: request a chocolate bar
; "carrots"         interp: request a package of carrot sticks
; "release"         interp: return all the coins that the customer has put in.
;
;____________________________________________________________________________
;____________________________________________________________________________
;add-cash : Machine CustomerInput -> Machine
;  GIVEN: a machine state and a customer input
;RETURNS: the state of the machine with customer's cash accepted.
  
;EXAMPLES: 
; (add-cash (initial-machine 10 35) 20)=> (make-machine 10 35 0 20)
; (add-cash (initial-machine 10 15) 200)=> (make-machine 10 15 0 200)
  
;STRATEGY: Structural De-Composition on mach:machine

(define (add-cash mach cinpt)
  (make-machine (machine-choco mach) (machine-carrot mach) 
                (machine-bnk mach) (+ (machine-custcash mach) cinpt)))

;TEST CASES:

;____________________________________________________________________________
;dispence-choco : Machine -> Machine
;  GIVEN: a machine state
;RETURNS: the new state of the machine after dispencing 1 chocolate & returning
;         the change to the user
  
;EXAMPLES: 
; (dispense-choco (machine-next-state 
;                    (initial-machine 10 35) 20))=> (make-machine 10 35 0 20)
; (dispense-choco (machine-next-state 
;                    (initial-machine 10 15) 200)=> (make-machine 9 15 175 0)

;STRATEGY: Structural De-Composition on mach:machine

(define (dispense-choco mach)
  (if (> (machine-choco mach) 0) 
      (make-machine (- (machine-choco mach) 1) (machine-carrot mach) 
                (+ (machine-bnk mach) 175) 0)
      mach
      ))

;TEST CASES:

;____________________________________________________________________________
;dispence-carrot : Machine -> Machine
;  GIVEN: a machine state
;RETURNS: the new state of the machine after dispencing 1 package of carrot & 
;         returning the change to the user
  
;EXAMPLES: 
; (dispense-carrot (machine-next-state 
;                    (initial-machine 10 35) 20))=> (make-machine 10 35 0 20)
; (dispense-carrot (machine-next-state 
;                    (initial-machine 10 15) 200)=> (make-machine 9 15 70 0)

;STRATEGY: Structural De-Composition on mach:machine  

(define (dispense-carrot mach)
  (if (> (machine-carrot mach) 0) 
      (make-machine (machine-choco mach) (- (machine-carrot mach) 1)  
                (+ (machine-bnk mach) 70) 0)
      mach
      ))

;TEST CASES:

;____________________________________________________________________________
;dispence-cash : Machine -> Machine
;  GIVEN: a machine state
;RETURNS: the new state of the machine after returning the cash to the user
  
;EXAMPLES: 
; (dispense-cash (machine-next-state 
;                    (initial-machine 10 35) 20))=> (make-machine 10 35 0 0)
; (dispense-cash (machine-next-state 
;                    (initial-machine 10 15) 200)=> (make-machine 10 15 0 0)

;STRATEGY: Structural De-Composition on mach:machine 


(define (dispense-cash mach)
(make-machine (machine-choco mach) (machine-carrot mach)  
              (machine-bnk mach) 0))

;TEST CASES:


;initial-machine : NonNegInt NonNegInt-> Machine
; GIVEN:  the number of chocolate bars and the number of packages of
;         carrot sticks
;RETURNS: a machine loaded with the given number of chocolate bars and
;         carrot sticks, with an empty bank.
;EXAMPLES: 
;  (initial-machine 10 10)=> (make-machine 10 10 0 0)
;  (initial-machine 10 35)=> (make-machine 10 35 0 0)
   
;STRATEGY: Function Composition
   
(define (initial-machine chc car)
  (make-machine chc car 0 0))
;____________________________________________________________________________
;
;machine-next-state : Machine CustomerInput -> Machine
;  GIVEN: a machine state and a customer input
;RETURNS: the state of the machine that should follow the customer's
;         input
;EXAMPLES: 
;  (machine-next-state (initial-machine 10 35) 20)=> (make-machine 10 35 0 20)
;  (machine-next-state (machine-next-state 
;                        (initial-machine 10 35) 
;                         20)
;                        "chocolate")=> (make-machine 9 35 175 0)
;STRATEGY: Cases


(define (machine-next-state mach cinpt)
  (cond [(integer? cinpt) (add-cash mach cinpt)]
        [(and (string=? cinpt "chocolate") (>= (machine-custcash mach) 175))
              (dispense-choco mach)]
        
        [(and (string=? cinpt "carrots") (>= (machine-custcash mach) 70))
              (dispense-carrot mach)]
        
        [(and (string=? cinpt "release") (>= (machine-custcash mach) 1))
              (dispense-cash mach)]
        
        [else mach]))
;____________________________________________________________________________
;machine-chocolates: Machine -> Number
;  GIVEN: a machine state
;RETURNS: the number of chocolate sticks available in the machine.
  
;EXAMPLES: 
; (machine-chocolates (initial-machine 10 35))=> 10
; (machine-chocolates (machine-next-state 
;                    (initial-machine 20 15) 200)=> 25

;STRATEGY: Structural De-Composition on mach:machine 


(define (machine-chocolates mach)
  (machine-choco mach))

;____________________________________________________________________________
;machine-carrots: Machine -> Number
;  GIVEN: a machine state
;RETURNS: the number of carrots packs available in the machine.
  
;EXAMPLES: 
; (machine-carrots (initial-machine 10 35))=> 35
; (machine-carrots (machine-next-state 
;                    (initial-machine 20 15) 200)=> 15

;STRATEGY: Structural De-Composition on mach:machine 


(define (machine-carrots mach)
  (machine-carrot mach))

;____________________________________________________________________________
;machine-carrots: Machine -> Number
;  GIVEN: a machine state
;RETURNS: the number of carrots packs available in the machine.
  
;EXAMPLES: 
; (machine-bank (initial-machine 10 35))=> 0
; (machine-bank (machine-next-state 
;                    (machine-next-state 
;                      (initial-machine 20 15) 200) "chocolate") => 175

;STRATEGY: Structural De-Composition on mach:machine 

(define (machine-bank mach)
  (machine-bnk mach))

;TEST CASES:

;Test cases
  (check-equal? (machine-next-state(make-machine 0 0 50 900) "chocolate")
                (make-machine 0 0 50 900)
                "Incorrect output")

  (check-equal? (machine-next-state(make-machine 10 0 50 900) "release")
                (make-machine 10 0 50 0)
                "Incorrect output")
    
  (check-equal? (machine-next-state(make-machine 10 10 50 900) "carrots")
                (make-machine 10 9 120 0)
                "Incorrect output")
      
  (check-equal? (machine-next-state(make-machine 10 9 50 900) "chocolate")
                (make-machine 9 9 225 0)
                "Incorrect output")
  (check-equal? (machine-next-state(make-machine 10 9 50 10) 10 )
                (make-machine 10 9 50 20)
                "Incorrect output")
  (check-equal? (machine-chocolates (make-machine 10 9 50 10)) 10
                "Incorrect output")
  (check-equal? (machine-carrots (make-machine 10 9 50 10)) 9
                "Incorrect output")
  (check-equal? (machine-bank (make-machine 10 9 50 10)) 50
                "Incorrect output")
