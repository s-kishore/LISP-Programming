;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname rectangle) (read-case-sensitive #t) (teachpacks ((lib "image.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ((lib "image.rkt" "teachpack" "2htdp")))))
(require 2htdp/universe)
(require rackunit)
(require "extras.rkt")
(require 2htdp/universe)
(require rackunit/text-ui)

; Draggable rectangle
; is a rectangle which can be dragged with the mouse. 
; button-down to select, drag to move, bottom-up to release. 

; start with (main 0)
; run with (run 0)

(provide run
         initial-world
         world-x
         world-y
         world-selected?
         world-after-mouse-event)
 

;_______________________________________________________________________________

; MAIN FUNCTION
; run : Any -> World
; GIVEN: any value
; EFFECT: ignores its argument and starts the interactive program.
; RETURNS: the final state of the world.

(define (run x)
  (big-bang (initial-world x)
            (on-mouse world-after-mouse-event)
            (to-draw create-world)))

;__________________________________________________________________________
;CONSTANTS 

;Constants for the canvas

(define CANVAS-WIDTH 400)
(define CANVAS-HEIGHT 300)
(define CANVAS-X-CENTER (/ CANVAS-WIDTH 2))
(define CANVAS-Y-CENTER (/ CANVAS-HEIGHT 2))
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))

;Constants for the rectange
(define RECT-WIDTH 100)
(define RECT-HEIGHT 60)
(define OUTLINE "outline")
(define SOLID "solid")
(define GREEN-COLOR "green")
(define HALF-RECT-WIDTH (/ RECT-WIDTH 2))
(define HALF-RECT-HEIGHT (/ RECT-HEIGHT 2))

;Constants for the circle 
(define CIRCLE-RAD 5)
(define NO-CIRCLE-RAD 0)
(define RED-COLOR "red")

;Constants for mouse events
(define MOUSE-BTN-DOWN "button-down")
(define MOUSE-BTN-UP "button-up")
(define MOUSE-DRAG "drag")

;Image constants

(define SOLID-RECT (rectangle RECT-WIDTH RECT-HEIGHT SOLID GREEN-COLOR))
(define OUTLINE-RECT (rectangle RECT-WIDTH RECT-HEIGHT OUTLINE GREEN-COLOR))
(define CIRCLE (circle CIRCLE-RAD SOLID RED-COLOR))

;Misc variables
(define ZERO 0)


;____________________________________________________________________________

;DATA DEFINITION

(define-struct 
          world (x y selected? mx my))

; A make-world is a (make-world Integer Integer Boolean Integer Integer)
; Interpretation:
; rect-x    gives the x-coordinate of the center of the rectangle
; rect-y    gives the y-coordinate of the rectangle
; selected? decribes whether the rectangle is selected by the mouse
; mx        gives the x-coordinate of the mouse event
; my        gives the y-coordinate of the mouse event

