#lang racket

(require rackunit)
(require 2htdp/universe)
(require 2htdp/image)
(require "extras.rkt")

(provide World%
         SquareToy%
         CircleToy%
         World<%>
         Toy<%>
         make-world
         make-square-toy
         make-circle-toy
         run)
;_______________________________________________________________________________

; DATA DEFINITIONS

; A Direction can be one of 
; -- "east"  -- Interpretation : the toy is moving towards right canvas border
; -- "west"  -- Interpretation : the toy is moving towards left canvas border

; TEMPLATE:
; direction-fn : Direction -> ??
#;(define (directon-fn dir)
    (cond
      [(string=? "east" dir) ...]
      [(string=? "west" dir) ...]))

; A ListOfToy is either
; -- empty
; -- (cons Toy<%> ListOfToy)

;  lot-fn : ListOfToy -> ??
#; (define (lot-fn lot) 
   (cond
      [(empty? lot) ...]
      [(else (...
                 (first lot))
                 (lot-fn (rest lot)))]))


; A ToyColor is a scalar data which be one of the following string
; "green"  Interp: the toy is green coloured
; "red"    Interp: the toy is red coloured

;_______________________________________________________________________________
;CONSTANTS

(define CANVAS-HEIGHT 500)
(define CANVAS-WIDTH 400)
(define HALF-CANVAS-HEIGHT (/ CANVAS-HEIGHT 2))
(define HALF-CANVAS-WIDTH (/ CANVAS-WIDTH 2))

(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))

(define OUTLINE "outline")
(define SOLID "solid")
(define RED "red")
(define GREEN "green")

; SQUARE CONSTANTS

(define SQUARE-SIZE 40)
(define SQUARE-HALF-SIZE (/ SQUARE-SIZE 2))
(define MAX-SQUARE-X (- CANVAS-WIDTH SQUARE-HALF-SIZE))
(define MIN-SQUARE-X SQUARE-HALF-SIZE)

(define SQUARE-TOY (square SQUARE-SIZE OUTLINE GREEN))

;CIRCLE CONSTANTS

(define TRGT-RADIUS 10)
(define CIRC-TOY-RADIUS 5)

(define CIRCLE-TOY-RED   (circle CIRC-TOY-RADIUS  SOLID   RED))
(define CIRCLE-TOY-GREEN (circle CIRC-TOY-RADIUS  SOLID   GREEN))
(define TARGET-CIRCLE    (circle TRGT-RADIUS OUTLINE GREEN))

;KEY EVENTS
(define S-KEY "s")
(define C-KEY "c")

;MOUSE-EVENTS
(define MOUSE-CLICK "button-down")
(define MOUSE-UNCLICK "button-up")
(define MOUSE-DRAG "drag")

;DIRECTIONS:
(define EAST "east")
(define WEST "west")

;MISC
(define FOUR 4)
(define FIVE 5)
(define ONE 1)
(define ZERO 0)
;_______________________________________________________________________________
; INTERFACE: World<%>
(define World<%>
  (interface ()
    
    ;; -> World<%>
    ;; Returns the World<%> that should follow this one after a tick
    on-tick                             

    ;; Integer Integer MouseEvent -> World<%>
    ;; Returns the World<%> that should follow this one after the
    ;; given MouseEvent
    on-mouse

    ;; KeyEvent -> World<%>
    ;; Returns the World<%> that should follow this one after the
    ;; given KeyEvent
    on-key

    ;; -> Scene
    ;; Returns a Scene depicting this world
    ;; on it.
    on-draw 
    
    ;; -> Integer
    ;; RETURN: the x and y coordinates of the target
    target-x
    target-y

    ;; -> Boolean
    ;; Is the target selected?
    target-selected?

    ;; -> ListOfToy<%>
    get-toys))

;_______________________________________________________________________________
; INTERFACE: Toy<%>

(define Toy<%> 
  (interface ()

    ;; -> Toy<%>
    ;; returns the Toy that should follow this one after a tick
    on-tick                             

    ;; Scene -> Scene
    ;; Returns a Scene like the given one, but with this toy drawn
    ;; on it.
    add-to-scene

    ;; -> Int
    toy-x
    toy-y

    ;; -> ColorString
    ;; returns the current color of this toy
    toy-color))
