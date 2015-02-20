;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname two-bouncing-cats) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ())))
;; two bouncing cats.
;; Are two individual cats falling down from the top of the world. Once they
;; encounter any of the walls they bounce and start moving in the opposite 
;; direction. The world can be paused and unpause by hitting the space key.

;; The cats can also be selected using mouse clicks and dragged to any location
;; on the canvas but they are dragged outside of it the jump back to the
;; closest point in which they completely inside the canvas. Once either of the
;; cat is selected the direction in which it is moving can be changed using 
;; arrow keys. 

;; start with (main 0)

(require rackunit)
(require "extras.rkt")
(require rackunit/text-ui)
(require 2htdp/universe)
(require 2htdp/image)

(provide
 initial-world
 world-paused?
 world-cat1
 world-cat2
 cat-x-pos
 cat-y-pos
 cat-selected?
 cat-north?
 cat-south?
 cat-east?
 cat-west?
 world-after-tick
 world-after-mouse-event
 world-after-key-event)

;_______________________________________________________________________________

;; MAIN FUNCTION.

;; main : Integer -> World
;;   GIVEN: the initial y-position of the cats
;;  EFFECT: runs the simulation, starting with the cats falling
;; RETURNS: the final state of the world

(define (main initial-pos)
  (big-bang (initial-world initial-pos)
            (on-tick world-after-tick 0.5)
            (on-draw world-to-scene)
            (on-key world-after-key-event)
            (on-mouse world-after-mouse-event)))

;_______________________________________________________________________________

;; CONSTANTS

(define CAT-IMAGE (bitmap "cat.png"))

;; how fast the cat falls, in pixels/tick
(define CATSPEED 8)

;; dimensions of the canvas
(define CANVAS-WIDTH 450)
(define CANVAS-HEIGHT 400)
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))
(define CAT1-X-COORD (/ CANVAS-WIDTH 3))
(define CAT2-X-COORD (* 2 CAT1-X-COORD))

;; dimensions of the cat
(define HALF-CAT-WIDTH  (/ (image-width  CAT-IMAGE) 2))
(define HALF-CAT-HEIGHT (/ (image-height CAT-IMAGE) 2))

;; minimum and maximum co ordinates of the cats

(define CAT-MIN-X-CO HALF-CAT-WIDTH)
(define CAT-MIN-Y-CO HALF-CAT-HEIGHT)
(define CAT-MAX-X-CO (- CANVAS-WIDTH HALF-CAT-WIDTH)) 
(define CAT-MAX-Y-CO (- CANVAS-HEIGHT HALF-CAT-HEIGHT))

;_______________________________________________________________________________

;; DATA DEFINITIONS

(define-struct world (cat1 cat2 paused?))
;; A World is a (make-world Cat Cat Boolean)
;; cat1 and cat2 are the two cats
;; paused? describes whether or not the world is paused


;; template:
;; world-fn : World -> ??
;; (define (world-fn w)
;;   (... (world-cat1 w) (world-cat2 w) (world-paused? w)))


(define-struct cat (x-pos y-pos selected? dir))
;; A Cat is a (make-cat Integer Integer Boolean)
;; Interpretation: 
;; x-pos, y-pos give the position of the cat. 
;; selected? describes whether or not the cat is selected.
;; dir describes the direction in which the cat is moving
;; dir can be any of the following
;; #\N - denotes that the cat is moving north
;; #\S - denotes that the cat is moving south
;; #\E - denotes that the cat is moving east
;; #\W - denotes that the cat is moving west

;; TEMPLATES:

;; cat-fn : Cat -> ??
;;(define (cat-fn c)
;; (... (cat-x-pos c) (cat-y-pos c) (cat-selected? c)  (cat-dir c)))