; TEMPLATE:
; world-fn : World -> ?
; (define (world-fn w)
;  (..
;    (world-x-pos w)
;    (world-y-pos w)
;    (world-selected? w)
;    (world-mx w)
;    (world-my w))

;; A MouseEvent can be any of the following and its effetcs on the world are
;; give next to each of them. 

;; -- "button-down"   selects the cat if clicked on a cat
;; -- "drag"          drags the cat if is selected already
;; -- "button-up"     unselects the cat if it was seleted already by button down
;; -- any other event ignore

;; mouseevent-fn : MouseEvent -> ??
;; (define (mouseevent-fn mev)
;;   (cond
;;     [(mouse=? mev "button-down")...]
;;     [(mouse=? mev "drag")...]
;;     [(mouse=? mev "button-up")...]
;;     [else...]))

;; EXAMPLES:

; rectangle is not selected
; (make-world CANVAS-X-CENTER CANVAS-Y-CENTER false 0 0)

; rectangle is selected
; (make-world CANVAS-X-CENTER CANVAS-Y-CENTER true 55 55)

; the x-coordinate of the rectangle
; (world-x (make-world CANVAS-X-CENTER CANVAS-Y-CENTER false))

; the y-coordinate of the rectangle
; (world-y (make-world CANVAS-X-CENTER CANVAS-Y-CENTER true))

; Selected? function
; (world-selected? (make-world CANVAS-X-CENTER CANVAS-Y-CENTER true 55 55))
; (world-selected? (make-world CANVAS-X-CENTER CANVAS-Y-CENTER false 0 0))

;Test Case variables
(define rect-unselected-at-50 (make-world 150 150 false 0 0))
(define rect-selected-at-50 (make-world 150 150 true 0 0))

; END OF DATA DEFINITIONS
;_____________________________________________________________________________

;initial-world : Any -> World
;  GIVEN: any value
; RETURNS: the initial world.
; EFFECTS: Ignores its argument.
;STRATEGY: Function Composition

(define  (initial-world x)
  (make-world CANVAS-X-CENTER CANVAS-Y-CENTER false ZERO ZERO))
;_____________________________________________________________________________
; render-world-clicked : World Integer Integer -> World
; GIVEN:    a world and the co ordinates of the mouse click
; RETURNS:  the world following a mouse click (button down) event
;           if the click is within the rectangle, returns a outlined rectangle
;           and a red circle in the place where mouse click occured
; STRATEGY: Structural Decomposition on w:World

(define (render-world-clicked w xco yco)
  (if (validate-click w xco yco)
      
      (make-world (world-x w) 
                  (world-y w) 
                  true 
                  xco 
                  yco 
                  )
    w))

; EXAMPLES:
; for a click that happens within the rectangle 
; render-world-clicked (make-world 50 50 false 55 55)
;
; for a click that happens outside the rectangle
; render-world-clicked (make-world 50 50 false 200 125)

;_____________________________________________________________________________
; validate-click : World Integer Integer -> Boolean
; GIVEN:    a world and the co ordinates of the mouse click
; RETURNS:  a boolean, true if the given coordinates are within the rectangle
;           else false
; STRATEGY: Structural Decomposition on w:World

(define (validate-click w xco yco)
  (and
   (and 
       (<= xco (+ (world-x w) HALF-RECT-WIDTH))
       (>= xco (- (world-x w) HALF-RECT-WIDTH)))
   (and 
       (<= yco (+ (world-y w) HALF-RECT-HEIGHT))
       (>= yco (- (world-y w) HALF-RECT-HEIGHT)))))
    
; EXAMPLES:
; validating a click made inside the rectangle 
; (validate-click (make-world 50 50 false 0 0) 55 55)

; validating a click made outside the rectangle 
; (validate-click (make-world 50 50 false 0 0) 01 55)

;_____________________________________________________________________________
; render-world-dragged : World Integer Integer -> Boolean
; GIVEN:    a world and the co ordinates of the mouse after drag
; RETURNS:  the world following a mouse drag event
;           redraws the world with the rectangle in the new positioned where
;           it is dragged to.

; STRATEGY: Function composition

(define (render-world-dragged w xco yco)
  (if (world-selected? w) 
      
      (render-world-dragged-helper w xco yco)
      
      w
      ))

; EXAMPLES: 
; (render-world-dragged rect-selected-at-50 300 200)
; (render-world-dragged rect-selected-at-50 10 15)
;_____________________________________________________________________________
; render-world-dragged : World Integer Integer -> Boolean
;    GIVEN: a world and the co ordinates of the mouse click
;  RETURNS: a boolean, true if the given coordinates are within the rectangle
;           else false
; STRATEGY: Structural Decomposition on w:World

(define (render-world-dragged-helper w xco yco)
  (make-world (+ (world-x w) (- xco (world-mx w) ))
              (+ (world-y w) (- yco (world-my w) )) 
              true
              xco 
              yco))

; EXAMPLES:
; (render-world-dragged-helper rect-selected-at-50 300 200)
; (render-world-dragged-helper rect-selected-at-50 10 15)
;_____________________________________________________________________________
; render-world-released : World Integer Integer -> World
; GIVEN:    a world and the co ordinates of the mouse unclick (button up)
; RETURNS:  the world after button up event.
; STRATEGY: Structural Decomposition on w:World

(define (render-world-released w xco yco)
  (make-world (world-x w)
              (world-y w)
               false
               ZERO
               ZERO))

; EXAMPLES:
; render-world-released rect-selected-at-50 50 50)
; render-world-released rect-selected-at-50 0 200)