;_______________________________________________________________________________
; CLASS: World% implements World<%> 

; A World is a (new World% 
;                   [x Integer] 
;                   [y Integer] 
;                   [selected? Boolean]
;                   [mouse-x-co Integer] 
;                   [mouse-y-co Integer] 
;                   [speed PosInt] 
;                   [toys ListOfToy])
; INTERPRETATION
;   x         - Represents the X co-ordinate of the center of target circle
;   y         - Represents the Y co-ordinate of the center of target circle
;  selected?  - Is true if the target has been selected else false
;  mouse-x-co - Represents the previous mouse event X co-ordinate
;  mouse-y-co - Represents the previous mouse event Y co-ordinate
;  speed      - Represents the speed in which the square toys should move 
;  toys       - A list containing both square and circle toys
;


(define World%
  (class* object% (World<%>)
    
    (init-field x)
    (init-field y)
    (init-field selected?)
    (init-field mouse-x-co)
    (init-field mouse-y-co)
    (init-field toys)
    (init-field speed)

    ; TRGT field is the target circle 
    (field [TRGT TARGET-CIRCLE])
     
    (super-new)
    
    ; on-tick: -> World%
    ;  Returns: A world like this world, but as it should be after tick
    ; Examples: Refer test cases
    ; Strategy: HOFC
    
    (define/public (on-tick)
      (new World%
           [x x]
           [y y]
           [selected? selected?]
           [mouse-x-co mouse-x-co]
           [mouse-y-co mouse-y-co]
           [speed speed]
           [toys (map
                  ; Toy<%> -> Toy<%>
                  ; Given: a toy
                  ; Returns: the toy that should follow after a tick.
                  (lambda (toy)
                    (send toy on-tick))
                  toys)]))
    
    ; on-mouse: Integer Integer MouseEvent -> World%
    ;    Given: the mouse's  x and y co-ordinates on canvas and mouse event
    ;  Returns: A world like this world, but as it should be after mouse event
    ; Examples: Refer test cases
    ; Strategy: Cases on mev: MouseEvent
    
    (define/public (on-mouse x-co y-co mev)
      (cond 
        [(mouse=? mev MOUSE-CLICK) (send this world-after-click x-co y-co)]
        [(mouse=? mev MOUSE-DRAG) (send this world-after-drag x-co y-co)]
        [(mouse=? mev MOUSE-UNCLICK) (send this world-after-unclick x-co y-co)]
        [else this]))
    
    ; world-after-click: Integer Integer -> World%
    ;    Given: the mouse event's x and y co-ordinates on canvas
    ;  Returns: A world like this world, but as it should be after mouse click
    ; Examples: (send (new World%
    ;               [x-pos 200] [y-pos 250] [selected? false] [mouse-x-co 0]
    ;               [mouse-y-co 0] [toys empty] [speed 2])
    ;                 world-after-click 200 200)-> 
    ;                      (new World% [x-pos 200] [y-pos 250][selected? false]
    ;               [mouse-x-co 200] [mouse-y-co 200] [toys empty] [speed 2])
    ; Strategy: Function Composition
    
    (define/public (world-after-click mx my)
      (new World%
           [x x]
           [y y]
           [selected? (is-target-selected? x y mx my)]
           [mouse-x-co mx]
           [mouse-y-co my]
           [speed speed]
           [toys toys]))
    
    ; is-target-selected?: Integer Integer Integer Integer -> Boolean
    ;    Given: x and y coordinate of the center of target also x and y 
    ;           coordinate of the mouse click event
    ;  Returns: true iff the mouse click was made inside the target else false
    ; Examples: (is-target-selected? 10 10 11 11) -> true
    ;           (is-target-selected? 10 10 11 20) -> false
    ; Strategy: Function Composition
    
    (define/public (is-target-selected? x y mx my)
      (<= (sqrt(+ (sqr (- x mx)) 
                  (sqr (- y my)))) 
          TRGT-RADIUS))
    
    ; world-after-drag: Integer Integer -> Boolean
    ;    Given: x and y coordinate of the mouse drag event
    ;  Returns: the same world if the target is not selected else the same world
    ;           with the target moved to the new location.
    ; Examples: (send NEW-WORLD-AFT-CLICK  world-after-drag 300 300) 
    ;                                             ->   NEW-WORLD-AFT-DRAG
    ; Strategy: Function Composition
    
    (define/public (world-after-drag mx my)
      (new World%
           [x (x-co-after-drag mx)]
           [y (y-co-after-drag my)]
           [selected? selected?]
           [mouse-x-co mx]
           [mouse-y-co my]
           [speed speed]
           [toys toys]))
    
    ; x-co-after-drag: Integer -> Integer
    ;    Given: x coordinate of the mouse drag event 
    ;  Returns: the new x co-ordinate of the center of target after drag
    ; Examples: (send NEW-WORLD-AFT-CLICK x-co-after-drag 300) -> 295
    ; Strategy: Function Composition 
    
    (define/public (x-co-after-drag mx)
      (if selected? 
      (+ x (- mx mouse-x-co))
      x))
    
    ; y-co-after-drag: Integer -> Integer
    ;    Given: y coordinate of the mouse drag event 
    ;  Returns: the new y co-ordinate of the center of target after drag
    ; Examples: (send NEW-WORLD-AFT-CLICK y-co-after-drag 300) -> 293
    ; Strategy: Function Composition 
    
    (define/public (y-co-after-drag my)
      (if selected? 
      (+ y (- my mouse-y-co))
      y))
    
    ; world-after-unclick Integer Integer -> World%
    ;    Given: the x and y coordinate of the mouse unclick event 
    ;  Returns: the same world as previous but with mouse x and y coordinates
    ;           reset to 0
    ; Examples: (send NEW-WORLD-AFT-CLICK world-after-unclick 300 300)
    ;                                      -> NEW-WORLD-AFT-UNCLICK
    ; Strategy: Function Composition 
    
    (define/public (world-after-unclick mx my)
      (new World%
           [x x]
           [y y]
           [selected? false]
           [mouse-x-co ZERO]
           [mouse-y-co ZERO]
           [speed speed]
           [toys toys]))
      
    ; on-key: KeyEvent  -> World%
    ;    Given: the key event
    ;  Returns: the world with a new square toy at target's center if the s key
    ;           is preseed or circle toy if c key is pressed else the same world
    ; Examples: Refer test cases 
    ; Strategy: Cases on kev: KeyEvent
    
    (define/public (on-key kev)
      (cond 
        [(key=? kev S-KEY) (create-sqr-toy)]
        [(key=? kev C-KEY) (create-circ-toy)]
        [else this]))
    
    ; create-sqr-toy:  -> World%
    ;  Returns: the world with a new square toy with the same center as target
    ; Examples: (send WORLD1 create-sqr-toy) -> WORLD1-AFT-KEY-S
    ; Strategy: Function Composition
    
    (define/public (create-sqr-toy)
      (new World%
           [x x]
           [y y]
           [selected? selected?]
           [mouse-x-co mouse-x-co]
           [mouse-y-co mouse-y-co]
           [speed speed]
           [toys (cons (make-square-toy x y speed) toys)]))

    ; create-circ-toy:  -> World%
    ;  Returns: world with a new green circle toy with the same center as target
    ; Examples: (send WORLD1 create-circ-toy) -> WORLD1-AFT-KEY-C
    ; Strategy: Function Composition   
    
    (define/public (create-circ-toy)
      (new World%
           [x x]
           [y y]
           [selected? selected?]
           [mouse-x-co mouse-x-co]
           [mouse-y-co mouse-y-co]
           [speed speed]
           [toys (cons (make-circle-toy x y) toys)]))
    
    ; on-draw: -> Scene
    ; Returns : a scene potraying this world on it.
    ; Example : Refer Test cases
    ; Strategy: HOFC
    
    (define/public (on-draw)
      (local
        ((define scene-with-trgt (send this trgt-to-scene EMPTY-CANVAS)))
        
        (foldr
         ; Toy<%> Scene -> Scene
         ; Given: a toy and a scene
         ; Returns: the toy placed on the given scene
         (lambda (toy scene)
           (send toy add-to-scene scene))
         scene-with-trgt
         toys)))
    
    ; trgt-to-scene Scene : -> Scene
    ;   Given : a scene
    ; Returns : the scene with the target circle on it
    ; Example : (trgt-to-scene EMPTY-CANVAS) -> 
    ;                    (place-image TARGET-CIRCLE HALF-CANVAS-HEIGHT
    ;                                               HALF-CANVAS-WIDTH
    ;                                               EMPTY-CANVAS)
    ; Design Strategy: Function Composition
    
    (define/public (trgt-to-scene scene)
      (place-image TRGT x y scene))
   
    ; get-toys -> Toys
    ; Returns : the list of toys in the current world
    ; Example : (send WORLD1 get-toys) -> (list SQUARE1 CIRCLE1 CIRCLE2 CIRCLE3)
    ; Strategy: Function Composition
    
    (define/public (get-toys)
      toys)
    
    ; target-x -> Integer
    ; Returns : the x coordinate of the target
    ; Example : (send WORLD1 target-x) -> 150
    ; Strategy: Function Composition
    
    (define/public (target-x)
      x)
    
    ; target-y -> Integer
    ; Returns : the y coordinate of the target
    ; Example : (send WORLD1 target-y) -> 222
    ; Strategy: Function Composition  
    
    (define/public (target-y)
      y)

    ; target-selected? -> Boolean
    ; Returns : the value of selected? in the given world object
    ; Example : (send WORLD1 target-selected?) -> false
    ; Strategy: Function Composition  
    
    (define/public (target-selected?)
      selected?)))