;; dir-fn : Direction -> ??
;; (define (dir-fn dir)
;;  (cond
;;     [(char-ci=? dir #\N)...]
;;     [(char-ci=? dir #\S)...]
;;     [(char-ci=? dir #\E)...]
;;     [(char-ci=? dir #\W)...]))

;; A KeyEvent and is one of the below and its effects on the system
;; -- " "                     pause/unpause the world
;; -- "up"                    selected cat should move north
;; -- "down"                  selected cat should move south
;; -- "left"                  selected cat should move west
;; -- "right"                 selected cat should move east
;; -- any other KeyEvent      ignore

;; keyevent-fn : KeyEvent -> ??
;; (define (keyevent-fn kev)
;;   (cond
;;     [(key=? kev " ")...]
;;     [(key=? kev "up")...]
;;     [(key=? kev "down")...]
;;     [(key=? kev "left")...]
;;     [(key=? kev "right")...]
;;     [else...]))

;; A MouseEvent can be any of the following and its effetcs on the world are
;; give next to each of them. 

;; -- "button-down"   selects the cat if clicked on a cat
;; -- "drag"          drags the cat if is selected already
;; -- "button-up"     unselects the cat if it was seleted already by button down
;; -- any other event Ignore

;; mouseevent-fn : MouseEvent -> ??
;; (define (mouseevent-fn mev)
;;   (cond
;;     [(mouse=? mev "button-down")...]
;;     [(mouse=? mev "drag")...]
;;     [(mouse=? mev "button-up")...]
;;     [else...]))

;; examples of cats, for testing
(define selected-cat1-at-20 (make-cat CAT1-X-COORD 20 true #\S))
(define unselected-cat1-at-20 (make-cat CAT1-X-COORD 20 false #\S))

(define selected-cat1-at-28 (make-cat CAT1-X-COORD 28 true #\S))
(define unselected-cat1-at-28 (make-cat CAT1-X-COORD 28 false #\S))

(define selected-cat2-at-35 (make-cat CAT2-X-COORD 35 true #\S))
(define unselected-cat2-at-35 (make-cat CAT2-X-COORD 35 false #\S))

;; examples of worlds, for testing

(define paused-world-at-20
  (make-world
    unselected-cat1-at-20
    selected-cat2-at-35
    true))

(define unpaused-world-at-20
  (make-world
    unselected-cat1-at-20
    selected-cat2-at-35
    false))

;; in an unpaused world, the unselected cat falls, but the selected
;; cat stays pinned to the mouse.
(define unpaused-world-at-20-after-tick
  (make-world
    unselected-cat1-at-28
    selected-cat2-at-35
    false))
  

;; examples KeyEvents for testing
(define pause-key-event " ")
(define non-pause-key-event "q")   


;; example MouseEvents for testing:
(define button-down-event "button-down")
(define drag-event "drag")
(define button-up-event "button-up")

;;; END DATA DEFINITIONS

;_______________________________________________________________________________

;; world-after-tick : World -> World
;;    GIVEN: a world w
;;  RETURNS: the world that should follow w after a tick.
;; STRATEGY: structural decomposition on w : World

(define (world-after-tick w)
  (if (world-paused? w)
    w
    (make-world
      (cat-after-tick (world-cat1 w))
      (cat-after-tick (world-cat2 w))
      (world-paused? w))))


;; TEST CASES:
 
 (begin-for-test
  ;; checking world after tick for paused world
  (check-equal? (world-after-tick paused-world-at-20)
                paused-world-at-20
                "Incorrect value. World is paused")
  
  ;; checking world after tick for unpaused world
  (check-equal? (world-after-tick unpaused-world-at-20)
                (make-world (make-cat 150 28 false #\S) selected-cat2-at-35 
                            false)
                "Incorrect value. World is unpaused"))

;_______________________________________________________________________________

;; cat-after-tick : Cat -> Cat
;;    GIVEN: a cat c
;;  RETURNS: the state of the given cat after a tick if it were in an
;;           unpaused world.
;; EXAMPLES: refer test cases
;; STRATEGY: structural decomposition on c : Cat

(define (cat-after-tick c)
  (if (cat-selected? c)
      c
      (cat-after-tick-helper c)))

;; EXAMPLES: 
;; cat selected
;; (cat-after-tick selected-cat1-at-20) = selected-cat1-at-20
;; cat paused:
;; (cat-after-tick unselected-cat1-at-20) = unselected-cat-at-28

;; TEST CASES: tests follow help function.

;_______________________________________________________________________________

;; cat-after-tick-helper : Integer Integer Boolean -> Cat
;;    GIVEN: a position and a value for selected?
;;  RETURNS: the cat that should follow one in the given position in an
;;           unpaused world
;; EXAMPLES: refer test cases
;; STRATEGY: Structural Decomposition on c:Cat

(define (cat-after-tick-helper c)
  (if (has-cat-hit-wall c)
      (make-cat-bounce c)
      (calc-cat-next-pos (cat-x-pos c)
                         (cat-y-pos c)
                         (cat-selected? c)
                         (cat-dir c))))

;; tests:
(begin-for-test
  ;; cat selected
  (check-equal?
    (cat-after-tick selected-cat1-at-20)
    selected-cat1-at-20
    "selected cat shouldn't move")

  ;; cat unselected
  (check-equal? 
    (cat-after-tick unselected-cat1-at-20)
    unselected-cat1-at-28
    "unselected cat should fall CATSPEED pixels and remain unselected")

  ;; making cat bounce off the wall
  (check-equal? (cat-after-tick-helper (make-cat 100 CAT-MIN-Y-CO false #\N))
                (make-cat 100 (+ CAT-MIN-Y-CO CATSPEED) false #\S)
                "Incorrect value. Can did not bounce off the wall")
  )
;_______________________________________________________________________________
;; has-cat-hit-wall: Cat -> Boolean
;;    GIVEN: a cat
;;  RETURNS: a boolean true if the cat will go beyond the wall on the next tick
;;           else returns false
;; STRATEGY: Structural decomposition on c:Cat

(define (has-cat-hit-wall c)
  (cond [(and (char-ci=? (cat-dir c) #\N) 
              (< (- (cat-y-pos c) CATSPEED) CAT-MIN-Y-CO))
         true]
        [(and (char-ci=? (cat-dir c) #\S) 
              (> (+ (cat-y-pos c) CATSPEED) CAT-MAX-Y-CO))
         true]
        [(and (char-ci=? (cat-dir c) #\W) 
              (< (- (cat-x-pos c) CATSPEED) CAT-MIN-X-CO))
         true]
        [(and (char-ci=? (cat-dir c) #\E) 
              (> (+ (cat-x-pos c) CATSPEED) CAT-MAX-X-CO))
         true]
        [else false]))

;; EXAMPLES: 
;; (has-cat-hit-wall (make-cat 10 20 false #\S)
;; (has-cat-hit-wall (make-cat 100 200 false #\E)

;; TEST CASES:
(begin-for-test
  ;; cat not hitting wall 
  (check-equal? (has-cat-hit-wall (make-cat 100 200 false #\E))
                false
                "Incorrect value. Answer should be false")
  ;; cat hitting the North wall
  (check-equal? (has-cat-hit-wall (make-cat 100 CAT-MIN-Y-CO false #\N))
                true
                "Incorrect value. Answer should be true")
  
   ;; cat hitting the South wall
  (check-equal? (has-cat-hit-wall (make-cat 100 CAT-MAX-Y-CO false #\S))
                true
                "Incorrect value. Answer should be true")
  
   ;; cat hitting the West wall
  (check-equal? (has-cat-hit-wall (make-cat CAT-MIN-X-CO 100 false #\W))
                true
                "Incorrect value. Answer should be true")
  
     ;; cat hitting the East wall
  (check-equal? (has-cat-hit-wall (make-cat CAT-MAX-X-CO 100 false #\E))
                true
                "Incorrect value. Answer should be true")
  
  )
;_______________________________________________________________________________
;; make-cat-bounce: Cat -> Cat
;;    GIVEN: a cat
;;  RETURNS: a new cat after making it bounce of the wall (changing its 
;;           direction to the exact opposite of current direction) & calculating
;;           it new coordinates in the direction after tick.
;; STRATEGY: Structural Decomposition on c:Cat

(define (make-cat-bounce c)
  (calc-cat-next-pos (cat-x-pos c) (cat-y-pos c) (cat-selected? c)
                     (cond [(char-ci=? (cat-dir c) #\N)
                            #\S]
                           [(char-ci=? (cat-dir c) #\S)
                            #\N]
                           [(char-ci=? (cat-dir c) #\E)
                            #\W]
                           [(char-ci=? (cat-dir c) #\W)
                            #\E])))

;; EXAMPLES: 
;; (has-cat-hit-wall (make-cat 10 20 false #\S)
;; (has-cat-hit-wall (make-cat 100 200 false #\E)

;; TEST CASES:
(begin-for-test
  ;; cat bouncing off the North wall
  (check-equal? (make-cat-bounce (make-cat 100 CAT-MIN-Y-CO false #\N))
                (make-cat 100 (+ CAT-MIN-Y-CO CATSPEED) false #\S)
                "Incorrect value. Answer should be false")
  
   ;; cat bouncing off the South wall
  (check-equal? (make-cat-bounce (make-cat 100 CAT-MAX-Y-CO false #\S))
                (make-cat 100 (- CAT-MAX-Y-CO CATSPEED) false #\N)
                "Incorrect value. Answer should be false")
  
   ;; cat bouncing off the West wall
  (check-equal? (make-cat-bounce (make-cat CAT-MIN-X-CO 100 false #\W))
                (make-cat (+ CAT-MIN-X-CO CATSPEED) 100 false #\E)
                "Incorrect value. Answer should be false")
  
     ;; cat bouncing off the East wall
  (check-equal? (make-cat-bounce (make-cat CAT-MAX-X-CO 100 false #\E))
                (make-cat (- CAT-MAX-X-CO CATSPEED) 100 false #\W)
                "Incorrect value. Answer should be false")
  
  )  
;_______________________________________________________________________________

;; calc-cat-next-pos: Integer Integer Boolean Character -> Cat
;;    GIVEN: the x & y coordinates of the cat,indictor wheather it is selected
;;           and the direction in which the cat is moving 
;;  RETURNS: a new cat after making it move by the CATSPEED in the given 
;;           direction 
;; STRATEGY: Function Composition  

(define (calc-cat-next-pos x-pos y-pos selected? dir)
  (make-cat (cat-new-x-pos x-pos dir)
            (cat-new-y-pos y-pos dir)
            selected?
            dir))

;; Examples:
;; A unselected cat moving south
;; (calc-cat-next-pos 10 10 false #\S)

;; A selected cat moving north
;; (calc-cat-next-pos 10 10 false #\N)

;_______________________________________________________________________________
;; calc-new-x-pos: Integer Character -> Integer
;;    GIVEN: the x coordinate & the direction in which the cat is moving
;;  RETURNS: the new X coordinate after moving cat by the CATSPEED if it is 
;;           moving in the WEST or EAST direction if not returns the old x 
;;           co-ordinate
;; STRATEGY: Function Composition

(define (cat-new-x-pos x-pos dir)
  (cond [(char-ci=? dir #\E) (+ x-pos CATSPEED)]
        [(char-ci=? dir #\W) (- x-pos CATSPEED)]
        [else x-pos]))

;; Example:
;; (cat-new-x-pos 15 #\E)
;; (cat-new-x-pos 105 #\N)
;; TEST CASES;
;; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
;; calc-new-y-pos: Integer Character -> Integer
;;    GIVEN: the Y coordinate & the direction in which the cat is moving
;;  RETURNS: the new Y coordinate after moving cat by the CATSPEED if it is 
;;           moving in the NORTH or SOUTH direction if not returns the old Y 
;;           co-ordinate
;; STRATEGY: Function Composition  

(define (cat-new-y-pos y-pos dir)
  (cond [(char-ci=? dir #\S) (+ y-pos CATSPEED)]
        [(char-ci=? dir #\N) (- y-pos CATSPEED)]
        [else y-pos]))
         
;; Example:
;; (cat-new-y-pos 15 #\E)
;; (cat-new-y-pos 105 #\N)        
;; TEST CASES;
;; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
;; world-to-scene : World -> Scene
;;    GIVEN: a world
;;  RETURNS: a Scene that portrays the given world.
;; EXAMPLES: (world-to-scene paused-world-at-20) should return a canvas with
;;           two cats, one at (150,20) and one at (300,28)          
;; STRATEGY: Function Composition

(define (world-to-scene w)
  (place-cat
    (world-cat1 w)
    (place-cat
      (world-cat2 w)
      EMPTY-CANVAS)))

;; TESTCASES:
;; Variable created for testing purpose

(define image-of-paused-world-at-20
  (place-image CAT-IMAGE 150 20
    (place-image CAT-IMAGE 300 35
      EMPTY-CANVAS)))

(begin-for-test
  (check-equal?
    (world-to-scene paused-world-at-20)
    image-of-paused-world-at-20))

;_______________________________________________________________________________
;; place-cat : Cat Scene -> Scene
;;    GIVEN: a cat and a scene
;;  RETURNS: a scene like the given one, but with the given cat painted on it
;; EXAMPLES: refer test cases
;; STRATEGY: Structural Decomposition on c : Cat

(define (place-cat c s)
  (place-image
    CAT-IMAGE
    (cat-x-pos c) (cat-y-pos c)
    s))

;; TEST CASES:
;; check this visually to make sure it's what you want
(define image-at-20 (place-image CAT-IMAGE CAT1-X-COORD 20 EMPTY-CANVAS))

;; note: these only test whether world-to-scene calls place-image properly.
;; it doesn't check to see whether image-at-20 is the right image!
(begin-for-test
 (check-equal? 
   (place-cat selected-cat1-at-20 EMPTY-CANVAS)
   image-at-20
   "(place-cat selected-cat1-at-20 EMPTY-CANVAS) 
     returned unexpected image or value")

 (check-equal?
   (place-cat unselected-cat1-at-20 EMPTY-CANVAS)   
   image-at-20
   "(place-cat unselected-ca1t-at-20 EMPTY-CANVAS) 
    returned unexpected image or value"))

;_______________________________________________________________________________
;; world-after-key-event : World KeyEvent -> World
;;    GIVEN: a world w
;;  RETURNS: the world that should follow the given world
;;           after the given key event.
;;           on space, toggle paused?-- ignore all others
;; EXAMPLES: see tests below
;; STRATEGY: Cases Strategy

(define (world-after-key-event w kev)
  (cond
    [(key=? kev " ")     (world-with-paused-toggled w)]
    [(key=? kev "left")  (world-after-left-key w)]
    [(key=? kev "right") (world-after-right-key w)]
    [(key=? kev "up")    (world-after-up-key w)]
    [(key=? kev "down")  (world-after-down-key w)]
    [else w]))

;_______________________________________________________________________________
;; world-with-paused-toggled : World -> World
;;    GIVEN: a world
;;  RETURNS: a world just like the given one, but with paused? toggled
;; STRATEGY: Structural Decomposition on w : World

(define (world-with-paused-toggled w)
  (make-world
   (world-cat1 w)
   (world-cat2 w)
   (not (world-paused? w))))

;; TEST CASES:
;; for world-after-key-event, we need 4 tests: a paused world, and an
;; unpaused world, and a pause-key-event and a non-pause key event.

;; test variable with cat1 selected
(define unpaused-world-sel-cat1
  (make-world
    selected-cat1-at-20
    unselected-cat2-at-35
    false))

;; test variable with no cat selected
(define unpaused-unselected-world-at-20
  (make-world
    unselected-cat1-at-20
    unselected-cat2-at-35
    false))

(begin-for-test
  (check-equal?
    (world-after-key-event paused-world-at-20 pause-key-event)
    unpaused-world-at-20
    "after pause key, a paused world should become unpaused")

  (check-equal?
    (world-after-key-event unpaused-world-at-20 pause-key-event)
    paused-world-at-20
    "after pause key, an unpaused world should become paused")

  (check-equal?
    (world-after-key-event paused-world-at-20 non-pause-key-event)
    paused-world-at-20
    "after a non-pause key, a paused world should be unchanged")

  (check-equal?
    (world-after-key-event unpaused-world-at-20 non-pause-key-event)
    unpaused-world-at-20
    "after a non-pause key, an unpaused world should be unchanged")

;_______________________________________________________________________________
;; TEST CASES for new added arrow keys functionality  
  
  (check-equal?
    (world-after-key-event unpaused-world-at-20 "left")
    (make-world unselected-cat1-at-20 (make-cat 300 35 true #\W) false)
    "Selected cat2 did not turn west after left key")

  (check-equal?
    (world-after-key-event unpaused-world-at-20 "right")
    (make-world unselected-cat1-at-20 (make-cat 300 35 true #\E) false)
    "Selected cat2 did not turn east after right key")

  (check-equal?
    (world-after-key-event unpaused-world-at-20 "up")
    (make-world unselected-cat1-at-20 (make-cat 300 35 true #\N) false)
    "Selected cat2 did not turn north after up key")
  
  (check-equal?
    (world-after-key-event (make-world unselected-cat1-at-20 
                                       (make-cat 300 35 true #\N) false) "down")
    (make-world unselected-cat1-at-20 (make-cat 300 35 true #\S) false)
    "Selected cat2 did not turn south after down key")

  (check-equal?  
    (world-after-key-event unpaused-world-sel-cat1 "left")
    (make-world (make-cat CAT1-X-COORD 20 true #\W) unselected-cat2-at-35 false)
    "Selected cat1 did not turn west after left key")

  (check-equal?
    (world-after-key-event unpaused-world-sel-cat1 "right")
    (make-world (make-cat CAT1-X-COORD 20 true #\E) unselected-cat2-at-35 false)
    "Selected cat1 did not turn east after right key")

  (check-equal?
    (world-after-key-event unpaused-world-sel-cat1 "up")
    (make-world (make-cat CAT1-X-COORD 20 true #\N) unselected-cat2-at-35 false)
    "Selected cat1 did not turn north after up key")

  (check-equal?
    (world-after-key-event (make-world (make-cat 300 35 true #\N) 
                                       unselected-cat1-at-20 false)  "down")
    (make-world (make-cat 300 35 true #\S) unselected-cat1-at-20  false)
    "Selected cat1 did not turn south after down key")
  
  (check-equal?
    (world-after-key-event unpaused-unselected-world-at-20 "left")
     unpaused-unselected-world-at-20
    "Incorrect answer. Neither cat should have changed to west ")
  (check-equal?
    (world-after-key-event unpaused-unselected-world-at-20 "right")
     unpaused-unselected-world-at-20
    "Incorrect answer Neither cat should have changed to east")

  (check-equal?
    (world-after-key-event unpaused-unselected-world-at-20 "up")
     unpaused-unselected-world-at-20
    "Incorrect answer.Neither cat should have changed to north")

  (check-equal?
    (world-after-key-event unpaused-unselected-world-at-20 "down")
     unpaused-unselected-world-at-20
    "Incorrect answer. Neither cat should have changed to south"))  
  
;_______________________________________________________________________________
;; world-after-left-key: World -> Cat
;;    GIVEN: the world.
;;  RETURNS: the new world after turning selcted cat to move in west direction
;;           or the same world if neither cat is selected.
;; STRATEGY: structural decomposition on  w : World 

(define (world-after-left-key w)
  (cond [(cat-selected? (world-cat1 w))
         (change-cat-dir w 1 #\W)]
        [(cat-selected? (world-cat2 w))
         (change-cat-dir w 2 #\W)]
        [else w]))

;;EXAMPLES:
;;(world-after-left-key unpaused-world-sel-cat1)
;;(world-after-left-key unpaused-unselected-world-at-20)

;; TEST CASES;
;; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
;_______________________________________________________________________________
;; world-after-right-key: World -> Cat
;;    GIVEN: the world.
;;  RETURNS: the new world after turning selcted cat to move in east direction
;;           or the same world if neither cat is selected.
;; STRATEGY: structural decomposition on  w : World 

(define (world-after-right-key w)
  (cond [(cat-selected? (world-cat1 w))
         (change-cat-dir w 1 #\E)]
        
        [(cat-selected? (world-cat2 w))
         (change-cat-dir w 2 #\E)]
        
        [else w]))

;;EXAMPLES:
;;(world-after-right-key unpaused-world-sel-cat1)
;;(world-after-right-key unpaused-unselected-world-at-20)

;; TEST CASES;
;; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
;; world-after-up-key: World -> Cat
;;    GIVEN: the world.
;;  RETURNS: the new world after turning selcted cat to move in north direction
;;           or the same world if neither cat is selected.
;; STRATEGY: structural decomposition on  w : World 

(define (world-after-up-key w)
  (cond [(cat-selected? (world-cat1 w))
         (change-cat-dir w 1 #\N)]
        
        [(cat-selected? (world-cat2 w))
         (change-cat-dir w 2 #\N)]
        
        [else w]))

;;EXAMPLES:
;;(world-after-up-key unpaused-world-sel-cat1)
;;(world-after-up-key unpaused-unselected-world-at-20)

;; TEST CASES;
;; All possible cases have been tested by using testcases from calling functions
   
;_______________________________________________________________________________
;; world-after-down-key: World -> Cat
;;    GIVEN: the world.
;;  RETURNS: the new world after turning selcted cat to move in south direction
;;           or the same world if neither cat is selected.
;; STRATEGY: structural decomposition on  w : World 

(define (world-after-down-key w)
  (cond [(cat-selected? (world-cat1 w))
         (change-cat-dir w 1 #\S)]
        
        [(cat-selected? (world-cat2 w))
         (change-cat-dir w 2 #\S)]
        
        [else w]))

;;EXAMPLES:
;;(world-after-down-key unpaused-world-sel-cat1)
;;(world-after-down-key unpaused-unselected-world-at-20)

;; TEST CASES;
;; All possible cases have been tested by using testcases from calling functions
   
;_______________________________________________________________________________
;; change-cat-dir World Integer Character -> Cat
;;    GIVEN: the world, the number of the cat which is selected and new 
;;           direction in which cat has to travel 
;;  RETURNS: the new world after turning selcted cat to move given direction
;; STRATEGY: structural decomposition on  w : World


(define (change-cat-dir w catno dir)
  (make-world (if (= catno 1)
                  (change-cat-dir-helper (world-cat1 w) dir)
                  (world-cat1 w))
              
              (if (= catno 2)
                  (change-cat-dir-helper (world-cat2 w) dir)
                  (world-cat2 w))
              (world-paused? w)))

;;EXAMPLES:
;;(change-cat-dir unpaused-world-sel-cat1 1 #\E)
;;(change-cat-dir paused-world-at-20 2 #\W)

;; TEST CASES;
;; All possible cases have been tested by using testcases from calling functions
   
;_______________________________________________________________________________
;; change-cat-dir-helper Cat Character -> Cat
;;    GIVEN: the cat and the new direction in which it has to move 
;;  RETURNS: the new cat after turning selcted cat to move given direction
;; STRATEGY: structural decomposition on  c : Cat
              
(define (change-cat-dir-helper c dir)
  (make-cat (cat-x-pos c)
            (cat-y-pos c)
            (cat-selected? c)
            dir))

;;EXAMPLES:
;;(change-cat-dir-helper (make-cat 50 50 false #\N) #\S)
;;(change-cat-dir-helper (make-cat 50 50 false #\E) #\W)

;; TEST CASES;
;; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
;; world-after-mouse-event : World Integer Integer MouseEvent -> World
;;   GIVEN: a world and a description of a mouse event
;; RETURNS: the world that should follow the given mouse event

(define (world-after-mouse-event w mx my mev)
  (make-world
    (cat-after-mouse-event (world-cat1 w) mx my mev)
    (cat-after-mouse-event (world-cat2 w) mx my mev)
    (world-paused? w)))

;_______________________________________________________________________________
;; cat-after-mouse-event : Cat Integer Integer MouseEvent -> Cat
;;    GIVEN: a cat and a description of a mouse event
;;  RETURNS: the cat that should follow the given mouse event
;;  EXAMPLE: See slide on life cycle of dragged cat
;; STRATEGY: Structural decomposition on mouse events

(define (cat-after-mouse-event c mx my mev)
  (cond
    [(mouse=? mev "button-down") (cat-after-button-down c mx my)]
    [(mouse=? mev "drag")        (cat-after-drag c mx my)]
    [(mouse=? mev "button-up")   (cat-after-button-up c mx my)]
    [else c]))

;TEST CASES:
(begin-for-test

  ;; button-down:

  ;; button-down inside cat1
  (check-equal?
    (world-after-mouse-event 
      (make-world
        unselected-cat1-at-20
        unselected-cat2-at-35
        false)
      (+ CAT1-X-COORD 5) 15    ;; a coordinate inside cat1
      "button-down")
    (make-world
      selected-cat1-at-20
      unselected-cat2-at-35
      false)
    "button down inside cat1 should select it but didn't")


  ;; button-down inside cat2
  (check-equal?
    (world-after-mouse-event 
      (make-world
        unselected-cat1-at-20
        unselected-cat2-at-35
        false)
      (+ CAT2-X-COORD 5) 15    ;; a coordinate inside cat2
      "button-down")
    (make-world
      unselected-cat1-at-20
      selected-cat2-at-35
      false)
    "button down inside cat2 should select it but didn't")

  ;; button-down not inside any cat
  (check-equal?
    (world-after-mouse-event 
      (make-world
        unselected-cat1-at-20
        unselected-cat2-at-35
        false)
      (+ CAT1-X-COORD 5) 115    ;; a coordinate not inside cat1 or cat2
      "button-down")
    (make-world
      unselected-cat1-at-20
      unselected-cat2-at-35
      false)
    "button down outside any cat should leave world unchanged, but didn't")
  
  ;; tests for drag

  ;; no cats selected: drag should not change anything
  (check-equal?
    (world-after-mouse-event
      (make-world
        unselected-cat1-at-20
        unselected-cat2-at-35
        false)
      (+ CAT1-X-COORD 100) 15    ;; a large motion
      "drag")
    (make-world
        unselected-cat1-at-20
        unselected-cat2-at-35
        false)
    "drag with no cat selected didn't leave world unchanged")
    
  ;; cat1 selected
  (check-equal?
    (world-after-mouse-event
      (make-world
        selected-cat1-at-20
        unselected-cat2-at-35
        false)
      (+ CAT1-X-COORD 100) 15    ;; a large motion
      "drag")
    (make-world
      (make-cat (+ CAT1-X-COORD 100) 15 true #\S)
      unselected-cat2-at-35
      false)
    "drag when cat1 is selected should just move cat1, but didn't")

  ;; cat2 selected
  (check-equal?
    (world-after-mouse-event
      (make-world
        unselected-cat2-at-35
        selected-cat1-at-20
        false)
      (+ CAT1-X-COORD 100) 15    ;; a large motion
      "drag")
    (make-world
      unselected-cat2-at-35
      (make-cat (+ CAT1-X-COORD 100) 15 true #\S)
      false)
    "drag when cat2 is selected should just move cat2, but didn't")
  
  ;; tests for button-up

  ;; button-up always unselects both cats

  ;; unselect cat1
  (check-equal?
    (world-after-mouse-event
      (make-world
        selected-cat2-at-35
        unselected-cat1-at-20
        true)
      (+ CAT1-X-COORD 100) 15    ;; arbitrary location
      "button-up")
    (make-world
        (make-cat CAT2-X-COORD 58.5 false #\S)
        unselected-cat1-at-20
        true)
    "button-up failed to unselect cat1")

  ;; unselect cat2
  (check-equal?
    (world-after-mouse-event
      (make-world
        unselected-cat1-at-20
        selected-cat2-at-35
        true)
      (+ CAT1-X-COORD 100) 15    ;; arbitrary location
      "button-up")
    (make-world
        unselected-cat1-at-20
        (make-cat 300 58.5 #f #\S)
        true)
    "button-up failed to unselect cat2")

  ;; unselect cat2
  (check-equal?
    (world-after-mouse-event
      (make-world
        unselected-cat1-at-20
        unselected-cat2-at-35
        true)
      (+ CAT1-X-COORD 100) 15    ;; arbitrary location
      "button-up")
    (make-world
        unselected-cat1-at-20
        unselected-cat2-at-35
        true)
    "button-up with two unselected cats failed.")

  ;; tests for other mouse events

  (check-equal?
    (world-after-mouse-event unpaused-world-at-20 
      (+ CAT1-X-COORD 100) 15    ;; arbitrary coordinate
      "move")
    unpaused-world-at-20
    "other mouse events should leave the world unchanged, but didn't")

  )
;_______________________________________________________________________________
;; helper functions:

;; cat-after-button-down : Cat Integer Integer -> Cat
;;  RETURNS: the cat following a button-down at the given location.
;; STRATEGY: struct decomp on cat

(define (cat-after-button-down c x y)
  (if (in-cat? c x y)
      (make-cat (cat-x-pos c) (cat-y-pos c) true (cat-dir c))
      c))

;; TEST CASES;
;; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
;; cat-after-drag : Cat Integer Integer -> Cat
;;  RETURNS: the cat following a drag at the given location
;; STRATEGY: struct decomp on cat

(define (cat-after-drag c x y)
  (if (cat-selected? c)
      (make-cat x y true (cat-dir c))
      c))

;; TEST CASES;
;; All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
;; cat-after-button-up : Cat Integer Integer -> Cat
;; RETURNS: the cat following a button-up. the cat is brought back into the 
;;          canvas if it has been previously dragged out of the canvas else
;;          else returns the same cat with selected? set to false
;; STRATEGY: struct decomposition on c : cat

(define (cat-after-button-up c x y)
  (if (cat-selected? c)
      (make-cat (cond [(> (cat-x-pos c) CAT-MAX-X-CO) CAT-MAX-X-CO]
                      [(< (cat-x-pos c) CAT-MIN-X-CO) CAT-MIN-X-CO]
                      [else (cat-x-pos c)])
                (cond [(> (cat-y-pos c) CAT-MAX-Y-CO) CAT-MAX-Y-CO]
                      [(< (cat-y-pos c) CAT-MIN-Y-CO) CAT-MIN-Y-CO]
                      [else (cat-y-pos c)])
                false 
                (cat-dir c))
      c))
;; EXAMPLE:
;; (cat-after-button-up 
;;                 (make-cat CANVAS-WIDTH CANVAS-HEIGHT true #\S) 100 200)
;;                 (make-cat  CAT-MAX-X-CO  CAT-MAX-Y-CO false #\S))

;; (cat-after-button-up 
;;                 (make-cat 0 80 true #\S) 100 200)
;;                 (make-cat  CAT-MIN-X-CO  80 false #\S))

;; TEST CASES for cases which are not covered by previous test cases  

(begin-for-test
  ;; Cat outside of the canvas both
   (check-equal? (cat-after-button-up 
                 (make-cat CANVAS-WIDTH CANVAS-HEIGHT true #\S) 100 200)
                 (make-cat  CAT-MAX-X-CO  CAT-MAX-Y-CO false #\S)
                 "Cat did not bounce back to into the canvas")
   ;; cat outside of the canvas only by left most x coordinate
    (check-equal? (cat-after-button-up 
                 (make-cat 0 80 true #\S) 100 200)
                 (make-cat  CAT-MIN-X-CO  80 false #\S)
                 "Cat did not bounce back to into the canvas"))

;_______________________________________________________________________________
;; in-cat? : Cat Integer Integer -> Cat
;;    GIVEN: a cat and the x & y co ordinates of the mouse event
;;  RETURNS: true iff the given coordinate is inside the bounding box of
;;           the given cat.
;; EXAMPLES: see tests below
;; STRATEGY: Structural Decomposition on c : cat

(define (in-cat? c x y)
  (and
    (<= 
      (- (cat-x-pos c) HALF-CAT-WIDTH)
      x
      (+ (cat-x-pos c) HALF-CAT-WIDTH))
    (<= 
      (- (cat-y-pos c) HALF-CAT-HEIGHT)
      y
      (+ (cat-y-pos c) HALF-CAT-HEIGHT))))

;; TEST CASES:

(begin-for-test
  
  ;; inside the cat
  (check-equal?
    (in-cat? unselected-cat1-at-20 (+ CAT1-X-COORD 5) 15)
    true
    "test of in-cat? with nearby point")

  (check-equal?
    (in-cat? unselected-cat1-at-20 
      (+ CAT1-X-COORD 100) 15)    ;; a coordinate not inside the cat
    false
    "test of in-cat? with distant point")

  )
;_______________________________________________________________________________
;; cat-north? Cat -> Boolean
;;    GIVEN: a cat 
;;  RETURNS: the true if the cat is moving north else false
;; STRATEGY: structural decomposition on  c : Cat

(define (cat-north? c)
  (if (char-ci=? (cat-dir c) #\N)
      true
      false))

;;EXAMPLES:
;;(cat-north? selected-cat1-at-20)
;;(cat-north? selected-cat2-at-35)
   
;_______________________________________________________________________________
;; cat-south? Cat -> Boolean
;;    GIVEN: a cat 
;;  RETURNS: the true if the cat is moving south else false
;; STRATEGY: structural decomposition on  c : Cat

(define (cat-south? c)
  (if (char-ci=? (cat-dir c) #\S)
      true
      false))

;;EXAMPLES:
;;(cat-south? selected-cat1-at-20)
;;(cat-south? selected-cat2-at-35)
   
;_______________________________________________________________________________
;; cat-east? Cat -> Boolean
;;    GIVEN: a cat 
;;  RETURNS: the true if the cat is moving east else false
;; STRATEGY: structural decomposition on  c : Cat

(define (cat-east? c)
  (if (char-ci=? (cat-dir c) #\E)
      true
      false))

;;EXAMPLES:
;;(cat-east? selected-cat1-at-20)
;;(cat-east? selected-cat2-at-35)
   
;_______________________________________________________________________________
;; cat-west? Cat -> Boolean
;;    GIVEN: a cat 
;;  RETURNS: the true if the cat is moving west else false
;; STRATEGY: structural decomposition on  c : Cat

(define (cat-west? c)
  (if (char-ci=? (cat-dir c) #\W)
      true
      false))
 
;;EXAMPLES:
;;(cat-west? selected-cat1-at-20)
;;(cat-west? selected-cat2-at-35)
        
;;TEST CASES:
(begin-for-test 
  ;; Positive test for cat-north? function
  (check-equal? (cat-north? (make-cat 50 50 false #\N))
                true
                "Cat is moving north answer should have been true")
   ;; Negative test for cat-north? function
  (check-equal? (cat-north? (make-cat 50 50 false #\S))
                false
                "Cat is moving south answer should have been false")
  ;; Positive test for cat-south? function
  (check-equal? (cat-south? (make-cat 50 50 false #\S))
                true
                "Cat is moving south answer should have been true")
   ;; Negative test for cat-south? function
  (check-equal? (cat-south? (make-cat 50 50 false #\N))
                false
                "Cat is moving north answer should have been false")
  ;; Positive test for cat-east? function
  (check-equal? (cat-east? (make-cat 50 50 false #\E))
                true
                "Cat is moving east answer should have been true")
   ;; Negative test for cat-east? function
  (check-equal? (cat-east? (make-cat 50 50 false #\N))
                false
                "Cat is moving north answer should have been false")
  ;; Positive test for cat-west? function  
  (check-equal? (cat-west? (make-cat 50 50 false #\W))
                true
                "Cat is moving west answer should have been true")
   ;; Positive test for cat-west? function
  (check-equal? (cat-west? (make-cat 50 50 false #\N))
                false
                "Cat is moving north answer should have been false"))

;_________________________________________________________________________  
;; initial-world : Integer -> World
;; RETURNS: a world with two unselected cats at the given y coordinate
(define (initial-world y)
  (make-world
    (make-cat CAT1-X-COORD y false #\S)
    (make-cat CAT2-X-COORD y false #\S)
    false))

;; TEST CASES:
(begin-for-test 
  (check-equal? (initial-world 3)
                (make-world (make-cat CAT1-X-COORD 3 false #\S)
                            (make-cat CAT2-X-COORD 3 false #\S)
                false)))