;_____________________________________________________________________________
; world-after-mouse-event : World Integer Integer MouseEvent -> World
; GIVEN: a world, current mouse coordinates and the mouse event
; RETURNS: the world that follows the given mouse event.
; STRATEGY: Cases on MouseEvent


(define (world-after-mouse-event w xco yco mevent)
    (cond 
    [(mouse=? mevent MOUSE-BTN-DOWN)  (render-world-clicked  w xco yco)]
    [(mouse=? mevent MOUSE-BTN-UP)    (render-world-released w xco yco)]
    [(mouse=? mevent MOUSE-DRAG)      (render-world-dragged  w xco yco)]
    [ else w]
    ))
  
; EXAMPLES:
; when mouse button down (clicked)
; (world-after-mouse-event (make-world 50 50 false 0 0) 55 48 "button-down")
; (world-after-mouse-event (make-world 50 50 false 0 0) 10 200 "button-down")   

;_____________________________________________________________________________
; create-world : World Integer Integer -> World
; GIVEN:    a world and the co ordinates of the mouse unclick (button up)
; RETURNS:  the world after button up event.
; STRATEGY: Structural Decomposition on w:World

(define (create-world w)
  (if (world-selected? w)
      (place-image OUTLINE-RECT 
                   (world-x w)
                   (world-y w)
                   (place-image CIRCLE 
                                (world-mx w) 
                                (world-my w) 
                                EMPTY-CANVAS))
      
      (place-image SOLID-RECT 
                   (world-x w)
                   (world-y w)
                   EMPTY-CANVAS)))

; EXAMPLES:

; A world with unselected rectangle
; (create-world (make-world 200 150 false 0 0))

; A world with selected rectangle
; (create-world (make-world 200 150 true 215 160))

; TEST SUITE:
  ; A rectangle at points (50, 50) which is not selected
  (define rect-at-50-50 (make-world 50 50 false 0 0))
  ; A rectangle at points (50, 50) which is selected
  (define rect-selected-at-50-50 (make-world 50 50 true 60 55))

(define-test-suite tests-for-rectangle

;; TEST CASES FOR MOUSE EVENTS:
  
  ;Test case for mouse click inside the rectangle 
  (check-equal? (world-after-mouse-event  rect-at-50-50 55 48 "button-down") 
                (make-world 50 50 #t 55 48)
                "Incorrect output")
  ;Test case for mouse click outside the rectangle 
  (check-equal? (world-after-mouse-event rect-at-50-50 10 200
                                         "button-down") 
                (make-world 50 50 #f 0 0)
                "Incorrect output")
  ;Test case for mouse drag performed on the rectangle 
  (check-equal? (world-after-mouse-event rect-selected-at-50-50 150 200 "drag")
                (make-world 140 195 true 150 200)
                "Incorrect output")
  ;Test case for mouse drag performed outside the rectangle 
  (check-equal? (world-after-mouse-event rect-at-50-50 150 200 "drag")
                (make-world 50 50 false 0 0)
                "Incorrect output")
  ;Test case for mouse button up performed on the rectangle 
  (check-equal? (world-after-mouse-event rect-selected-at-50-50 150 200 
                                         "button-up")
                (make-world 50 50 false 0 0)
                "Incorrect output")
  ;Test case for mouse drag performed outside the rectangle 
  (check-equal? (world-after-mouse-event rect-at-50-50 150 200 "button-up")
                (make-world 50 50 false 0 0)
                "Incorrect output")
  ;Test case for mouse event other than click unclick and drag
  (check-equal? (world-after-mouse-event rect-at-50-50 150 200 "move")
                (make-world 50 50 false 0 0)
                "Incorrect output")
;; Test case for initial-world
  (check-equal? (initial-world 5) (make-world 200 150 false 0 0)
                "Incorrect output")
  
;;Test case for create-world function
   ; Test for selected rectangle
  
  (check-equal? (create-world (make-world 200 150 true 215 160))
                (place-image OUTLINE-RECT 200 150 
                             (place-image CIRCLE 
                                215 
                                160 
                                EMPTY-CANVAS))
                "Incorrect output")
  
    ; Test for unselected rectangle
  
  (check-equal? (create-world (make-world 200 150 false 215 160))
                (place-image SOLID-RECT 200 150 EMPTY-CANVAS)
                "Incorrect output"))
;_______________________________________________________________________________

(run-tests tests-for-rectangle)
                                             