;_______________________________________________________________________________
;SquareToy% -- a class that satisfies the Toy<%> interface

; A SquareToy is a
;(new SquareToy%
;     [x Integer]
;     [y Integer]
;     [dir Direction]
;     [speed PosInt])

; INTERPRETATION: 
; x     - The x coordinate of the center of the square toy 
; y     - The y coordinate of the center of the square toy
; dir   - represents the direction in which the square toy is moving
; speed - represents the speed in which the square is moving in terms of pixels

(define SquareToy%
  (class* object% (Toy<%>)
    (init-field x
                y
                dir
                speed)
    
    ; SQR field represents the green square image of side 20 
    (field [SQR SQUARE-TOY])
    
    (super-new)
    
    ; on-tick: -> SquareToy%
    ;   Returns: a square toy like this one but as it should be after tick
    ;   Example: Refer test cases
    ; Startegy : Function Composition
    
    (define/public (on-tick)
      (new SquareToy%
           [x (get-new-x-co x dir)]
           [y y]
           [dir (get-new-dir x dir)]
           [speed speed]))
    
    ; add-to-scene: Scene -> Scene
    ;   Returns: returns the scene with the square toy in it
    ;   Example: (send SQUARE1 add-to-scene EMPTY-CANVAS)
    ;                -> (place-image SQUARE-TOY 375 20 EMPTY-CANVAS)
    ; Startegy : Function Composition
        
    (define/public (add-to-scene scene)
      (place-image SQR x y scene))

    ; get-new-x-co: Integer Direction -> Integer
    ;   Returns: returns the new x coordinate of the toy ater moving
    ;   Example: (send SQUARE1 get-new-x-co 375 EAST) -> 380
    ; Startegy : Structural Decomposition on dir : Direction 
    
    (define/public (get-new-x-co x dir)
      (cond              
        [(string=? dir EAST) (calc-x-moving-east x)]
        [(string=? dir WEST) (calc-x-moving-west x)]))
    
    ; calc-x-moving-east: Integer -> Integer
    ;   Returns: returns the new x coordinate of the toy ater moving east
    ;   Example: (send SQUARE1 calc-x-moving-east 375) -> 380
    ; Startegy : Function Composition
    
    (define/public (calc-x-moving-east x)
      (if (>= (+ x speed) MAX-SQUARE-X)
          MAX-SQUARE-X
          (+ x speed)))
    
    ; calc-x-moving-west: Integer -> Integer
    ;   Returns: returns the new x coordinate of the toy ater moving west
    ;   Example: (send SQUARE1 calc-x-moving-east 375) -> 365
    ; Startegy : Function Composition
    
    (define/public (calc-x-moving-west x)
      (if  (<= (- x speed) MIN-SQUARE-X)
           MIN-SQUARE-X
          (- x speed)))
          
    ; get-new-dir: Integer Direction -> Direction
    ;   Returns: the new direction in which the toy shold travel
    ;   Example: (send SQUARE1 get-new-dir 375 EAST) -> WEST
    ; Startegy : Structural Decomposition on dir : Direction
    
    (define/public (get-new-dir x dir) 
      (cond 
        [(and (string=? dir EAST) (= (get-new-x-co x dir) MAX-SQUARE-X)) WEST]
        [(and (string=? dir WEST) (= (get-new-x-co x dir) MIN-SQUARE-X)) EAST]
        [else dir]))
    
    ; toy-color -> ToyColor 
    ; Returns : the color of the toy 
    ; Example : (send SQUARE1 toy-color) -> GREEN
    ; Strategy: Function Composition
    
    (define/public (toy-color)
      GREEN)

    ; toy-x -> Integer 
    ; Returns : the x coordinate of the center of the toy
    ; Example : (send SQUARE1 toy-x) -> 375
    ; Strategy: Function Composition
    
    (define/public (toy-x)
      x)

    ; toy-y -> Integer 
    ; Returns : the y coordinate of the center of the toy
    ; Example : (send SQUARE1 toy-y) -> 20
    ; Strategy: Function Composition
    
    (define/public (toy-y)
      y)
    
    ; toy-direction -> Direction 
    ; Returns : the direction in which the square is travelling
    ; Example : (send SQUARE1 toy-direction) -> EAST
    ; Strategy: Function Composition
    
    (define/public (toy-direction)
      dir)
    
    ;is-toy-equal?: SquareToy% -> Boolean
    ;  Given: a square toy 
    ;Returns: true iff the current square toy and the given square toy are equal
    ;Examples: Refer test cases
    ;Strategy: Function Composition
    
    (define/public (is-toy-equal? sq2)
      (and (equal? x (send sq2 toy-x))
           (equal? y (send sq2 toy-y))
           (equal? dir (send sq2 toy-direction))))))

