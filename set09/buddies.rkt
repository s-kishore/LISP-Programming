#lang racket

(require rackunit)
(require 2htdp/universe)   
(require 2htdp/image)   
(require "extras.rkt")
(require "sets.rkt")

(provide World%
         SquareToy%
         make-world
         run
         make-square-toy
         StatefulWorld<%>
         StatefulToy<%>)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS

(define ZERO 0)
(define TWO 2)
(define CANVAS-WIDTH 400)
(define CANVAS-HEIGHT 500)
(define TARGET-RADIUS 10)
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT)) 
(define SQUARE-SIDE 30)

(define TARGET-X-START (/ CANVAS-WIDTH 2))
(define TARGET-Y-START (/ CANVAS-HEIGHT 2))

(define OUTLINE "outline")
(define RED "red")
(define GREEN "green")
(define BLACK "black")
(define ORANGE "orange")

;KEY EVENTS
(define S-KEY "s")

; SQUARE CONSTANTS
(define SQUARE-SIZE 30)
(define SQUARE-HALF-SIZE (/ SQUARE-SIZE 2))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA DEFINITIONS
;; *The Data Definition of World and SquareToy will be defined in corresponding
;; class

;; A WorldMouseEvent is partition of MouseEvent and is one of
;; -- "button-down" (INTERP Mouse's left button is pressed down in the World)
;; -- "drag"        (INTERP Mouse is dragging in the World)
;; -- "button-up"   (INTERP Mouse's pressed button in the World is released)
;; -- other         (INTERP Any other MouseEvent that happened in the World will
;;                          be ignored)
;; TEMPLATE:
;; wme-fn : WorldMouseEvent -> ??
;;(define (wme-fn wme)
;;  (cond
;;    [(mouse=? wme "button-down") ...]
;;    [(mouse=? wme "drag") ...]
;;    [(mouse=? wme "button-up") ...]
;;    [else ...]))

;; A WorldKeyEvent is a partition of KeyEvent and is one of
;; -- "s" (INTERP Pressing n in the World will create a new square toy)
;; -- other (INTERP any other KeyEvent that happened in the World will
;;                  be ignored)
;; TEMPLATE:
;; wke-fn : WorldKeyEvent -> ??
;;(define (wke-fn wke)
;;  (cond
;;    [(key=? wke "s") ...]
;;    [else ...]))

;; a ListOf<SquareToy<%>> is one of 
;; -- empty                             (INTERP This means no square toy 
;;                                              in the World)
;; -- (cons SquareToy<%> ListOf<SquareToy<%>>)(INTERP This means there is a
;;                                              square toy appended to
;;                                              a ListOf<SquareToy<%>> in the
;;                                              World)
;; TEMPLATE:
;; lost-fn : ListOf<SquareToy<%>> -> ??
;;(define (lost-fn lor)
;;  (cond 
;;    [(empty? lost) ...]
;;    [else ... 
;;     (first lost) (lost-fn (rest lost))]))

;; A TargetColorString is partition of ColorString and is one of
;; --"black"
;; --"orange"

;; A SquareToyColorString is partition of ColorString and is one of
;; -- "green"
;; -- "red"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; INTERFACE: StatefulWorld<%>
(define StatefulWorld<%>
  (interface ()
    
    ;; -> Void
    ;; EFFECT: updates this StatefulWorld<%> to the 
    ;;         state that it should be in after a tick.
    on-tick                             
    
    ;; Integer Integer MouseEvent -> Void
    ;; EFFECT: updates this StatefulWorld<%> to the 
    ;;         state that it should be in after the given MouseEvent
    on-mouse
    
    ;; KeyEvent -> Void
    ;; EFFECT: updates this StatefulWorld<%> to the 
    ;;         state that it should be in after the given KeyEvent
    on-key
    
    ;; -> Scene
    ;; Returns a Scene depicting this StatefulWorld<%> on it.
    on-draw 
    
    ;; -> Integer
    ;; RETURN: the x and y coordinates of the target
    target-x
    target-y
    
    ;; -> Boolean
    ;; Is the target selected?
    target-selected?
    
    ;; -> ColorString
    ;; color of the target
    target-color
    
    ;; -> ListOfStatefulToy<%>
    get-toys
    )
  )

;; INTERFACE: StatefulToy<%>
(define StatefulToy<%> 
  (interface ()
    
    ;; Integer Integer MouseEvent -> Void
    ;; EFFECT: updates this StatefulToy<%> to the 
    ;;         state that it should be in after the given MouseEvent
    on-mouse
    
    ;; Scene -> Scene
    ;; Returns a Scene like the given one, but with this  
    ;; StatefulToy<%> drawn on it.
    add-to-scene
    
    ;; -> Int
    toy-x
    toy-y
    
    ;; -> ColorString
    ;; returns the current color of this StatefulToy<%>
    toy-color
    
    ;; -> Boolean
    ;; Is this StatefulToy<%> selected?
    toy-selected?
    )
  )

;; INTERFACE: SquareToyExtras<%>
;; SquareToyExtras<%> is a set of extra methods that the class of SquareToy% 
;; should implement.
(define SquareToyExtras<%>
  (interface ()
    ;; String -> Void
    ;; EFFECT: Update the current color of the SquareToy 
    ;;         with the new color sent.
    set-color
    
    ;; SquareToy<%> -> Void
    ;; EFFECT: Adds SquareToy<%> sent to the ListOfStatefulToy<%> buddies for
    ;;         a given SquareToy<%>.
    add-buddy
    
    ;; SquareToy<%> -> Boolean
    ;; EFFECT: Returns whether the SquareToy is currently intersecting the given
    ;;         SquareToy.
    intersects?
    )
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; World% -- a class that satisfies the StatefulWorld<%> interface.
;; A World is a (new World% 
;;                          [squaretoys ListOfStatefulToy<%>]
;;                          [x PosInt] [y PosInt] [r PosInt]
;;                          [color ColorString]
;;                          [selected? Boolean]
;;                          [x-diff PosInt] [y-diff PosInt])
;; INTERPRETATION:
;; It represents a world, containing some SquareToys, the moving speed of the
;; SquareToys, the target's x and y position, the targets radius,
;; and a boolean of whether the target is selected?, the distance from the 
;; center of target to the mouse pointer
;; EXAMPLES: refer to test-world at end of file.
(define World%
  (class* object% (StatefulWorld<%>) 
    (init-field toys) ; a ListOfStatefulToy<%> -- the list of toys 
    ; that have been generated
    (init-field
     x                         ; the target x position, in pixels, 
     y )                       ; the target y position
    (init-field r)             ; the targets radius
    
    (init-field [color BLACK])         ; the target's color
    (init-field [selected? false])     ; the target's selected? status 
    ; initially false.
    (init-field [x-diff ZERO]  ; x distance from center of target
                [y-diff ZERO]) ; y distance from center of target
    
    ;; private data for objects of this class.
    
    (field [TARGET (circle r OUTLINE color)])   
    ; image for displaying the circle/target
    
    (super-new)
    
    ;; on-tick : -> Void
    ;; EFFECT: updates this World to its state following a tick  
    ;; EXAMPLES: refer to tests below in test-world
    ;; STRATEGY: HOFC
    (define/public (on-tick)
      this)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; in-target? : Integer Integer -> Boolean
    ;; GIVEN: a position of mouse
    ;; RETURNS: a Boolean of true iff the position of the mouse is
    ;;          inside the target's radius.
    ;; EXAMPLES: refer to tests in test-world
    ;; STRATEGY:  Function Composition
    (define/public (in-target? mouse-x mouse-y)
      (<= (+ (sqr (- x mouse-x)) (sqr (- y mouse-y)))
          (sqr r)))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; on-mouse : Integer Integer MouseEvent -> Void
    ;; GIVEN: a pair of mouse position Integers x and y, 
    ;;        and a WorldMouseEvent evt
    ;; EFFECT: Updates this SquareToy to its state following the given
    ;;         MouseEvent.
    ;; EXAMPLES: refer to tests in test-world
    ;; STRATEGY: Structural Decomposition on evt : WorldMouseEvent
    (define/public (on-mouse mx my evt)
      (cond 
        [(mouse=? evt "button-down")
         (if (in-target? mx my)
             (send this mouse-evt-target-world x y mx my 
                   (- x mx) (- y my) true evt )
             (send this mouse-evt-target-world x y 
                   mx my ZERO ZERO false evt))]
        [(mouse=? evt "drag")
         (if selected?
             (send this mouse-evt-target-world (+ mx x-diff) (+ my y-diff)
                   mx my x-diff y-diff true evt)
             (send this mouse-evt-target-world x y
                   mx my ZERO ZERO false evt ))]
        [(mouse=? evt "button-up") 
         (send this mouse-evt-target-world x y mx my ZERO ZERO false evt )]
        [else this]))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; mouse-evt-target-world : Integer Integer Integer Integer
    ;;                          Integer Integer Boolean MouseEvent -> Void
    ;; GIVEN: a pair of target position, a pair of mouse position Integers, 
    ;;        a pair of position that represents the distance from the 
    ;;        center of target to the mouse pointer, a boolean selected? status,
    ;;        and a WorldMouseEvent.
    ;; EFFECT: Updates this SquareToy to its state following the given
    ;;         MouseEvent.
    ;; EXAMPLES: refer to tests in test-world
    ;; STRATEGY: HOFC
    (define/public (mouse-evt-target-world x-loc y-loc mx my 
                                           x-diff-loc y-diff-loc select? evt)
      
      (for-each
       ;; Toy -> Void
       ;; GIVEN: the current SquareToy.
       ;; EFFECT: Updates this SquareToy to its state following the given
       ;;         MouseEvent.
       (lambda (toy)
         (begin
           (send toy on-mouse mx my evt)
           (check-intersections toy) 
           )
         ) toys)
      
      (set! x x-loc) (set! y y-loc) 
      (set! x-diff x-diff-loc) (set! y-diff y-diff-loc)
      (set! selected? select?)
      (if select? 
          (set! color ORANGE)
          (set! color BLACK))
      (if select?
          (set! TARGET (circle r OUTLINE ORANGE))
          (set! TARGET (circle r OUTLINE BLACK))))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; on-key: KeyEvent  -> Void
    ;; Given: the key event
    ;; EFFECT: Updates this SquareToy to its state following
    ;; the given Key event
    ;; Examples: Refer test cases 
    ;; Strategy: Cases on kev: KeyEvent
    (define/public (on-key kev)
      (cond 
        [(key=? kev S-KEY) 
         (create-sqr-toy)]
        [else this]))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; create-sqr-toy ??  -> World%
    ;  Returns: the world with a new square toy with the same center as target
    ; Examples: (send WORLD1 create-sqr-toy) -> WORLD1-AFT-KEY-S
    ; Strategy: Function Composition
    (define/public (create-sqr-toy)
      (set! toys (cons (make-square-toy x y) toys)))  
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; on-draw: -> Scene
    ;; GIVEN: a scene
    ;; RETURNS: a Scene like the given one, but with a new world drawn with
    ;;          updated object perameters.
    ;; EXAMPLES: refer to tests in test-world
    ;; STRATEGY: HOFC
    (define/public (on-draw)
      (local
        ((define scene-with-target 
           (place-image TARGET x y EMPTY-CANVAS)))
        (foldr
         ;; SquareToy Scene -> Scene
         ;; GIVEN: the current Scene
         ;; RETURNS: a Scene like the given one, but with this SquareToy
         ;;          drawn on it.
         (lambda (toy scene)
           (send toy add-to-scene scene))
         scene-with-target
         toys)))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
    ; -> ColorString 
    ; Returns : the color of the target 
    ; Example : (send SQUARE1 target-color) -> BLACK
    ; Strategy: Function Composition
    (define/public (target-color)
      color)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; -> Integer
    ;; RETURNS: the x coordinate of the target
    ;; EXAMPLES: refer to tests in test-world
    ;; STRATEGY: Function Composition
    (define/public (target-x)
      x)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; -> Integer
    ;; RETURNS: the y coordinate of the target
    ;; EXAMPLES: refer to tests in test-world
    ;; STRATEGY: Function Composition
    (define/public (target-y)
      y)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; -> Boolean
    ;; GIVEN: a location on the canvas
    ;; RETURNS: true iff the target is selected.
    ;; EXAMPLE: refer to tests in test-world
    ;; STRATEGY: Function Composition
    (define/public (target-selected?)
      selected?)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; -> ListOfStatefulToy<%>
    ;; RETURNS: the list of SquareToys currently in the world.
    ;; EXAMPLE: refer to tests in test-world
    ;; STRATEGY: Function Composition
    (define/public (get-toys)
      toys)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; check-intersections : ListOfStatefulToy<%> -> Void
    ;; GIVEN: a list of StatefulToy<%>
    ;; EFFECT: Checks all SquareToys in ListOfStatefulToy<%> in the world
    ;;         for intersections.  If there is an intersections the 
    ;;         intersecting SquareToy is added to the buddies list for each
    ;;         intersecting SquareToy.
    ;; STRATEGY: HOFC
    (define/public (check-intersections square-src)
      (for-each
       ;; SquareToy -> Void
       ;; GIVEN: a SquareToy.
       ;; EFFECT: check this SquareToy with the ListOfStatefulToy<%>,
       ;;         and if the given SquareToy is connect to 
       ;;         any SquareToys in the SquareToy list then add the SquareToy
       ;;         to the list.
       (lambda (square-tgt) (when (and
                                   (not (equal? square-src square-tgt))
                                   (send square-src intersects? square-tgt)
                                   (send square-src toy-moving?)
                                   )
                              (begin
                                (send square-src add-buddy square-tgt)
                                (send square-tgt add-buddy square-src)))) toys))
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SquareToy% -- a class that satisfies the StatefulToy<%> interface
;; A SquareToy is a (new SquareToy% [x Integer] [y Integer] 
;;                                  [e PosInt] 
;;                                  [x-diff Integer] [y-diff Integer]
;;                                  [selected? Boolean] 
;;                                  [buddies ListOfStatefulToy<%>])
;;
;; INTERPRETATIONS:
;; This represents a SquareToy, containing the target's x and y position,
;; the Square's edge, the distance from the center of square to mouse 
;; pointer, a selected? status that whether the target is selected?
;; and a buddies that represents a list of square toys that each square 
;; toy is connected to.
;; EXAMPLE:
;; refer to the "SquareToy tests" below
(define SquareToy% 
  (class* object% (StatefulToy<%> SquareToyExtras<%>)
    (init-field
     x               ; x-coordinate of a square toy, in pixels
     y)              ; y-coordinate of a square toy, in pixels
    
    (init-field [e SQUARE-SIDE])      ; the edge of a square toy
    
    (init-field [m-x ZERO]            ; x distance from center of square toy
                [m-y ZERO])           ; y distance from center of square toy
    (init-field [selected? false])    ; the square toy's selected? status-  
    ; initially false. 
    
    (init-field [buddies empty])      ; initialize the list of "buddies" each
    ; square toy is connected to.
    
    (init-field [color GREEN])        ; initialize the color of each square toy
    ; is green.
    
    (init-field [moving? false])
    ; private data for objects of this class 
    ; these can depend on the init-fields.
    
    ;; image for displaying the square toy 
    (field [IMG (square e OUTLINE color)])    
    
    (super-new)
    
    ;; on-mouse: Integer Integer MouseEvent -> Void
    ;; GIVEN: a pair of mouse positions x and y, and a MouseEvent.
    ;; EFFECT: Updates this SquareToy to its state following the given
    ;;         MouseEvent;
    ;; EXAMPLES: refer to tests below in test-squaretoy
    ;; STRATEGY: Structural Decomposition on evt : WorldMouseEvent
    (define/public (on-mouse mx my evt)
      (cond
        [(mouse=? evt "button-down")
         (send this squaretoy-after-button-down mx my)]
        [(mouse=? evt "drag") 
         (send this squaretoy-after-drag mx my)]
        [(mouse=? evt "button-up")
         (send this squaretoy-after-button-up)]
        [else this]))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;; update-squaretoy : Integer Integer Integer Integer Boolean -> Void
    ;; GIVEN: updates to x and y location, updates to x-diff and y-diff 
    ;;         (difference between squaretoy center and mouse click)
    ;;         and the boolean of whether the squaretoy is selected or not.
    ;; EFFECT: Updates this squaretoy with changes in the x,y location, 
    ;;         updates to x-diff and y-diff (difference between squaretoy 
    ;;         center and mouse click), and updates the boolean of whether the
    ;;         squaretoy is selected or not.
    ;; STRATEGY: HOFC 
    (define/public (update-squaretoy x-loc y-loc mx my select?)
      (begin
        (set! x (+ (- x-loc m-x) mx))
        (set! y (+ (- y-loc m-y) my))
        (set! m-x mx)
        (set! m-y my)
        (set! moving? true)
        (set! selected? select?)
        ;(if select? 
            (set-color RED)
            ;(set-color GREEN))  
        (set-buddy)
        (for-each 
         (lambda (buddy)
           (send buddy drag-buddy (- x x-loc) (- y y-loc) mx my))
         buddies)
        ))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;; drag-buddy: Integer Integer Integer Integer -> Void
    ;; GIVEN:x distance from center of square toy,y distance from center of 
    ;;       square toy, x-coordinate and y-coordinate of mouse position
    ;; EFFECT: buddy dragged to a new position, change on position of each 
    ;;         square toy is same as its parent square toy 
    ;; EXAMPLES: see tests
    ;; STRATEGY: Function Composition
    (define/public (drag-buddy bx by mx my)
      (begin
        (when (not (send this in-squaretoy? mx my))
          (begin
            (set! x (+ x bx))
            (set! y (+ y by))
            (set! moving? true)
            ))
        ))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;; set-buddy: -> Void
    ;; EFFECT: change square toy's color into red and make them selected
    ;; EXAMPLES: see tests
    (define/public (set-buddy)
      (for-each
       (lambda (buddy) 
         (begin
           (set! selected? true)
           (send buddy set-color RED)))
       buddies))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; squaretoy-after-button-down : Integer Integer -> Void
    ;; GIVEN: the location of a mouse position of Integers x and y
    ;; EFFECT: Updates the squaretoy that should follow this one after a button
    ;;          down at the given location
    ;; DETAILS: If the event is inside the squaretoy, returns a squaretoy just
    ;;          like this squaretoy, except that it is selected and distance to
    ;;          mouse position is saved in x-diff and y-diff.
    ;;          Otherwise returns the squaretoy unchanged.
    ;; EXAMPLES: refer to tests below in test-squaretoy
    ;; STRATEGY: function composition
    (define/public (squaretoy-after-button-down mx my)
      (if (send this in-squaretoy? mx my)
          (begin
            (set! m-x mx)
            (set! m-y my)
            (set! selected? true)
            (set-color RED)
            (set-buddy))
          this))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;; squaretoy-after-drag : Integer Integer -> Void
    ;; GIVEN: the location of a mouse event
    ;; EFFECT: Updates the squaretoy that should follow this one after a 
    ;; drag at the given location 
    ;; DETAILS: if squaretoy is selected, move the squaretoy to 
    ;;          the mouse location, otherwise ignore.
    ;; EXAMPLES: see tests below in test-squaretoy
    ;; STRATEGY: Function Composition
    (define/public (squaretoy-after-drag mx my)
      (if selected?
          (update-squaretoy x y mx my true)
          this))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; squaretoy-after-button-up : -> Void
    ;; EFFECT: Updates the squaretoy that should follow this one after 
    ;;          a button-up.
    ;; DETAILS: button-up unselects all squaretoy
    ;; EXAMPLES: see tests below in test-squaretoy
    ;; STRATEGY: function composition
    (define/public (squaretoy-after-button-up)
      (begin
        (set! selected? false)
        (set-color GREEN)
        (set! moving? false)
        (for-each (lambda (buddy)
                    (begin 
                      (set! selected? false)
                      (set! moving? false)
                      (set-color GREEN)
                      ))
                  buddies))) 
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; add-to-scene : Scene -> Scene
    ;; GIVEN: a scene
    ;; RETURNS: a scene like the given one, but with this squaretoy painted
    ;;          on it.
    ;; EXAMPLES: see tests below in test-squaretoy
    ;; STRATEGY: function composition
    (define/public (add-to-scene scene)
      (place-image IMG x y scene))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; on-key : KeyEvent -> Void
    ;; GIVEN: A KeyEvent
    ;; EFFECT: Updates this squaretoy to its state following the given
    ;;         KeyEvent.
    ;; DETAILS: a squaretoy ignores key events
    ;; EXAMPLES: see tests below in test-squaretoy
    ;; STRATEGY: Function Composition
    (define/public (on-key kev)
      void)  
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; toy-x : -> Integer
    ;; RETURNS: the x coordinate of the squaretoy
    ;; EXAMPLES: refer to tests in test-squaretoy
    ;; STRATEGY: Function Composition
    (define/public (toy-x)
      x)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; toy-y : -> Integer
    ;; RETURNS: the y coordinate of the squaretoy
    ;; EXAMPLES: refer to tests in test-squaretoy
    ;; STRATEGY: Function Composition
    (define/public (toy-y)
      y)
    
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; toy-moving? : -> Boolean
    ;; RETURNS: true if the square toy is moving 
    ;; EXAMPLES: refer to tests in test-squaretoy
    ;; STRATEGY: Function Composition
    (define/public (toy-moving?)
      moving?)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; in-squaretoy? Integer Integer : -> Boolean
    ;; GIVEN: a location x and y on the canvas as Integers
    ;; RETURNS: true iff the location is inside this squaretoy.
    ;; EXAMPLES: refer to tests in test-squaretoy
    ;; STRATEGY: Function Composition
    (define/public (in-squaretoy? mx my)
      (and (<= (abs (- x mx)) (/ e TWO))
           (<= (abs (- y my)) (/ e TWO))))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; toy-selected? : -> Boolean
    ;; RETURNS: true if the squaretoy is selected
    ;; EXAMPLE: refer to tests in test-squaretoy
    (define/public (toy-selected?) selected?)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; set-color : String -> Void
    ;; GIVEN: The New squaretoy's color.
    ;; EFFECT: switches the squaretoy color and updates the IMG being drawn.
    ;; EXAMPLES: See tests below in color-tests.
    (define/public (set-color color-loc)
      (begin
        (set! color color-loc)
        (set! IMG (square e OUTLINE color))))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; toy-color : -> String
    ;; RETURNS: either "red" or "green", depending on the color in
    ;; which this squaretoy would be displayed if it were displayed now.
    ;; EXMAPLE: 
    ;;  (send (squaretoy with state color of "green") get-color) -> "green"
    ;; STRATEGY: Function Composition
    (define/public (toy-color) color)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; add-buddy : SquareToy<%> -> Void
    ;; GIVEN: A SquareToy to add to this SquareToys buddies list.
    ;; EFFECT: Updates the list of buddies for this SquareToy to include rect.
    ;; EXAMPLE: 
    ;;   (send squaretoy(with a empty buddies list) add-buddy new-squaretoy)
    ;;    -> (list new-squaretoy)
    ;; STRATEGY: Function Composition
    (define/public (add-buddy squaretoy)
      (set! buddies (set-cons squaretoy buddies)))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; intersects-helper-fn : Integer Integer -> Boolean
    ;; GIVEN: An x and y position of a squaretoy other than this squaretoy
    ;;        to check for intersections between the two.
    ;; RETURNS: True iff there is an intersection (overlap)
    ;;          between the two squaretoys.
    ;; EXAMPLE: (send squaretoy (at pos 100 100) 120 110) -> True
    ;; STRATEGY: Function Composition
    (define/public (intersects-helper-fn other-x other-y)
      (and (<= (abs (- x other-x)) SQUARE-SIDE) 
           (<= (abs (- y other-y)) SQUARE-SIDE)))
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; intersects-helper-fn : SquareToy<%> -> Boolean
    ;; GIVEN: A SquareToy other than this SquareToy
    ;;        to check for intersections between the two.
    ;; RETURNS: True iff there is an intersection (overlap)
    ;;          between the two SquareToys.
    ;; EXAMPLE: (send rect (at pos 100 100) rect-other (at pos 120 110))
    ;;           -> True
    ;; Strategy: function combination 
    (define/public (intersects? other-r)
      (intersects-helper-fn
       (send other-r toy-x)
       (send other-r toy-y)))
    
    (define/public (get-buddy)
      buddies)
    )
  ) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; make-world : -> World%
;; GIVEN: no arguments
;; RETURNS: A World% with no squares
;; EXAMPLES: refer to tests below
;; STRATEGY: Function Composition 
(define (make-world)
  (new World% 
       [toys empty]
       [x TARGET-X-START]
       [y TARGET-Y-START]
       [r TARGET-RADIUS]
       [selected? false]
       [color BLACK]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; make-square-toy : PosInt PosInt -> SquareToy%
;; GIVEN: an x and a y position
;; RETURNS: an object representing a square toy at the given position
;; EXAMPLES: refer to tests below
;; STRATEGY: Function Composition
(define (make-square-toy target-x target-y)
  (new SquareToy% 
       [x target-x]
       [y target-y]
       [e SQUARE-SIDE]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; run : PosNum -> World%
;; GIVEN: a frame rate (in seconds/tick).
;; EFFECT: creates and runs a world that runs at the given rate.
;; RETURNS: the final world.
;; EXAMPLE: (run 0.25)
;; STRATEGY: Function Composition
(define (run rate) 
  (big-bang (make-world)
            (on-tick
             ;World -> World
             ;GIVEN: Current World
             ;RETURNS: World after a tick
             (lambda (w) (send w on-tick) w)
             rate)
            (on-draw
             ;World -> Scene
             ;GIVEN: Current World
             ;RETURNS: Scene after the last tick update
             (lambda (w) (send w on-draw)))
            (on-key
             ;World -> World
             ;GIVEN: Current World
             ;RETURNS: World after a key event updates.
             (lambda (w kev) (send w on-key kev) w))
            (on-mouse
             ;World -> World
             ;GIVEN: Current World
             ;RETURNS: World after a mouse event updates.
             (lambda (w m-x m-y evt) (send w on-mouse m-x m-y evt) w))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Test Constants 
(define test-unselected-squaretoy 
  (new SquareToy% 
       [x 100][y 100][e SQUARE-SIDE][selected? false]))

(define test-selected-squaretoy 
  (new SquareToy% 
       [x 100][y 100][e SQUARE-SIDE][m-x 105][m-y 105][selected? true]))

(define test-selected-squaretoy1 
  (new SquareToy% 
       [x 105][y 105][e SQUARE-SIDE][m-x 105][m-y 105][selected? true]))

(define test-selected-squaretoy-after-drag 
  (new SquareToy% 
       [x 105][y 115][e SQUARE-SIDE][m-x 110][m-y 120][selected? true]))


(define test-selected-squaretoy-buddy11 
  (new SquareToy% 
       [x 55][y 65][e SQUARE-SIDE][m-x 60][m-y 70][selected? true]
       [buddies (list empty)][color RED][moving? true]))

(define test-selected-squaretoy-buddy1 
  (new SquareToy% 
       [x 100][y 100][e SQUARE-SIDE][m-x 95][m-y 95][selected? true]
       [buddies (list test-selected-squaretoy-buddy11)]
       [color RED][moving? true]))  

(define test-selected-squaretoy-buddy22 
  (new SquareToy% 
       [x 55][y 65][e SQUARE-SIDE][m-x 60][m-y 70][selected? false]
       [buddies (list empty)][color RED][moving? false]))

(define test-selected-squaretoy-buddy22-after-button-down 
  (new SquareToy% 
       [x 55][y 65][e SQUARE-SIDE][m-x 60][m-y 70][selected? true]
       [buddies (list empty)][color RED][moving? false]))

(define test-selected-squaretoy-buddy22-after-button-up
  (new SquareToy% 
       [x 55][y 65][e SQUARE-SIDE][m-x 60][m-y 70][selected? false]
       [buddies (list empty)][color GREEN][moving? false])) 

(define test-unselected-squaretoy-buddy2 
  (new SquareToy% 
       [x 100][y 100][e SQUARE-SIDE][m-x 95][m-y 95][selected? false]
       [buddies (list test-selected-squaretoy-buddy22)]
       [color RED][moving? true]))  

;(define test-selected-squaretoy-buddy1-after-button-up 
;  (new SquareToy% 
;       [x 100][y 100][e SQUARE-SIDE][m-x 95][m-y 95][moving? false]
;       [buddies (list test-selected-squaretoy-buddy11-after-button-up)]
;       [color GREEN][selected? false]))

(define test-selected-squaretoy-buddy11-after-drag 
  (new SquareToy% 
       [x 80][y 100][e SQUARE-SIDE][m-x 60][m-y 70][selected? true]
       [buddies (list empty)]))

(define test-selected-squaretoy-buddy1-after-drag 
  (new SquareToy% 
       [x 125][y 135][e SQUARE-SIDE][m-x 120][m-y 130][selected? true]
       [buddies (list test-selected-squaretoy-buddy11-after-drag)]))

; (define test-scene 
;   (send test-selected-squaretoy-2 add-to-scene EMPTY-CANVAS))
;; Tests for SquareToy%

(begin-for-test
  (send test-unselected-squaretoy on-mouse 110 115 "button-down")
  (check-equal?
   (send test-unselected-squaretoy toy-selected?)
   true
   "the square toy should be selected.")
  
  (send test-unselected-squaretoy on-mouse 130 130 "button-up")
  
  (check-equal?
   (send test-unselected-squaretoy toy-selected?) 
   false
   "the square toy should not be selected.")
  
  (send test-unselected-squaretoy on-mouse 100 100 "button-up")
  
  (check-equal?
   (send test-unselected-squaretoy toy-selected?)
   false
   "the square toy should not be selected after a 
   button-up occurs in the selection area.")
  
  (send test-unselected-squaretoy-buddy2 on-mouse 95 95 "button-down")
   
  (check-equal?
   (send test-unselected-squaretoy-buddy2 get-buddy)
   (list test-selected-squaretoy-buddy22)
   "the square toy should not be selected after a 
   button-up occurs in the selection area.")  
  
  (check-equal?
   (send test-selected-squaretoy-buddy1 on-mouse 95 95 "button-up")
   (void)
   "the square toy should not be selected after a 
   button-up occurs in the selection area.")
    
  (check-equal?
   (send test-selected-squaretoy-buddy11 toy-moving?)
   true
   "the square toy should not be selected after a 
   button-up occurs in the selection area.")
    
  (send test-selected-squaretoy on-mouse 110 120 "drag")
  
  (check-equal?
   (send test-selected-squaretoy toy-x)
   (send test-selected-squaretoy-after-drag toy-x)
   "the square toy should have a x position of 105 after drag")
  
  (check-equal?
   (send test-selected-squaretoy toy-y)
   (send test-selected-squaretoy-after-drag toy-y)
   "the square toy should have a y position of 115 after drag")
  
   (send test-selected-squaretoy-buddy1 on-mouse 120 300 "drag")
      (check-equal?
          (send test-selected-squaretoy-buddy1-after-drag get-buddy)
          (list test-selected-squaretoy-buddy11-after-drag))  
  )
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; testing World class: 
(define world1 (make-world))
(define world2 (send world1 on-key "s"))
(define world3 (new World% 
                    [toys empty] 
                    [x 100][y 100]
                    [r TARGET-RADIUS]))
 

(define world-for-test (new World% 
                            [toys (list test-selected-squaretoy)]
                            [x TARGET-X-START][y TARGET-Y-START]
                            [r TARGET-RADIUS]
                            [color BLACK]
                            [selected? false]))

(define world-for-intersection (new World%
                                    [toys (list test-selected-squaretoy
                                                test-selected-squaretoy1)]
                                    [x TARGET-X-START][y TARGET-Y-START]
                                    [r TARGET-RADIUS]
                                    [color BLACK][selected? false]))
(define world-on-tick-test 
  (new World% 
       [toys (list test-selected-squaretoy)]
       [x TARGET-X-START][y TARGET-Y-START][r TARGET-RADIUS]
       [color BLACK][selected? false]))

(define selected-world-for-test 
  (new World% 
       [toys (list test-selected-squaretoy)]
       [x TARGET-X-START][y TARGET-Y-START][r TARGET-RADIUS]
       [color ORANGE][selected? true]))

(define drag-world-for-test (new World% 
                                 [toys (list test-selected-squaretoy)]
                                 [x 200][y 350][r TARGET-RADIUS]))

(define new-test-selected-squaretoy 
  (new SquareToy% 
       [x 100][y 100][e SQUARE-SIDE][selected? true]))

(define world-for-test-new (new World% 
                                [toys (list new-test-selected-squaretoy)]
                                [x TARGET-X-START][y TARGET-Y-START]
                                [r TARGET-RADIUS]))

(define test-world-scene (send world-for-test-new on-draw))
 
;; Tests for World% 
(begin-for-test
  
  (check-equal?
   (send world-for-intersection mouse-evt-target-world 5 50 100 100 1 1 true "drag")
    (void))
 ;; x-loc y-loc mx my x-diff-loc y-diff-loc select? evt
  ;; target test
  (check-not-equal?
   (send world1 mouse-evt-target-world 5 50 1 1 1 1 true "drag")
   world1
   "the target should at west edge.")
  
  (check-not-equal?
   (send world1 mouse-evt-target-world 395 50 1 1 1 1 true "drag")
   world1
   "the target should at east edge.")
  
  (check-not-equal?
   (send world1 mouse-evt-target-world 50 5 1 1 1 1 true "drag")
   world1
   "the target should at north edge.")
  
  (check-not-equal?
   (send world1 mouse-evt-target-world 50 495 1 1 1 1 true "drag")
   world1
   "the target should at south edge.")
  
  (check-not-equal?
   (send world1 mouse-evt-target-world 0 0 1 1 1 1 true "drag")
   world1
   "the target should at northwestern corner")
  
  (check-not-equal?
   (send world1 mouse-evt-target-world 400 500 1 1 1 1 true "drag")
   world1
   "the target should at northeastern corner")
  
  (check-not-equal?
   (send world1 mouse-evt-target-world 0 500 1 1 1 1 true "drag")
   world1
   "the target should at southwestern corner")
  
  
  (send world-on-tick-test on-tick)
  
  (check-equal?
   (send world-on-tick-test target-x) 
   (send world-for-test target-x)
   "the target position should not change.")
  
  
  (send world-on-tick-test on-tick)

 
 ;(define world-test-on-mouse world-on-tick-test)
  
  (send world-on-tick-test on-mouse 0 0 "button-down")
  (check-equal?
   (send world-on-tick-test target-selected?)
   false
   "The target should not be selected ;after button-down on target position.")
  
  (check-equal?
   (send world3 on-key "s")
   (void)
   "The result should be void.")
  
  (send world-on-tick-test on-mouse 
        (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2) "button-down")
  (check-equal?
   (send world-on-tick-test target-selected?)
   true
   "The target should be selected after button-down on target position.")
  
  (send world-on-tick-test on-mouse 200 350 "drag")
  (check-equal?
   (send world-on-tick-test target-x)
   (send drag-world-for-test target-x)
   "The target should be dragged to the new x position 200.")
  
  (check-equal?
   (send world-on-tick-test target-y)
   (send drag-world-for-test target-y)
   "The target should be dragged to the new y position 200.")
  
  (send world-on-tick-test on-mouse
        (/ CANVAS-WIDTH 2) (/ CANVAS-HEIGHT 2) "button-up")
  (check-equal?
   (send  world-on-tick-test target-selected?)
   (send world-for-test target-selected?)
   "The target should be unselected.")
  
  
  
  (send world-on-tick-test on-mouse 100 350 "drag")
  (check-equal?
   (send world-on-tick-test target-x)
   (send world-for-test target-x)
   "The target should not be dragged if unselected.")
  (send world-on-tick-test on-mouse 200 350 "leave")
  (check-equal?
   (send world-on-tick-test target-x)
   (send world-for-test target-x)
   "The target should not change if an unused mouse event is run.")
  
  (send test-selected-squaretoy on-mouse 110 120 "leave")
 
 (check-equal?
  (send test-selected-squaretoy toy-x)
  (send test-selected-squaretoy toy-x)
  "the squaretoy x position should not change after a leave mouse event.")
  
  ;;"key event test"
  
  (send test-selected-squaretoy on-key "k")
  (check-equal?
   (send test-selected-squaretoy toy-selected?)
   false
   "The target selected? value should not change on a key event.")
 
  (send world-for-test on-key "k")
  (check-equal?
   (send world-for-test target-selected?)
   false
   "The target selected? value should not change on a key event.")
  
  (check-equal?
   (send (send world-for-test on-key "k") target-x)
   (send world-for-test target-x)
   "The target x position should not change on a key event.")
  
  (check-equal?
   (send (send world-for-test on-key "k") target-y)
   (send world-for-test target-y)
   "The target y position should not change on a key event.")
  
  ;get-toys test
  (check-equal?
   (send world-for-test get-toys) 
   (list test-selected-squaretoy)
   "The target should return a (list test-selected-squaretoy).")
  
  (check-equal?
   (send world-for-test-new on-draw) 
   test-world-scene
   "The test scenes should be equal."))

;; Tests for color
(begin-for-test
  (check-equal?
   (send test-selected-squaretoy toy-color)
   GREEN
   "square toy's color should be green")
  (check-equal?
   (send selected-world-for-test target-color)
   ORANGE
   "The target's color should be orange"))