;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname balls-in-box) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ())))
(require rackunit)
(require "extras.rkt")
(require rackunit/text-ui)
(require 2htdp/universe)
(require 2htdp/image)

;Balls in box
; is empty box of 400x300 where new balls can be created at the center of the
;screen by pressing the key "N" and once it has been created it can be dragged
;to any position on the screen by using the mouse. A unselcted ball will be
;outline green coloured one while the selcted one will be a solid green one.
;it also implements smooth dragging

; run with (run 0)

(provide run
         initial-world
         world-after-tick
         world-after-key-event
         world-after-mouse-event
         world-to-scene
         world-balls
         ball-x-pos
         ball-y-pos
         ball-selected?)

;_______________________________________________________________________________

; MAIN FUNCTION.

; run: Integer -> World
;   GIVEN: any value
;  EFFECT: ignores the given input and start a interactive program
; RETURNS: the final state of the world

(define (run x)
  (big-bang (initial-world x)
            (on-tick world-after-tick 0.25)
            (on-key world-after-key-event)
            (on-mouse world-after-mouse-event)
            (on-draw world-to-scene)))

;            
;_______________________________________________________________________________
; CONSTANTS

;CIRCLE CONSTANTS
(define CIRC-RAD 20)
(define SOLID-CIRC (circle CIRC-RAD "solid" "green"))
(define OUTLINE-CIRC (circle CIRC-RAD "outline" "green"))


; CANVAS DIMENTIONS 
(define CANVAS-WIDTH 400)
(define CANVAS-HEIGHT 300)
(define CANVAS-X-CENTER (/ CANVAS-WIDTH 2))
(define CANVAS-Y-CENTER (/ CANVAS-HEIGHT 2))
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))

;KeyStrokes
(define KEY-N "n")

;Mouse Events
(define MOUSE-CLICK "button-down")
(define MOUSE-RELEASE "button-up")
(define MOUSE-DRAG "drag")

;MISC
(define NO-BALLS 0)


;_______________________________________________________________________________
; DATA DEFINITIONS
(define-struct world (balls count m-xco m-yco))

; A World is a (make-world LOB NonNegInt Integer Integer)

; INTERPRETATION:
; LOB    List of ball
; count  Represents the total number of balls on the screen
; m-xco  Represents the x cooridinate of previous/current mouse click
; m-yco  Represents the y cooridinate of previous/current mouse click