;_______________________________________________________________________________
;CircleToy% -- a class that satisfies the Toy<%> interface

; A CircleToy is a
;(new CircleToy%
;     [x Integer]
;     [y Integer]
;     [color CircleToyColor]
;     [sec-cnt NonNegInt])

;INTERPRETATION:
; x       - The x coordinate of the center of the circle toy 
; y       - The y coordinate of the center of the circle toy
; color   - represents the color of the circle
; sec-cnd - represent the seconds count of the current color circle's existence

(define CircleToy%
  (class* object% (Toy<%>)
    (init-field x
                y
                color
                sec-cnt)
    
    (super-new)
    
    ; on-tick: -> CircleToy%
    ;   Returns: a circle toy like this one but as it should be after tick
    ;   Example: (send CIRCLE1 on-tick) -> CIRCLE1-AFT-TICK
    ; Startegy : Function Composition
    
    (define/public (on-tick)
      (new CircleToy%
           [x x]
           [y y]
           [color (determine-color color sec-cnt)]
           [sec-cnt (calc-sec-cnt sec-cnt)]))
    
    ; determine-color: ToyColor NonNegInt -> CircleToyColor 
    ;   Returns: the color of the circle and the seconds count
    ;   Example: (send CIRCLE1 determine-color GREEN ONE) -> GREEN
    ; Startegy : Cases on color : ToyColor
    
    (define/public (determine-color color sec-cnt)
      (cond [(and (string=? GREEN color) (= sec-cnt FIVE)) RED]
            [(and (string=? RED color) (= sec-cnt FIVE)) GREEN]
            [else color]))

    ; calc-sec-cnt: NonNegInt -> NonNegInt 
    ;   Returns: Zero iff the count has already reached 5 else adds one to it
    ;   Example: (send CIRCLE1 determine-color 1) -> 2
    ; Startegy : Function Composition 
    
    (define/public (calc-sec-cnt sec-cnt)
      (if (= sec-cnt FIVE)
          ZERO
          (+ sec-cnt ONE)))
    
    ; add-to-scene: Scene -> Scene 
    ;   Returns: the scene with the circle of the specified color in it
    ;   Example: (send CIRCLE1 add-to-scene EMPTY-CANVAS)
    ;                      -> (place-image CIRCLE-TOY-GREEN 30 30 EMPTY-CANVAS)
    ; Startegy : Function Composition 
 
    (define/public (add-to-scene scene)
      (place-image (if (string=? color GREEN)
                       CIRCLE-TOY-GREEN
                       CIRCLE-TOY-RED)
                       x y scene))
    
    ; toy-color -> ToyColor 
    ; Returns : the color of the toy
    ; Example : (send CIRCLE1 toy-color) -> GREEN
    ; Strategy: Function Composition
    
    (define/public (toy-color)
      color)

    ; toy-x -> Integer 
    ; Returns : the x coordinate of the center of the toy
    ; Example : (send CIRCLE1 toy-x) -> 30
    ; Strategy: Function Composition
    
    (define/public (toy-x)
      x)

    ; toy-y -> Integer 
    ; Returns : the y coordinate of the center of the toy
    ; Example : (send CIRCLE1 toy-y) -> 30
    ; Strategy: Function Composition
    
    (define/public (toy-y)
      y)
    
    ;is-toy-equal?: CircleToy% -> Boolean
    ;  Given: a circle toy 
    ;Returns: true iff the current circle toy and the given circle toy are equal
    ;Examples: Refer test cases
    ;Strategy: Function Composition
    
    (define/public (is-toy-equal? circ2)
     (and (equal? x (send circ2 toy-x))
          (equal? y (send circ2 toy-y))
          (equal? color (send circ2 toy-color))))))
