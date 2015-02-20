;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname robot) (read-case-sensitive #t) (teachpacks ((lib "image.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ((lib "image.rkt" "teachpack" "2htdp")))))
(require "extras.rkt")
(require rackunit)

(provide
  initial-robot
  robot-left 
  robot-right
  robot-forward
  robot-north? 
  robot-south? 
  robot-east? 
  robot-west?) 

;DATA DEFINITIONS
(define-struct robot (xc yc hd io))

;Robot represents (make-robot Number Number String)
;It represents the current position of the robot, its heading direction and also
;wheather it is inisde the given 200x400 room
;INTERPRETATION
;xc - x co-oridinate of the robot
;yc - y co-oridinate of the robot
;hd - represents the heading direction of the robot
;io - represents weather the robot is inisde or outside the room 


;TEMPLATE
;robot-fn: Robot-> ??
;(define (robot-fn robo)
;(... (robot-xc robo)
;     (robot-yc robo)
;     (robot-hd robo)
;     (robot-io robo))

;____________________________________________________________________________
;initial-robot : Real Real-> Robot
;GIVEN:   a set of (x,y) coordinates
;RETURNS: a robot with its center at those coordinates, facing north(up).
;Examples: 
; (initial-robot 10 10) => (make-robot 10 10 #\N #\O)
; (initial-robot 10 10) => (make-robot 20 20 #\N #\I)
; (initial-robot -200 10) => (make-robot -200 10 #\N #\O)
;STRATEGY: Function Composition
  
(define (initial-robot x y)
 
  (make-robot x y #\N (call-in-out x y))

)

;____________________________________________________________________________
                     
;call-in-out : Real Real-> Character
;GIVEN:   a set of (x,y) coordinates
;RETURNS: a character that represents wheather the robot is present inisde 
;         or outside the room.
;Examples: 
; (call-in-out 10 10) => #\O
; (call-in-out 20 20) => #\I

;STRATEGY: Function Composition
                     
(define (call-in-out x y)
  (cond [ (and (and (>= x 15) (<= x 185)) 
               (and (>= y 15) (<= y 385))) #\I ]

       [ else #\O ]))

;TEST CASE
    
  (check-equal? (initial-robot 15 15) (make-robot 15 15 #\N #\I)
              "Incorrect value . Should be (make-robot 15 15 N I)")
    (check-equal? (initial-robot 15 5) (make-robot 15 5 #\N #\O)
              "Incorrect value . Should be (make-robot 15 5 N O)")
;_____________________________________________________________________________
    
;robot-left : Robot -> Robot
;GIVEN: a robot
;RETURNS: a robot like the original, but turned 90 degrees left.

;EXAMPLES:
; (robot-left (initial-robot 15 15)) => (make-robot 15 15 #\W #\I)
; (robot-left (robot-left (initial-robot 15 15))) => (make-robot 15 15 #\S #\I)
    
;STRATEGY: Structural De-Composition on rr:robot

(define (robot-left rr)
   (make-robot(robot-xc rr) 
              (robot-yc rr)
              (cond [(char-ci=? (robot-hd rr) #\N) #\W]
                    [(char-ci=? (robot-hd rr) #\W) #\S]
                    [(char-ci=? (robot-hd rr) #\S) #\E]
                    [(char-ci=? (robot-hd rr) #\E) #\N])
              (robot-io rr)))

;TEST CASES:
    (check-equal? (robot-left (make-robot 28 18 #\E #\I))
                  (make-robot 28 18 #\N #\I) 
                  "Robot has not turned to its left")   
    (check-equal? (robot-left (make-robot 28 18 #\N #\I))
                  (make-robot 28 18 #\W #\I) 
                  "Robot has not turned to its left")
    (check-equal? (robot-left (make-robot 28 18 #\S #\I))
                  (make-robot 28 18 #\E #\I) 
                  "Robot has not turned to its left")

;____________________________________________________________________________
     
;robot-right : Robot -> Robot
;GIVEN: a robot
;RETURNS: a robot like the original, but turned 90 degrees right.

;EXAMPLES:
; (robot-right (initial-robot 15 15)) => (make-robot 15 15 #\E #\I)
; (robot-right (robot-right (initial-robot 15 15)))=> (make-robot 15 15 #\S #\I)
    
;STRATEGY: Structural De-Composition on rr:robot

(define (robot-right rr)
   (make-robot(robot-xc rr) 
              (robot-yc rr) 
              (cond [(char-ci=? (robot-hd rr) #\N) #\E]
                    [(char-ci=? (robot-hd rr) #\E) #\S]
                    [(char-ci=? (robot-hd rr) #\S) #\W]
                    [(char-ci=? (robot-hd rr) #\W) #\N])
              (robot-io rr)))

;TEST CASE:
     (check-equal? (robot-right (make-robot 28 18 #\E #\I))
                  (make-robot 28 18 #\S #\I) 
                  "Robot has not turned to its left")   
    (check-equal? (robot-right (make-robot 28 18 #\N #\I))
                  (make-robot 28 18 #\E #\I) 
                  "Robot has not turned to its left")
    (check-equal? (robot-right (make-robot 28 18 #\S #\I))
                  (make-robot 28 18 #\W #\I) 
                  "Robot has not turned to its left")
    (check-equal? (robot-right (make-robot 28 18 #\W #\I))
                  (make-robot 28 18 #\N #\I) 
                  "Robot has not turned to its left")
;____________________________________________________________________________
       
;robot-north? : Robot -> Boolean
;GIVEN: a robot
;RETURNS: True if the robot is faceing North else false.

;EXAMPLES:
; (robot-north (initial-robot 15 15)) => true
; (robot-north (robot-right (initial-robot 15 15)))=> false
    
;STRATEGY: Structural decomposition on rr:robot


(define (robot-north? rr)
  (if (char-ci=? (robot-hd rr) #\N)
      "true" 
      "false"))

;TEST CASE:
         (check-equal? (robot-north? (initial-robot 15 15))  "true"
              "Incorrect value . Should be true")
         (check-equal? (robot-north? (robot-left (initial-robot 15 15))) "false"
              "Incorrect value . Should be false")
;_____________________________________________________________________________

;robot-south? : Robot -> Boolean
;GIVEN: a robot
;RETURNS: True if the robot is facing south else false.

;EXAMPLES:
; (robot-south (initial-robot 15 15)) => false
; (robot-south (robot-right (robot-right (initial-robot 15 15))))=> true
    
;STRATEGY: Structural decomposition on rr:robot

(define (robot-south? rr)
  (if (char-ci=? (robot-hd rr) #\S)
      "true" 
      "false"))

;TEST CASE:
  (check-equal? (robot-south? (initial-robot 15 15))  "false"
       "Incorrect value . Should be false")
  (check-equal? (robot-south? (robot-left (robot-left 
                                          (initial-robot 15 15)))) "true"
       "Incorrect value . Should be true")

;____________________________________________________________________________
       
;robot-west? : Robot -> Boolean
;GIVEN: a robot
;RETURNS: True if the robot is facing west else false.

;EXAMPLES:
; (robot-west (initial-robot 15 15)) => false
; (robot-west (robot-right (initial-robot 15 15)))=> true
    
;STRATEGY: Structural decomposition on rr:robot
       
       
(define (robot-west? rr)
  (if (char-ci=? (robot-hd rr) #\W)
      "true" 
      "false"))

;TEST CASE:
  (check-equal? (robot-west? (initial-robot 15 15))  "false"
       "Incorrect value . Should be false")
  (check-equal? (robot-west? (robot-left (initial-robot 15 15))) "true"
       "Incorrect value . Should be true")  


;_____________________________________________________________________________

;robot-east? : Robot -> Boolean
;GIVEN: a robot
;RETURNS: True if the robot is facing east else false.

;EXAMPLES:
; (robot-east (initial-robot 15 15)) => false
; (robot-east (robot-left (initial-robot 15 15)))=> true
    
;STRATEGY: Structural decomposition on rr:robot


(define (robot-east? rr)
  (if (char-ci=? (robot-hd rr) #\E)
      "true" 
      "false"))

;TEST CASES:
    (check-equal? (robot-east? (initial-robot 15 15))  "false"
       "Incorrect value . Should be false")
   (check-equal? (robot-east? (robot-right (initial-robot 15 15))) "true"
       "Incorrect value . Should be true")    

;____________________________________________________________________________

;robot-forward : Robot PosInt -> Robot
;GIVEN: a robot and a distance
;RETURNS: a robot like the given one, but moved forward by the  specified number
;         of pixels distance. If moving forward the specified number of pixels
;         distance would cause the robot to move from being entirely inside the 
;         canvas room to being even partially outside the canvas room, then the 
;         robot should stop at the wall.

;EXAMPLES: 
;  (robot-forward (initial-robot 15 30) 10) => (make-robot 15 20 #\N #\I) 
;  (robot-forward (robot-right 
;                   (initial-robot 30 30) 10)) => (make-robot 40 30 #\N #\I)

;STRATEGY: Structural decomposition rr:robot #########


(define (robot-forward rr dist)
  (if (char-ci=? (robot-io rr) #\I)
        (make-robot (calc-xc (robot-xc rr) (robot-hd rr) dist #\I) 
                    (calc-yc (robot-yc rr) (robot-hd rr) dist #\I) 
                    (robot-hd rr)
                    (robot-io rr))
        (if (char-ci=? (calc-new-io (robot-xc rr) 
                                    (robot-yc rr) 
                                    (robot-hd rr) dist) #\I)
            
            (make-robot (calc-xc (robot-xc rr) (robot-hd rr) dist #\I) 
                        (calc-yc (robot-yc rr) (robot-hd rr) dist #\I) 
                        (robot-hd rr)
                        #\I)
            (make-robot (calc-xc (robot-xc rr) (robot-hd rr) dist #\O) 
                        (calc-yc (robot-yc rr) (robot-hd rr) dist #\O) 
                        (robot-hd rr)
                        #\O))))
;____________________________________________________________________________

;calc-new-io : Number Number Character Number -> Char
;GIVEN:   The x and y co-ordinates, heading direction and distance to be moved
;RETURNS: Character "I" if the robot will enter completely inside the room or 
;         else "O" 

;EXAMPLES: 
;  (calc-new-io 18 5 #\S 20)=> #\I) 
;  (calc-new-io 5 20 #\W 50)=> #\O)


;STRATEGY: Function Composition #########


(define (calc-new-io x y dir dist)
  (cond [(char-ci=? dir #\E)
         (if (and (>= y 15) (<= y 385) (>= (+ x dist) 15))
             #\I
             #\O)
         ]
        [(char-ci=? dir #\W)
         (if (and (>= y 15) (<= y 385) (>= (- x dist) 185))
             #\I
             #\O)
         ]
        [(char-ci=? dir #\N)
         (if (and (>= x 15) (<= x 185) (<= (- y dist) 385))
             #\I
             #\O)
         ]
        [(char-ci=? dir #\S)
         (if (and (>= x 15) (<= x 185) (>= (+ y dist) 15))
             #\I
             #\O)
         ]))            
;___________________________________________________________________________
            
;calc-xc : Number Number Number Character -> Number
;GIVEN:   The x co-ordinates, heading direction, distance to be moved, weather
;         the robot is inside the room or outside
;RETURNS: New x-Cordinate after moving by the given distance if it is moving
;            in a direction where x should either increase or decrease
         

;EXAMPLES: 
;  (calc-xc 18 10 #\N #\I)=> 18 
;  (calc-xc 18 100 #\E #\I)=> 118 


;STRATEGY: Function Composition 


(define (calc-xc xco dir dist io)
  (cond [ (char-ci=? dir #\E)
          
          (if (char-ci=? io #\O)
              (+ xco dist)
              (if (> (+ xco dist) 185)
                  185
                  (+ xco dist)))
        ]
        [ (char-ci=? dir #\W)
          (if (char-ci=? io #\O)
              (- xco dist)
              (if (< (- xco dist) 15)
                  15
                  (- xco dist)))
        ]
        [else xco]))

;TEST CASES:
(check-equal? (calc-xc 10 #\N 200 #\I) 10
              "incorrect x value. should be 10")
(check-equal? (calc-xc 10 #\E 200 #\I) 185
            "incorrect x value. should be 185")
;____________________________________________________________________________
            
;calc-yc : Number Number Number Character -> Number
;GIVEN:   The y co-ordinates, heading direction, distance to be moved, weather
;         the robot is inside the room or outside
;RETURNS: New Y-Cordinate after moving by the given distance if it is moving
;            in a direction where Y should either increase or decrease 

;EXAMPLES: 
;  (calc-yc 18 10 #\N #\I)=> 15 
;  (calc-yc 18 100 #\E #\I)=> 18


;STRATEGY: Function Composition #########

(define (calc-yc yco dir dist io)
  (cond [ (char-ci=? dir #\N)
          
          (if (char-ci=? io #\O)
              (- yco dist)
              (if (< (- yco dist) 15)
                  15
                  (- yco dist)))
        ]
        [ (char-ci=? dir #\S)
          (if (char-ci=? io #\O)
              (+ yco dist)
              (if (> (+ yco dist) 385)
                  385
                  (+ yco dist)))
        ]
        [else yco]))
        
;TEST CASES:
      (check-equal? (calc-yc 10 #\N 200 #\I) 15
              "incorrect x value. should be 10")
      (check-equal? (calc-yc 10 #\E 200 #\I) 10
              "incorrect x value. should be 185")
      (check-equal? (robot-forward (make-robot 40 220 #\S #\I) 60) 
              (make-robot 40 280 #\S #\I) 
           "Robot failed to move SOUTH eventhough it is fully inside the room")
     (check-equal? (robot-forward (make-robot 40 220 #\E #\I) 40) 
              (make-robot 80 220 #\E #\I) 
           "Robot failed to move SOUTH eventhough it is fully inside the room")