; TEMPLATE: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; world-fn : World -> ?
; (define (world-fn w)
;  (..
;    (world-balls w)
;    (world-count w)
;    (world-mx w)
;    (world-my w))

;_______________________________________________________________________________

; A ListOf<Ball> (LOB) is one of
;  -- empty
;  -- (cons Ball LOB)
;
; INTERPRETATION:
; empty -- The list is empty
; (cons Ball LOB) -- List of Balls
;
; TEMPLATE:
; lob-fn : LOB -> ??
; (define (lob-fn balls)
;   (
;    [(empty? balls)...]
;    [(cons? balls)
;     (...
;      (first balls)
;      (balls-fn (rest balls)))]))

(define-struct ball(x-pos y-pos selected?))
; A Ball is a (make-ball Integer Integer Boolean)
; Interpretation:
; x-pos -> gives the x coordinate of the center of the ball
; y-pos -> gives the Y coordinate of the center of the ball
; selected? describes whether or not the ball is selected.

; TEMPLATE
; ball-fn : Ball -> ??
;(define (ball-fn c)
;  (... (ball-x-pos c) 
;       (ball-y-pos c) 
;       (ball-selected? c)))

;_______________________________________________________________________________

; A KeyEvent and is one of the below and its effects on the system
; -- "n"                     create a new ball

; A MouseEvent can be any of the following and its effetcs on the world are
;; give next to each of them. 

; INTERPRETATION:
; -- "button-down"   selects the cat if clicked on a cat
; -- "drag"          drags the cat if is selected already
; -- "button-up"     unselects the cat if it was seleted already by button down
; -- any other event Ignore

;_________________________________________________________________________  

;TEST CASE CONSTANTS
(define EMPTY-WORLD (make-world empty NO-BALLS 0 0))
(define 2-BALL (cons(make-ball 50 20 false) 
                    (cons (make-ball 70 90 false) empty)))

(define 1-BALL-CENTER (make-ball CANVAS-X-CENTER CANVAS-Y-CENTER false))

(define 2-BALL-SELECTED1 (cons(make-ball 50 20 true) 
                    (cons (make-ball 70 90 false) empty)))

(define 2-BALL-DRAGGED (cons (make-ball 200 145 true) 
                    (cons (make-ball 70 90 false) empty)))

(define WORLD0 (make-world empty 0 0 0))
(define WORLD1 (make-world 2-BALL 2 0 0))
(define WORLD2 (make-world (cons 1-BALL-CENTER empty) 1 0 0))
(define WORLD1-AFT-CLICK-OUT-200 (make-world 2-BALL 2 200 200))
(define WORLD1-SELECTED (make-world 2-BALL-SELECTED1 2 50 25))
(define WORLD1-UNSELECTED (make-world 2-BALL 2 0 0))
(define WORLD1-SELECTED-AFT-DRAG (make-world 2-BALL-DRAGGED 2 200 150))


(define SCENE-WORLD0 (place-image (text "0" 20 "green")
                                         15 
                                         10
                                         EMPTY-CANVAS))
(define SCENE-WORLD1 
  (place-image OUTLINE-CIRC 50 20 
               (place-image OUTLINE-CIRC 70 90
                            (place-image (text "2" 20 "green")
                                         15 
                                         10 
                                         EMPTY-CANVAS))))

;_________________________________________________________________________ 
; initial-world : Any -> World
;   GIVEN: Any. Input is ignored
; RETURNS: a world with a empty screen with a display on the top left 
;           corner a number that denotes the number of ball in the screen

(define (initial-world x)
  EMPTY-WORLD)

; TEST CASES:
(begin-for-test 
  (check-equal? (initial-world 3)
                EMPTY-WORLD
                "Incorrect Value. Empty World should have been created"))
;_______________________________________________________________________________
; world-after-tick : World -> World
;    GIVEN: a world w
;  RETURNS: the world that should follow w after a tick.
; STRATEGY: Function composition
; EXAMPLES: (world-after-tick WORLD1)-> World

(define (world-after-tick w)
  w)

; TEST CASES:
(begin-for-test
  (check-equal? (world-after-tick WORLD1)
                WORLD1
                "Incorrect Value. Should have returned WORLD1"))

;_______________________________________________________________________________

; world-to-scene : World -> Scene
;    GIVEN: a world
;  RETURNS: a Scene that portrays the given world.
; EXAMPLES: (world-to-scene WORLD1) -> Scene 
; STRATEGY: Structural Decomposition w : World

(define (world-to-scene w)
  (if (= (world-count w) 0)
      (display-world-ball-count (world-count w))
      (create-world-with-balls (world-balls w) (world-count w))))

; TEST CASES:
(begin-for-test
  (check-equal? (world-to-scene WORLD1)
                SCENE-WORLD1
                "Incorrect Value. Should have returned SCENE-WORLD1")
  (check-equal? (world-to-scene WORLD0)
                SCENE-WORLD0
                "Incorrect Value. Should have returned SCENE-WORLD0"))

;_______________________________________________________________________________
; display-world-ball-count : Number -> Scene
;    GIVEN: the count of balls in the world
;  RETURNS: a Scene that with the number in the top left corner
; EXAMPLES: (display-world-ball-count 0) -> Scene 
; STRATEGY: Function Composition

(define (display-world-ball-count count)
  (place-image (text (number->string count) 20 "green")
               15 
               10
               EMPTY-CANVAS))

; TEST CASES;
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; create-world-with-balls: LOB -> Scene
;    GIVEN: LOB-> a list of ball
;  RETURNS: a Scene that with all the balls in the list on the scene and the 
;           count of balls in the top left corner
; EXAMPLES: (create-world-with-balls 2-BALL 2) -> Scene 
; STRATEGY: Function Composition

(define (create-world-with-balls lob count)
  (if (empty? lob)
      (display-world-ball-count count)
      (place-image (make-circles (first lob))
                   (get-x-co (first lob))
                   (get-y-co (first lob))
                   (create-world-with-balls (rest lob) count))))   

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; make-circles: Ball -> Circle
;    GIVEN: a ball
;  RETURNS: a solid circle if the ball is selected or else a outlined green ball
; EXAMPLES: (make-circles (make-ball 50 50 false) -> OUTLINE-CIRC 
;           (make-circles (make-ball 100 50 true) -> SOLID-CIRC 
; STRATEGY: Structural Decomposition ball1 : Ball
  
(define (make-circles ball1)
  (if (ball-selected? ball1)
      SOLID-CIRC 
      OUTLINE-CIRC ))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; get-x-co: Ball -> Number
;    GIVEN: a ball
;  RETURNS: the x co-ordinate of the ball


(define (get-x-co ball1)
  (ball-x-pos ball1))

;_______________________________________________________________________________
; get-y-co Ball -> Number
;    GIVEN: a ball
;  RETURNS: the y co-ordinate of the ball

(define (get-y-co ball1)
  (ball-y-pos ball1))

;_______________________________________________________________________________
; world-after-key-event : World KeyEvent -> World
;    GIVEN: a world w
;  RETURNS: the world that should follow the given world
;           after the given key event.
;           on space, toggle paused?-- ignore all others
; EXAMPLES: see tests below
; STRATEGY: Cases 

(define (world-after-key-event w kev)
  (cond [(key=? kev KEY-N) (create-new-circle w)]
        [else w]))

; TEST CASES:
(begin-for-test
  (check-equal? (world-after-key-event WORLD1 " ")
                WORLD1
                "Incorrect value. World should be unchanged")
  (check-equal? (world-after-key-event WORLD0 "n")
                WORLD2
                "Incorrect value. should be WORLD2"))
   
;_______________________________________________________________________________
; create-new-circle : World -> World
;    GIVEN: a world w
;  RETURNS: the world with a new circle created at the center 
; EXAMPLES: (create-new-circle WORLD0) -> WORLD2
; STRATEGY: Structural Decomposition on w : World

(define (create-new-circle w)
  (make-world (add-circle-in-center (world-balls w)) 
              (+ (world-count w) 1) 
              (world-m-xco w) 
              (world-m-yco w)))
; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; add-circle-in-center: LOB -> LOB
;    GIVEN: a list of balls
;  RETURNS: list of balls with a new ball created at the center 
; EXAMPLES: (add-circle-in-center empty) -> (cons 1-BALL-CENTER empty)
; STRATEGY: Function Composition

(define (add-circle-in-center lob)
  (list* (make-ball CANVAS-X-CENTER CANVAS-Y-CENTER false) lob))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; world-after-mouse-event : World Integer Integer MouseEvent -> World
;    GIVEN: a world, mouse co-ordinates and a description of a mouse event
;  RETURNS: the world that should follow the given mouse event
; EXAMPLES: Refer test cases
; STRATEGY: Cases on MouseEvents

(define (world-after-mouse-event w mx my mev)
  (cond
    [(mouse=? mev MOUSE-CLICK)   (circles-after-click w mx my)]
    [(mouse=? mev MOUSE-DRAG)    (circles-after-drag w mx my)]
    [(mouse=? mev MOUSE-RELEASE) (circles-after-release w mx my)]
    [else w]))

; TEST CASES
(begin-for-test
  ;button-down
  (check-equal? (world-after-mouse-event WORLD1 50 25 MOUSE-CLICK)
                WORLD1-SELECTED
                "World After Mouse Event Test: the world with one ball 
                selected is not done properly")

  (check-equal? (world-after-mouse-event WORLD1 200 200 MOUSE-CLICK)
                WORLD1-AFT-CLICK-OUT-200   
                "World should not have changed")
  
  (check-equal? (world-after-mouse-event EMPTY-WORLD 200 200 MOUSE-CLICK)
                EMPTY-WORLD   
                "World should not have changed") 
  ; drag event
  (check-equal? (world-after-mouse-event WORLD1-SELECTED 200 150 MOUSE-DRAG)
                WORLD1-SELECTED-AFT-DRAG 
                "World After Mouse Event Test: the world with one ball 
                dragged to new position is not done properly")
  
  (check-equal? (world-after-mouse-event EMPTY-WORLD 200 200 MOUSE-DRAG)
                EMPTY-WORLD   
                "World should not have changed") 

  ; other events
  (check-equal? (world-after-mouse-event WORLD1 20 30 "leave")
                WORLD1    
                "Ignore this mouse event")
 
  ; button-up event
  (check-equal? (world-after-mouse-event WORLD1-SELECTED 200 150 MOUSE-RELEASE)
                WORLD1-UNSELECTED    
                "World After Mouse Event Test: ball selection should 
                be released but it is not happening")
  
  (check-equal? (world-after-mouse-event WORLD1 50 100 MOUSE-RELEASE)
                WORLD1     
                "World After Mouse Event Test: mouse is not inside 
                the ball. so no change in world")
  
  (check-equal? (world-after-mouse-event EMPTY-WORLD 200 200 MOUSE-RELEASE)
                EMPTY-WORLD   
                "World should not have changed"))
;_______________________________________________________________________________
; circles-after-click : World Integer Integer -> World
;    GIVEN: a world and a description of a mouse event
;  RETURNS: the world that should follow the given mouse event
; EXAMPLES: (circles-after-click WORLD1 50 25 MOUSE-CLICK) -> WORLD1-SELECTED
; STRATEGY: Structural Decomposition on w : World

(define (circles-after-click w mx my)
  (if (empty? (world-balls w))
      w
      (make-world 
       (circles-after-click-helper (world-balls w) mx my)
       (world-count w)
       mx
       my)))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; circles-after-click-helper: LOB Integer Integer -> LOB
;    GIVEN: a list of ball and coordinates of mouse event
;  RETURNS: the list of ball with baal selected if click is made within any of
;           the balls else returns the world as it is
; EXAMPLES: (circles-after-click-helper 2-BALL 50 25 MOUSE-CLICK)
;                                                           -> WORLD1-SELECTED
; STRATEGY: Functional Composition

(define (circles-after-click-helper lob mx my)
  (list* (circle-after-click (first lob) mx my)
         (if (empty? (rest lob)) 
             empty
             (circles-after-click-helper (rest lob) mx my))))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; circles-after-click-helper: Ball Integer Integer -> Ball
;    GIVEN: a ball and coordinates of mouse event
;  RETURNS: the ball after mouse click
; EXAMPLES: (circle-after-click (make-ball 50 20 false) 50 25 MOUSE-CLICK)
;                                                    -> (make-ball 50 20 true)
; STRATEGY: Structural Decomposition on ball1 : Ball


(define (circle-after-click ball1 mx my)
  (if (is-mouse-over-ball (ball-x-pos ball1)
                          (ball-y-pos ball1)
                          mx my)
      (make-ball (ball-x-pos ball1) (ball-y-pos ball1) true)
      ball1))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; circles-after-click-helper: Ball Integer Integer -> Ball
;    GIVEN: a ball and coordinates of mouse event
;  RETURNS: true if the click is made inside the ball else returns false
; EXAMPLES: (is-mouse-over-ball 50 20 50 25) -> true
; STRATEGY: Function Composition

(define (is-mouse-over-ball b-xpos b-ypos mx my)
  (<= (sqrt(+ (sqr (- b-xpos mx)) 
              (sqr (- b-ypos my)))) 
      CIRC-RAD))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; circles-after-release World Integer Integer -> World
;    GIVEN: a world and the coordinate of mouse release
;  RETURNS: the world that should follow the given mouse event
; EXAMPLES: (circles-after-release WORLD1-SELECTED 50 25 MOUSE-RELEASE) 
;                                                           -> WORLD1-UNSELECTED
; STRATEGY: Function Composition

(define (circles-after-release w mx my)
  (if (empty? (world-balls w))
      w
      (make-world 
       (circles-after-release-helper (world-balls w))
       (world-count w)
       0
       0)))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; circles-after-release LOB -> LOB
;    GIVEN: List of balls
;  RETURNS: List of balls after unselecting all balls
; EXAMPLES: (circles-after-release-helper 2-BALL-SELECTED1) -> 2-BALL
; STRATEGY: Function Composition

(define (circles-after-release-helper lob)
  (list* (circle-after-release (first lob))
         (if (empty? (rest lob)) 
             empty
             (circles-after-release-helper (rest lob)))))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; circle-after-release Ball -> Ball
;    GIVEN: List of balls
;  RETURNS: List of balls after unselecting all balls
; EXAMPLES: (circle-after-release (make-ball 20 20 true) 
;                                                     -> (make-ball 20 20 false)
; STRATEGY: Structural Decomposition ball1 : Ball

(define (circle-after-release ball1)
  (if (ball-selected? ball1)
      (make-ball (ball-x-pos ball1) (ball-y-pos ball1) false)
      ball1))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; circles-after-drag World Integer Integer -> World
;    GIVEN: a world and the coordinate of mouse drag
;  RETURNS: the world that should follow the given mouse event
; EXAMPLES: (world-after-mouse-event WORLD1-SELECTED 200 150 MOUSE-DRAG)
;                                  -> WORLD1-SELECTED-AFT-DRAG 
; STRATEGY: Structural Decomposition on w : World

(define (circles-after-drag w mx my)
  (if (empty? (world-balls w))
      w
      (make-world (circles-after-drag-helper (world-balls w)
                                             (world-m-xco w)
                                             (world-m-yco w)
                                              mx my)
                  (world-count w)
                  mx
                  my)))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; circles-after-drag-helper: LOB Integer Integer Integer Integer -> LOB
;    GIVEN: list of balls,the coordinate of previous mouse event &
;           current drag event
;  RETURNS: the list of balls after dragging selected balls
; EXAMPLES: (circles-after-drag-helper 2-BALL-SELECTED1 50 25 200 150)
;                                  -> 2-BALL-DRAGGED 
; STRATEGY: Function Composition


(define (circles-after-drag-helper lob wm-xco wm-yco mx my)
  (list* (circle-after-drag (first lob) wm-xco wm-yco mx my)
         (if (empty? (rest lob))
             empty
             (circles-after-drag-helper (rest lob) wm-xco wm-yco mx my))))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; circle-after-drag Ball Integer Integer Integer Integer -> Ball
;    GIVEN: a ball, the coordinate of previous mouse event & current drag event
;  RETURNS: the ball moved to the new position if it is selected
; EXAMPLES: (circle-after-drag (make-ball 50 20 true) 50 25 200 150)
;                                  -> (make-ball 200 145 true) 
; STRATEGY: Structural Decomposition on ball1: Ball

(define (circle-after-drag ball1 wm-xco wm-yco mx my)
  (if (ball-selected? ball1)
      (make-ball (ball-new-x (ball-x-pos ball1) wm-xco mx)
                 (ball-new-y (ball-y-pos ball1) wm-yco my)
                 true)
      ball1))


; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; ball-new-x Integer Integer Integer -> Ball
;    GIVEN: the x coordinate of the ball, previos mouse event, new drag location
;  RETURNS: the new x coordinate of the ball
; EXAMPLES: (ball-new-x 50 50 200) -> 200                               
; STRATEGY: Function Composition

(define (ball-new-x bxco wm-xco mx)
  (+ bxco (- mx wm-xco)))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; ball-new-y Integer Integer Integer -> Ball
;    GIVEN: the y coordinate of the ball, previos mouse event, new drag location
;  RETURNS: the new y coordinate of the ball
; EXAMPLES: (ball-new-y 20 25 150) -> 145                               
; STRATEGY: Function Composition
      
(define (ball-new-y byco wm-yco my)
  (+ byco (- my wm-yco)))

; TESTCASES:
; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________