;_______________________________________________________________________________

; make-world: PosInt -> World%
;   Given: a positive integer representing the speed 
; Returns: a world with a target, no toys and speed as given
; Example: Refer test cases
;Strategy: Function Composition

(define (make-world spd)
  (new World%
       [x HALF-CANVAS-WIDTH]
       [y HALF-CANVAS-HEIGHT]
       [selected? false]
       [mouse-x-co ZERO]
       [mouse-y-co ZERO]
       [toys empty]
       [speed spd]))

; make-square-toy: Integer Integer PosInt -> SquareToy%
;   Given: a x and y coordinate of the new square to be created and its speed
; Returns: a square heading east at given speed from given location
; Example: (make-square-toy 375 20 10) -> SQUARE1
;Strategy: Function Composition

(define (make-square-toy x-co y-co spd)
  (new SquareToy%
       [x x-co]
       [y y-co]
       [dir EAST]
       [speed spd]))

; make-circle-toy Integer Integer -> CircleToy%
;   Given: a x and y coordinate of the new circle to be created
; Returns: a green circle with its location in the coordinates given
; Example: (make-circle-toy 30 30) -> CIRCLE1
;Strategy: Function Composition

(define (make-circle-toy x-co y-co)
  (new CircleToy%
       [x x-co]
       [y y-co]
       [color GREEN]
       [sec-cnt ZERO]))

;   run : PosNum PosInt -> World%
;  GIVEN: the frame rate (in seconds/tick) and the speed of square 
;         (pixels/tick)
;RETRUNS: Final state of the world.

(define (run fr spd)
  (big-bang (make-world spd)
            (on-tick 
             ; World% -> World%
             ; GIVEN: World w
             ; RETURNS: world after tick
              (lambda (w) (send w on-tick)) fr)
            (on-draw 
             ; World% -> World%
             ; GIVEN: World w
             ; RETURNS: world after draw
             (lambda (w) (send w on-draw)))
            (on-key 
             ; World% KeyEvent -> World%
             ; GIVEN: World w
             ; RETURNS: world after key event
             (lambda (w kev) (send w on-key kev)))
            (on-mouse 
             ; World% Integer Integer MouseEvent -> World%
             ; GIVEN: World w
             ; RETURNS: world after mouse event
             (lambda (w mx my mev) (send w on-mouse mx my mev)))))
            

;_______________________________________________________________________________
; TESTING FUNCTIONS 
;is-world-equal? World% World% -> Boolean
;    Given: the two worlds to be compared
;  Returns: true iff the two worlds are equal, else false
;  Example: Refer test cases
; Strategy: HOFC

(define (is-world-equal? w1 w2)
  (and (equal? (send w1 target-x) (send w2 target-x))
       (equal? (send w1 target-y) (send w2 target-y))
       (equal? (send w1 target-selected?) (send w2 target-selected?))
       
       (andmap 
        ;Toy Toy -> Boolean
        ;   Given: the toys to be compared
        ; Returns: true iff the two worlds are equal, else false
        (lambda (toy1 toy2)
          (send toy1 is-toy-equal? toy2))
         (send w1 get-toys)
         (send w2 get-toys))))

;_______________________________________________________________________________
;TEST CONSTANTS:
(define CIRCLE1 (new CircleToy%
                     [x 30]
                     [y 30]
                     [color GREEN]
                     [sec-cnt ZERO]))

(define CIRCLE2 (new CircleToy%
                     [x 90]
                     [y 40]
                     [color GREEN]
                     [sec-cnt FIVE]))

(define CIRCLE3 (new CircleToy%
                     [x 110]
                     [y 80]
                     [color RED]
                     [sec-cnt FIVE]))

(define CIRCLE4 (new CircleToy%
                     [x 150]
                     [y 222]
                     [color GREEN]
                     [sec-cnt ZERO]))


(define CIRCLE1-AFT-TICK (new CircleToy%
                              [x 30]
                              [y 30]
                              [color GREEN]
                              [sec-cnt 1]))

(define CIRCLE2-AFT-TICK (new CircleToy%
                              [x 90]
                              [y 40]
                              [color RED]
                              [sec-cnt 0]))

(define CIRCLE3-AFT-TICK (new CircleToy%
                              [x 110]
                              [y 80]
                              [color GREEN]
                              [sec-cnt 0]))


(define SQUARE1 (new SquareToy% 
                     [x 375]
                     [y 20]
                     [dir EAST]
                     [speed 10]))

(define SQUARE2 (new SquareToy% 
                     [x 150]
                     [y 222]
                     [dir EAST]
                     [speed 10]))

(define SQUARE3 (new SquareToy% 
                     [x 150]
                     [y 222]
                     [dir WEST]
                     [speed 10]))

(define SQUARE4 (new SquareToy% 
                     [x 30]
                     [y 222]
                     [dir WEST]
                     [speed 10]))

(define SQUARE4-AFT-TICK (new SquareToy% 
                     [x MIN-SQUARE-X]
                     [y 222]
                     [dir EAST]
                     [speed 10]))


(define SQUARE3-AFT-TICK (new SquareToy% 
                              [x 140]
                              [y 222]
                              [dir WEST]
                              [speed 10]))


(define SQUARE1-AFT-TICK (new SquareToy% 
                              [x 380]
                              [y 20]
                              [dir WEST]
                              [speed 10]))

(define SQUARE2-AFT-TICK (new SquareToy% 
                              [x 160]
                              [y 222]
                              [dir EAST]
                              [speed 10]))

(define WORLD1 (new World%
                    [x 150]
                    [y 222]
                    [selected? false]
                    [mouse-x-co ZERO]
                    [mouse-y-co ZERO]
                    [toys (list SQUARE1 CIRCLE1 CIRCLE2 CIRCLE3)]
                    [speed 10]))

(define WORLD2 (new World%
                    [x 150]
                    [y 222]
                    [selected? false]
                    [mouse-x-co ZERO]
                    [mouse-y-co ZERO]
                    [toys (list SQUARE1 CIRCLE2 CIRCLE3)]
                    [speed 10]))

(define WORLD2-SCENE
  (place-image CIRCLE-TOY-RED 110 80 
               (place-image CIRCLE-TOY-GREEN 90 40 
                            (place-image SQUARE-TOY 375 20
                                         (place-image TARGET-CIRCLE 150 222 
                                                      EMPTY-CANVAS)))))


(define WORLD1-AFT-KEY-S (new World%
                              [x 150]
                              [y 222]
                              [selected? false]
                              [mouse-x-co ZERO]
                              [mouse-y-co ZERO]
                              [toys (list SQUARE2 SQUARE1 CIRCLE1 
                                          CIRCLE2 CIRCLE3)]
                              [speed 10]))

(define WORLD1-AFT-KEY-C (new World%
                              [x 150]
                              [y 222]
                              [selected? false]
                              [mouse-x-co ZERO]
                              [mouse-y-co ZERO]
                              [toys (list CIRCLE4 SQUARE1 CIRCLE1 
                                          CIRCLE2 CIRCLE3)]
                              [speed 10]))


(define WORLD1-AFT-TICK (new World%
                    [x 150]
                    [y 222]
                    [selected? false]
                    [mouse-x-co ZERO]
                    [mouse-y-co ZERO]
                    [toys (list SQUARE1-AFT-TICK CIRCLE1-AFT-TICK 
                                CIRCLE2-AFT-TICK CIRCLE3-AFT-TICK)]
                    [speed 10]))

(define NEW-WORLD (new World%
                       [x HALF-CANVAS-WIDTH]
                       [y HALF-CANVAS-HEIGHT]
                       [selected? false]
                       [mouse-x-co ZERO]
                       [mouse-y-co ZERO]
                       [toys empty]
                       [speed 20]))

(define NEW-WORLD-AFT-CLICK (new World%
                                 [x HALF-CANVAS-WIDTH]
                                 [y HALF-CANVAS-HEIGHT]
                                 [selected? true]
                                 [mouse-x-co 205]
                                 [mouse-y-co 257]
                                 [toys empty]
                                 [speed 20]))

(define NEW-WORLD-AFT-UNCLICK (new World%
                                 [x HALF-CANVAS-WIDTH]
                                 [y HALF-CANVAS-HEIGHT]
                                 [selected? false]
                                 [mouse-x-co ZERO]
                                 [mouse-y-co ZERO]
                                 [toys empty]
                                 [speed 20]))


(define NEW-WORLD-AFT-DRAG (new World%
                                 [x 295]
                                 [y 293]
                                 [selected? true]
                                 [mouse-x-co 300]
                                 [mouse-y-co 300]
                                 [toys empty]
                                 [speed 20]))

;_______________________________________________________________________________
;TEST CASES:
(begin-for-test
  
  (check is-world-equal? (send WORLD1 on-tick)
         WORLD1-AFT-TICK
   "World after tick should have moved the square & changed color of 1 circle")
                
  (check is-world-equal? (send WORLD1 on-key "s")
         WORLD1-AFT-KEY-S
         "Should have returned a world with a new square")
  
  (check is-world-equal? (send WORLD1 on-key "c")
         WORLD1-AFT-KEY-C
         "Should have returned a world with a new green circle at target")
    
  (check is-world-equal? (send WORLD1 on-key "e")
         WORLD1
         "Should have same world as key pressed is invalid")
  
  (check is-world-equal? (make-world 20)
         NEW-WORLD
         "A new world with target and center and speed 20 should be created")
  
  (check-equal? (send (send SQUARE1 on-tick) is-toy-equal?
                      SQUARE1-AFT-TICK)
                true
                "The square should stop at the right wall and change direction")
  
  (check-equal? (send (send SQUARE3 on-tick) is-toy-equal?
                                SQUARE3-AFT-TICK)
                true
                "The square should have moved 10 pixes to the left")
  
  (check-equal? (send (send SQUARE4 on-tick) is-toy-equal?
                                SQUARE4-AFT-TICK)
                true
                "The square should have moved 10 pixes to the left")
  
  (check-equal? (send (send SQUARE2 on-tick) is-toy-equal?
                                SQUARE2-AFT-TICK)
                true
                "The square should have moved 10 pixes to the right")
  
  (check is-world-equal? (send NEW-WORLD on-mouse 205 257 MOUSE-CLICK)
         NEW-WORLD-AFT-CLICK
         "The same world with target selected should be returned")
  
  
  (check is-world-equal? (send NEW-WORLD-AFT-CLICK on-mouse 300 300 MOUSE-DRAG)
         NEW-WORLD-AFT-DRAG
         "The world with the target dragged to the new location")
  
  (check is-world-equal? (send NEW-WORLD-AFT-CLICK on-mouse 20 25 MOUSE-UNCLICK)
         NEW-WORLD-AFT-UNCLICK
         "the same world with the target unselected should be retured")
  
  (check-equal? (send WORLD2 on-draw)
                WORLD2-SCENE
                "A world with target & toys drawn on canvas must be retured")
  
  (check-equal? (send NEW-WORLD on-mouse 205 257 "move")
                NEW-WORLD
                "The same world should be retured since mouse event is invalid")
  
  (check-equal? (send SQUARE1 toy-color)
                GREEN
                "the color of the square (green) as a string must be returned")
  
  (check is-world-equal? (send NEW-WORLD on-mouse 30 30 MOUSE-DRAG)
         NEW-WORLD
         "The same world should be returned as target is not selected"))