;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname trees) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ())))
;;trees
;;Hitting "t" at any time creates a new root node in the center of the top of
;;the canvas
;;Hitting "n" while a node is selected adds a new son, whose center has an
;;x-coordinate two square-lengths to the left of the center of the currently 
;;leftmost son, and a y-coordinate 3 square-lengths down from the center of the
;;parent. If a selected node ever moves into a position so that there is no 
;;room for the son, it appears as red solid rather than green, and "n"
;;has no effect. 
;;The first son of a node appears 3 square-lengths down
;;and directly beneath the node. There is room for a new son if it would be
;;placed with the whole square entirely within the canvas. Note that a node
;;should turn red at the same instant that its vertical line disappears off the
;;left edge of the screen
;;Hitting "d" while a node is selected deletes the node and its whole subtree
;;Hitting "u" (whether a node is selected or not) deletes every node whose
;;center is in the upper half of the canvas. (If a node is deleted, all of
;;its children are also deleted.)


(require rackunit)
(require "extras.rkt")
(require 2htdp/universe)
(require 2htdp/image)

(provide
 initial-world 
 run
 world-after-mouse-event
 world-after-key-event
 world-to-roots
 node-to-center
 node-to-sons
 node-to-selected? )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;struct for posn
;(define-struct posn (x y))
;;a Posn is a (make-posn Real Real)
;;x is the x coordinate of the point
;;y is the y coordinate of the point

;;destructor template:
;;posn-fn: Posn -> ?
;;(define (posn-fn p)
;;(...(posn-x p)
;;    (posn-y p)))

(define-struct node (center selected? sons))
;;a Node is a (make-node Posn Boolean Tree)
;;Posn is the center point of the node
;;selected? says whether the node is selected or not
;;sons is the list of nodes(tree) which are the node's sons

;;destructor template:
;;node-fn: Node -> ?
;;(define (node-fn n)
;;(...(node-posn n)
;;    (node-selected? n)
;;    (lon-fn (node-tree n))))

;a ListOf<Node> (LON) is one of
;--empty
;--(cons node LON)

;;lon-fn:LON ->
;;(define (lon-fn lon)
;;  (cond
;;    [(empty? lon) ...]
;;    [else (... (node-fn(first lon))
;;               (lon-fn(rest lon)))]))

;;a Tree is a ListOf<Node>

;;World Struct
(define-struct world (tree))
;;A World is a (make-world Tree)
;;tree is the list of nodes that are in the world

;;template:
;(define (world-fn w)
;  (... (world-tree))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Constants 
(define NODE-LENGTH 20)
(define NODE-COLOR "green")
(define ERROR-COLOR "red")
(define BLUE-COLOR "blue")

(define SOLID-GREEN-SQUARE (square NODE-LENGTH "solid" NODE-COLOR))
(define OUTLINE-GREEN-SQUARE (square NODE-LENGTH "outline" NODE-COLOR))
(define SOLID-RED-SQUARE (square NODE-LENGTH "solid" ERROR-COLOR))
;(define OUTLINE-GREEN-SQUARE (square NODE-LENGTH "outline" ERROR-COLOR))

;; dimensions of the canvas
(define CANVAS-WIDTH 400)
(define CANVAS-HEIGHT 400)
(define CANVAS-MID-WIDTH (/ CANVAS-WIDTH 2))
(define CANVAS-MID-HEIGHT (/ CANVAS-HEIGHT 2))
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))

(define ZERO 0)
(define THREE 3)
(define TWO 2)

(define HALF-NODE-LENGTH (/ NODE-LENGTH 2))
(define ADD-Y (* THREE NODE-LENGTH))
(define SUB-X (* TWO NODE-LENGTH))

(define NEW-NODE-POSN (make-posn CANVAS-MID-WIDTH HALF-NODE-LENGTH))

(define NEW-CENTER-NODE (make-node NEW-NODE-POSN false empty))

(define NEW-TREE (cons NEW-CENTER-NODE empty))

;; constants for test cases
(define POSN1 (make-posn 100 120))
(define POSN2 (make-posn 150 160))
(define POSN3 (make-posn 200 180))
(define CENTER-SON-POSN1 (make-posn 200 (+ (* THREE NODE-LENGTH)120)))
(define POSN5 (make-posn 200 10))
(define NODE5 (make-node POSN5 true empty))
(define POSN6 (make-posn 200 (+ (* THREE NODE-LENGTH) 10)))

(define NODE5-UNSELECTED (make-node POSN5 false empty))

(define NODE2 (make-node POSN2 false empty))
(define NODE3 (make-node POSN3 false empty))

(define NODE4 (make-node POSN6 false empty))
(define SON-TREE (list NODE4))
(define NEW-CENTER-SON-NODE (make-node POSN5 true SON-TREE))


(define TREE2 (list NODE2 NODE3))
(define NODE1 (make-node POSN1 false TREE2) )
(define NEW-SON-NODE1 (make-node NODE1 true SON-TREE))
(define NEW-SON-1 (cons NEW-SON-NODE1 empty))
(define EMPTY-TREE (list ))
(define TREE1 (list NODE1))
(define WORLD1 (make-world TREE1))
(define EMPTY-WORLD (make-world EMPTY-TREE))
(define NEW-TREE-IN-EMPTY-WORLD (make-world NEW-TREE))
(define NEW-SON-WORLD (make-world (list NEW-CENTER-SON-NODE)))


(define WORLD5 (make-world (list NODE5)))
;node with no space at left
(define POSN7 (make-posn NODE-LENGTH 10))
(define EDGE-POSN (make-posn NODE-LENGTH 
                             (+ (* THREE NODE-LENGTH)HALF-NODE-LENGTH)))
(define EDGE-NODE (make-node EDGE-POSN false empty))
(define EDGE-SON (list EDGE-NODE))
(define NODE7 (make-node POSN5 true EDGE-SON))
(define EDGE-WORLD (make-world (list NODE7)))

;;new brother world
(define POSN9 (make-posn (- 200 (* TWO NODE-LENGTH)) 
                         (+ (* THREE NODE-LENGTH)HALF-NODE-LENGTH)))
(define NODE9 (make-node POSN9 false empty))
(define NODE10 (make-node POSN5 true (list NODE9 NODE4)))
(define NEW-BROTHER-WORLD (make-world (list NODE10)))

;;tree below center-for "u"
(define POSN-DOWN (make-posn 10 (+ CANVAS-MID-HEIGHT 2 NODE-LENGTH) ))
(define NODE-DOWN (make-node POSN-DOWN false empty))
(define WORLD-WITH-NODE-ABOVE-AND-BELOW (make-world (list NODE5 NODE-DOWN)))
(define WORLD-WITH-NODE-BELOW-ONLY (make-world (list NODE-DOWN)))

;;tree after buttoon up 
(define WORLD5-UNSELECTED (make-world (list NODE5-UNSELECTED)))

;;nodes and tree for dragging
(define DRAGGED-SON-NODE-POSN
  (make-posn 201 (+ (* THREE NODE-LENGTH) 10 1)))
(define DRAGGED-SON-NODE (make-node DRAGGED-SON-NODE-POSN false empty))
(define DRAGGED-SON-TREE (list DRAGGED-SON-NODE))
(define DRAGGED-PARENT-NODE 
  (make-node (make-posn 201 11) true DRAGGED-SON-TREE)) 
(define DRAGGED-WORLD (make-world (list DRAGGED-PARENT-NODE)))

;;for world-to-scene
(define 1TREE-RT-SEL
  (make-world
 (list
  (make-node
   (make-posn 215 54)
   true
   (list (make-node (make-posn 135 114) false empty) 
         (make-node (make-posn 175 114) false empty) 
         (make-node (make-posn 215 114) false empty))))))



 
(define SQR-1TREE-RT-SEL (place-images (list OUTLINE-GREEN-SQUARE
                                             OUTLINE-GREEN-SQUARE
                                             OUTLINE-GREEN-SQUARE)
                                       (list (make-posn 135 114)
                                             (make-posn 175 114)
                                             (make-posn 215 114))
                                       EMPTY-CANVAS))

(define SQR-LINES-1TREE-RT-SEL
  (place-image SOLID-GREEN-SQUARE 215 54
   (scene+line
   (scene+line
    (scene+line (scene+line SQR-1TREE-RT-SEL 215 54 135 114 "blue") 
                215 
                54 
                175 
                114 
                "blue")
    215 54 215 114 "blue")
   (- 135 SUB-X HALF-NODE-LENGTH) 0 (- 135 SUB-X HALF-NODE-LENGTH) 
   CANVAS-WIDTH ERROR-COLOR)))

(define ROOT-SEL-CANT-CREATE-SON
  (make-world (list (make-node (make-posn HALF-NODE-LENGTH 92) true empty))))

(define ROOT-SEL-CANT-CREATE-SON-IMG
  (place-image SOLID-RED-SQUARE HALF-NODE-LENGTH 92 EMPTY-CANVAS))






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MAIN FUNCTION.

;; run: PosReal -> World
;; GIVEN: any value
;;EFFECT: runs a copy of an initial world
;; RETURNS: the final state of the world

(define (run x)
  (big-bang (initial-world x)
            (on-key world-after-key-event)
            (on-mouse world-after-mouse-event)
            (to-draw world-to-scene)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; world-after-key-event : World String -> World
;; GIVEN: a world w and a key event
;; RETURNS: the world that should follow the given world
;; after the given key event.
;; on t, new tree is created
;; on n, new son is added to the selected node
;; on d, selected node is deleted
;; on u, all nodes  whose center is in the upper half of the canvas are deleted
;; EXAMPLES: Refer test cases
;; Strategy:Cases on kev
(define (world-after-key-event w kev)
  (cond
    [(key=? kev "t") (world-after-t w)]
    [(key=? kev "n") (world-after-n w)]
    [(key=? kev "d") (world-after-d w)]
    [(key=? kev "u") (world-after-u w)]
    [else w]))

;; world-after-t : World -> World  
;; Given: a World
;; Returns: a World that appears after the 't' key stroke
;; Examples: Refer test cases
;; Strategy:Functional Composition
(define (world-after-t w) 
  (make-world (cons NEW-CENTER-NODE (world-tree w))))


;; world-after-n : World -> World  
;; Given: a World
;; Returns: a World that appears after the 'n' key stroke
;; Examples: Refer test cases
;; Strategy:Functional Composition
(define (world-after-n w)  
  (make-world (tree-after-n (world-tree w))))

;; tree-after-n: Tree -> Tree
;; Given: a Tree 
;; Returns: the tree after the key event n
;; Examples: Refer test cases
;; Strategy:HOFC
(define (tree-after-n tree)
  (map node-after-n tree))

;; node-after-n: Node -> Node
;; Given: a Node
;; Returns: if node is selected, returns the given node with a son added,
;; else the same node is returned.
;; Examples: refer test cases
;; Strategy: Functional Composition 
(define (node-after-n n)
  (if (and (node-selected? n)  (node-in-bound-with-space? n))
      (son-added n)
      (make-node (node-center n) (node-selected? n) 
                 (tree-after-n (node-sons n)))))

;;node-in-bound-with-space?: Node -> Boolean
;;Given: a Node
;;Returns:true iff the there is enough space after the left most son of the node
;;to add a new son
;;Examples: 
;;(node-in-bound-with-space? NODE5) => true
;;(node-in-bound-with-space? EDGE-NODE) => false
;;Strategy: Functional Composition
(define (node-in-bound-with-space? node)
  (and (current-node-inside? (node-center node))
       (left-most-son-in-bound-with-space? (node-sons node))))

;;current-node-inside?: Posn -> Boolean
;;Given:a center of a node
;;Returns:true iff the current node is with the left canvas wall
;;Examples:
;;(current-node-inside? POSN5) => true
;;(current-node-inside? EDGE-POSN) => false
;;Strategy:Structural Decomposition on center:Posn
(define (current-node-inside? center)
  (< ZERO (- (posn-x center) HALF-NODE-LENGTH)))

;;left-most-son-in-bound-with-space?: Tree -> Boolean
;;Given: a Tree which is a son of a node 
;;Returns: true iff there is enough space after given node
;;to add a new son
;;Examples: 
;;(left-most-son-in-bound-with-space? (list NODE5) => true
;;(left-most-son-in-bound-with-space? (list EDGE-NODE NODE6) => false
;;Strategy:Structural Decomposition on tree: Tree
(define (left-most-son-in-bound-with-space? tree)
  (cond
    [(empty? tree) true]   
    [else (node-in-bound? (first tree))]))

;;node-in-bound?: Node -> Boolean
;;Given: a Node
;;Returns:true iff there is enough space to the left of the node to add a new
;;node
;;Examples: 
;;(node-in-bound? NODE7) =>false
;;(node-in-bound? NODE5) =>true
;;Strategy:Structural Decomposition on node: Node
(define (node-in-bound? node)
  (space-for-new-node? (node-center node)))

;;space-for-new-node?: Posn -> Boolean
;;Given:a Posn
;;Returns:true iff there is enough space to the left of the posn to add a new
;;node
;;Examples:
;;(space-for-new-node? POSN5) => true
;;(space-for-new-node? EDGE-POSN) => fale
;;Strategy:Structural Decomposition on center:Posn
(define (space-for-new-node? center)
  (< ZERO (- (posn-x center) HALF-NODE-LENGTH SUB-X)))

;; son-added: Node -> Node
;; Given: a Node
;; Returns: a node with a son added
;; Examples: Refer test cases for main function
;; Strategy: Structural Decomposition on n: Node
(define (son-added n)
  (make-node (node-center n) (node-selected? n)
             (new-son-added (node-center n)  (node-sons n))))

;;new-son-added: Posn Tree -> Tree
;;Given: a Posn and a Tree
;;Returns: the given tree with a node added
;;Examples:refer test cases for main function
;;Strategy:Structural Decomposition on t: Tree
(define (new-son-added center t)
  (cond
    [(empty? t) (center-son center)]
    [else (cons
           (added-new-node (first t))
           t)]))

;;center-son: Posn -> Tree
;;Given: a center position of the parent node
;;Returns: a tree with its first and only node three node lengths below the
;;given posn
;;Examples:refer test cases for main function
;;Strategy:Structural Decomposition on parent-center: Posn
(define (center-son parent-center)
  (cons (new-node (posn-x parent-center) (posn-y parent-center)) empty))

;;new-node: Real Real->Node
;;Given: The coordinates of the parent node's center
;;Returns: a new node with center three node lengths below the
;;given parent node center
;;Examples:refer test cases for main function
;;Strategy:Functional Composition
(define (new-node parent-x parent-y)
  (make-node (new-node-center parent-x parent-y) false empty))

;;new-node-center: Real Real -> Posn
;;Given: The coordinates of the center of the parent node
;;Returns: the center of a node which is three node lengths below the
;;given parent node center
;;Examples: refer test cases for main function
;;Strategy:Functional Composition
(define (new-node-center parent-x parent-y)
  (make-posn parent-x (+ ADD-Y parent-y)))

;;added-new-node: Node-> Node
;;Given: the left most node of the selected nodes's son
;;Returns: a node which is two node lengths to the left of the given node
;;Examples:refer test cases for main function
;;Strategy:Structural Decomposition on left-most-node: Node
(define (added-new-node left-most-node)
  (make-node (added-node-center (node-center left-most-node)) 
             false empty))

;;added-node-center: Posn-> Posn
;;Given: the center coordinates of the left most node of the selected
;;nodes's son
;;Returns:a posn which is two node lengths to the left of the given posn
;;Examples:refer test cases for main function
;;Strategy:Structural Decomposition on left-most-node-center: Posn
(define (added-node-center  left-most-node-center)
  (make-posn (- (posn-x left-most-node-center) SUB-X )
             (posn-y left-most-node-center)))

;; world-after-d : World -> World 
;; Given: a World
;; Returns: a World after the key event d
;; Examples: refer test cases
;; Strategy:Functional Composition
(define (world-after-d w)  
  (make-world (tree-after-d (world-tree w))))

;; tree-after-d: Tree -> Tree
;; Given: a tree 
;; Returns: the tree after the key event d
;; Examples:refer test cases
;; Strategy:HOFC
(define (tree-after-d tree)
  (filter node-is-not-selected? (map node-with-sons-after-d tree)))

;; node-with-sons-after-d: Node -> Node
;; Given: a Node
;; Returns: the given node, where the selected nodes of its sons deleted
;; Examples:refer test cases
;; Strategy: Structural Decomposition on node: Node
(define (node-with-sons-after-d node)
  (make-node (node-center node)
             (node-selected? node)
             (tree-after-d (node-sons node))))

;; node-is-selected?: Node -> Boolean
;; Given: a Node
;; Returns: if selected, returns true else returns false
;; Examples: 
;; (node-is-selected? NODE5) => true
;; (node-is-selected? NODE2) => false
;; Strategy:Structural Decomposition on n: Node 
(define (node-is-not-selected? n)
  (not (node-selected? n)))

;; world-after-u : World -> World 
;; Given: a World
;; Returns: a World after key event u, where all its trees above the canvas mid 
;; are deleted
;; Examples:refer test cases
;; Strategy:Structural Decomposition on w: World
(define (world-after-u w)  
  (make-world (tree-after-u (world-tree w))))

;; tree-after-u: Tree -> Tree
;; Given: a tree 
;; Returns:the tree after key event u, where all its nodes above the canvas mid 
;; are deleted 
;; Examples:refer test cases
;; Strategy:HOFC
(define (tree-after-u tree) 
  ;;Node Tree -> Tree
  ;;Given:a Node and result of rest of the tree
  ;;Returns: if the given node is above the center then it removes the node and 
  ;;checks the same for the rest of the tree, else the node is retained and the 
  ;;rest of the tree is checked if above the canvas center
  (foldr 
   (lambda (node result-rest)
     (if (node-above-center? node)
         result-rest
         (cons node result-rest)))
   empty
   tree))

;; node-above-center?: Node -> Boolean
;; Given: a node
;; Returns: returns true iff the node is above the center of the canvas
;; Examples: refer test cases
;; Strategy: Structural Decomposition on n: Node
(define (node-above-center? n)
  (posn-above-center? (node-center n)))

;;posn-above-center?: Posn -> Boolean
;;Given: a Posn
;;Returns: true iff the point is above the center of the canvas
;;Examples:refer test cases
;;Strategy:Structural Decomposition on center: Posn
(define (posn-above-center? center)
  (< (- (posn-y center) NODE-LENGTH) CANVAS-MID-HEIGHT))

;;tests for world-after-key events and its helpers
(begin-for-test
  (check-equal? (world-after-key-event EMPTY-WORLD "t")NEW-TREE-IN-EMPTY-WORLD)
  (check-equal? (world-after-key-event WORLD5 "n") NEW-SON-WORLD)
  (check-equal? (world-after-key-event WORLD1 "n") WORLD1)
  (check-equal? (world-after-key-event EDGE-WORLD "n") EDGE-WORLD)
  (check-equal? (world-after-key-event NEW-SON-WORLD "n") NEW-BROTHER-WORLD)
  (check-equal? (world-after-key-event WORLD-WITH-NODE-ABOVE-AND-BELOW "u") 
                WORLD-WITH-NODE-BELOW-ONLY)
  (check-equal? (world-after-key-event WORLD5 "d") EMPTY-WORLD)
  (check-equal? (world-after-key-event WORLD1 "a") WORLD1)
  ;world-after- each key event functions
  (check-equal? (world-after-t EMPTY-WORLD)NEW-TREE-IN-EMPTY-WORLD)
  (check-equal? (world-after-n WORLD5) NEW-SON-WORLD)
  (check-equal? (world-after-u WORLD-WITH-NODE-ABOVE-AND-BELOW) 
                WORLD-WITH-NODE-BELOW-ONLY)
  (check-equal? (world-after-d WORLD5) EMPTY-WORLD)
  ;tree after each key event functions
  (check-equal? (tree-after-n (list NODE5))
                 (list NEW-CENTER-SON-NODE))
  (check-equal? (tree-after-u  (list NODE5 NODE-DOWN)) 
                (list NODE-DOWN))
  (check-equal? (tree-after-d (list NODE5)) (list ) )
  ;node functions after each key event
  (check-equal? (node-after-n  NODE5)
                  NEW-CENTER-SON-NODE)
  (check-equal? (node-above-center? NODE-DOWN) false) 
  (check-equal? (node-above-center? NODE5) true) 
  (check-equal? (node-with-sons-after-d NODE5)NODE5)
  ;;posn functions
  (check-equal? (posn-above-center? POSN5) true)
  (check-equal? (posn-above-center? POSN-DOWN) false)
  (check-equal? (added-node-center POSN5) (make-posn (- 200 SUB-X) 10))
  )


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; world-after-mouse-event : World Integer Integer MouseEvent -> World
;; Given: a World, mouse coordinates and mouse event
;; Returns: the world that should follow the given mouse event
;; Examples: refer test cases 
;; strategy: Cases on mev
(define (world-after-mouse-event w mx my mev)
  (cond
    [(mouse=? mev "button-down") (world-after-button-down w mx my)]
    [(mouse=? mev "drag") (world-after-drag w mx my)]
    [(mouse=? mev "button-up")(world-after-button-up w)]
    [else w]))

;; world-after-button-down : World Integer Integer -> World
;; RETURNS: the world following a button-down at the given location.
;; if the button-down is inside the node, returns a node just like the
;; given one, except that the nodes with mouse coordinates in it is represented
;; as  solid nodes 
;; Examples:refer test cases for world-after-mouse-event
;; STRATEGY: Structural Decomposition on w: World
(define (world-after-button-down w mx my)
  (make-world (tree-after-button-down (world-tree w) mx my)))

;;tree-after-button-down: Tree Integer Integer -> Tree
;;Given: a tree, and the mouse coordinates
;;Returns: the given Tree with the nodes selected if mouse is in 
;;the node
;;Examples:refer test cases for main function
;;Strategy:Higher Order Function Composition 
(define (tree-after-button-down tree mx my)
  (map 
   ;;Node -> Node
   ;;Given: a node
   ;;Returns: if the node is selected, returns the selected version of the given
   ;;node else it returns the same node
   (lambda (node) (in-node-selected node mx my))
   tree)) 

;;in-node-selected:Node Integer Integer -> Node
;;Given: a node
;;Returns: if the mouse coordinates are in the node, then the given node 
;;marked as selected is returned. Else, the given node is returned unchnaged.
;;Similarly, the nodes of the sons of the given node are also checked if
;;selected
;;Examples:refer test cases for main function
;;Strategy:Structural Decomposition on node: Node
(define (in-node-selected node mx my)
  (make-node (node-center node)
             (selected-value-node (node-center node) mx my)
             (tree-after-button-down(node-sons node) mx my)))

;;selected-value-node:Posn Integer Integer->Boolean
;;Given: the center point of a node and mouse coordinates
;;Returns: true iff the mouse coordinates are within the node
;;Examples:refer test cases
;;Strategy:Structural Decomposition on center:Posn
(define (selected-value-node center mx my)
  (in-node? (posn-x center) (posn-y center) mx my))

;;in-node?:Real Real Integer Integer
;;Given: the center coordinates of a node and mouse coordinates
;;Returns: true iff the mouse coordinates are with the node
;;Examples:
;;(in-node? 100 120 101 121) => true
;;(in-node? 100 120 180 190) => false
;;Strategy:Functional Composition
(define (in-node? node-x node-y mx my)
  (and
   (<= 
    (- node-x HALF-NODE-LENGTH)
    mx
    (+ node-x HALF-NODE-LENGTH))
   (<= 
    (- node-y HALF-NODE-LENGTH)
    my
    (+ node-y HALF-NODE-LENGTH))))

;; world-after-drag : World Integer Integer-> World
;; RETURNS: the world following a drag at the given location.
;; if the world is selected, then return a world just like the given
;; one, except the selected node is now centered on the mouse position.
;; EXAMPLES:refer test cases for main function
;; STRATEGY: Structural Decomposition on w: World
(define (world-after-drag w mx my)
  (make-world (tree-after-drag (world-tree w) mx my)))

;; tree-after-drag: Tree Integer Integer -> Tree
;; Given: a tree and mouse coordinates
;; Returns: the given Tree with the selected nodes and its sons dragged
;; Examples:refer test cases for main function
;; Strategy: HOFC 
(define (tree-after-drag tree mx my)
  (map 
   ;;Node->Node
   ;;Given: a Node
   ;;Returns: if selected,returns the given Node dragged as per the mouse 
   ;;movements ,else it returns the given Node unchanged
   (lambda (node) (if-selected-dragged-node node mx my))
   tree))

;;if-selected-dragged-node: Node Integer Integer -> Node
;;Given: a Node and the mouse coordinates
;;Returns: if selected, the given Node dragged as per the mouse movements 
;;else it returns the given Node unchanged
;;Examples:Refer test cases for main function
;;Strategy: Structural Decomposition on node: Node
(define (if-selected-dragged-node node mx my)
  (if (node-selected? node)
      (make-node (make-posn mx my)                 
                 true
                 (dragged-sons (node-sons node)
                               (distance-moved (node-center node) mx my)))
      (make-node (node-center node)
                 false
                 (tree-after-drag (node-sons node) mx my))))

;;distance-moved: Posn Integer Integer-> Posn
;;Given:the center coordinate of a node and mouse coordinates
;;Returns:the posn by which the node's sons should move by
;;Examples:Refer test cases for main function
;;Strategy:Structural Decomposition on center: Posn
(define (distance-moved center mx my)
  (make-posn (- mx (posn-x center)) (- my (posn-y center))))


;;dragged-sons: Tree Posn -> Tree
;;Given:a tree and the posn by which the tree should move
;;Returns:a tree moved by the given posn
;;Examples:refer test cases for main function
;;Strategy:HOFC
(define (dragged-sons tree move-point)
  (map (lambda (node) (moved node move-point)) tree))

;;moved: Node Posn -> Node
;;Given: a Node and the posn by which the node should move
;;Returns: a node and all its sons moved by the given posn
;;Examples:refer test cases for main function
;;Strategy:Structural Decomposition on node: Node
(define (moved node move-by-point)
  (make-node (moved-posn (node-center node) move-by-point)
             (node-selected? node) 
             (dragged-sons (node-sons node) move-by-point)))

;;moved-posn: Posn Posn -> Posn
;;Given: the center of a Node and the posn by which the center should move
;;Returns: the posn moved by the given posn
;;Examples:refer test cases for main function
;;Strategy:Structural Decomposition on posn: Posn
(define (moved-posn posn move-by-point)
  (make-posn (+ (posn-x posn) (posn-x move-by-point))
             (+ (posn-y posn) (posn-y move-by-point))))

;; world-after-button-up : World Integer Integer -> World
;; RETURNS: the world following a button-up at the given location.
;; if the node is selected, returns a tree just like the given one
;; except that its nodes are no longer selected.
;; EXAMPLES: refer test cases for main function
;; STRATEGY: struct decomp on w: World
(define (world-after-button-up w)
  (make-world (tree-after-button-up (world-tree w))))

;;tree-after-button-up: Tree -> Tree
;;Given: a Tree
;;Returns: the given tree with all its nodes unselected
;;Examples: refer test cases for main function
;;Strategy:HOFC
(define (tree-after-button-up tree)
  (map node-after-button-up tree))

;;node-after-button-up: Node -> Node
;;Given: a Node
;;Returns: the given node is marked as unselected and returned
;;Examples:refer test cases for main function
;;Strategy:Structural Decomposition on node: Node
(define (node-after-button-up node)
  (make-node (node-center node) false (tree-after-button-up (node-sons node))))

;;tests for world-after-mouse event
(begin-for-test
  (check-equal? (world-after-mouse-event WORLD5-UNSELECTED 202 11 "button-down")
                WORLD5)
  (check-equal? (world-after-mouse-event WORLD5 202 11 "button-up")
                WORLD5-UNSELECTED)
  (check-equal? (world-after-mouse-event NEW-SON-WORLD 201 11 "drag")
                DRAGGED-WORLD)
  (check-equal? (world-after-mouse-event WORLD5-UNSELECTED 201 11 "drag")
                WORLD5-UNSELECTED)
  (check-equal? (world-after-mouse-event WORLD5 201 11 "enter")
                WORLD5))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; initial-world: PosReal -> World
;; GIVEN: any value
;; EFFECT: ignores the given input and start a interactive program
;; RETURNS: an initial world.  The given value is ignored.
(define (initial-world x)
  (make-world empty))

;TEST CASES:
(begin-for-test 
  (check-equal? (initial-world 0)
                (make-world empty)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; node-x-pos: Posn -> Real
; GIVEN: Posn
; RETURNS: the x co-ordinate in the posn
; EXAMPLE: (node-x-pos (make-posn 19 10))-> 19
; STRATEGY: Structural Decomposition on center : Posn
(define (node-x-pos center)
  (posn-x center))

; node-y-pos: Posn -> Real
; GIVEN: Posn
; RETURNS: the y co-ordinate in the posn
; EXAMPLE: (node-y-pos (make-posn 19 10))-> 10
; STRATEGY: Structural Decomposition on center : Posn
(define (node-y-pos center)
  (posn-y center))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; world-to-scene World -> Scene
;; GIVEN: a World 
;; RETURNS: a scene representing the given world
;; EXAMPLES: refer test cases
;; STRATEGY: Structural Decomposition on world: World

(define (world-to-scene world)
  (if (empty? world)
      EMPTY-CANVAS
      (world-to-scene-helper (world-tree world) EMPTY-CANVAS)
      ))

;; world-to-scene-helper: Tree -> Scene
;; GIVEN: a Tree
;; RETURNS: a scene representing the given tree
;; EXAMPLES: refer test cases for main function
;; STRATEGY: Higher Order Function Composition
(define (world-to-scene-helper tree scene)
  (foldr
   ; Node Scene -> Scene
   ; GIVEN: a node and a scene
   ; RETURNS: the node image added to the scene
   (lambda (node scene)
     (draw-nodes node scene))
   scene
   tree))

;; draw-nodes: Node Scene -> Scene
;; GIVEN: a node and a scene
;; RETURNS: the scene with the given node's image added
;; EXAMPLES: refer test cases for main function
;; STRATEGY: Structural Decomposition on node : Node
(define (draw-nodes node scene)
  (draw-node-helper node
                    (if (empty? (node-sons node))
                        scene
                        (draw-child-nodes (node-x-pos (node-center node))
                                          (node-y-pos (node-center node))
                                          (node-sons node) scene))))


;; draw-child-nodes: Real Real Tree Scene -> Scene
;; GIVEN: the x,y co-ordinate of the parent node, the nodes' son and a scene 
;; RETURNS: the scene with the image of the son tree added to it
;; EXAMPLES: refer test cases for main function
;; STRATEGY: Structural Decomposition on node : Node
(define (draw-child-nodes x y tree scene)
  (foldr
   ; Node Scene -> Scene
   ; GIVEN: a node and a scene
   ; RETURNS: the node image added to the scene
   (lambda (node scene)
     (draw-scene-lines x y 
                       (node-x-pos (node-center node)) 
                       (node-y-pos (node-center node))
                       (draw-nodes node scene)))
   scene
   tree))

;; draw-scene-lines: Real Real Real Real Scene -> Scene
;; GIVEN: the x,y co-ordinate of the parent node and child node, and a scene
;; RETURNS: the scene with a line connecting the two given co-ordinates
;; EXAMPLES: refer test cases
;; STRATEGY: Function Composition
(define (draw-scene-lines par-x par-y chl-x chd-y scene)
  (scene+line scene par-x par-y chl-x chd-y BLUE-COLOR))

;; draw-node-helper Node Scene -> Scene
;; GIVEN: a node and a scene
;; RETURNS: the scene with a solid green colored square if the node is selected,
;; a outline green colored square if it is unselected and red colored 
;; square if the selected node doesn't have enough space to create a 
;; child node.
;; EXAMPLES: refer test cases
;; STRATEGY: Function Composition
(define (draw-node-helper node scene)
  (if (node-selected? node)
      (draw-selected-node node scene)
      (draw-unselected-node node scene)))

;; draw-selected-node Node Scene -> Scene
;; GIVEN: a selected node and a scene
;; RETURNS: the scene with a solid green square if the given node has 
;; space for a child node, else a solid red square is added to the scene.
;; EXAMPLES: refer test cases of main function
;; STRATEGY: Structural Decomposition on node: Node
 
(define (draw-selected-node node scene)
  (place-node-in-world (node-x-pos (node-center node))
                       (node-y-pos (node-center node))
                       (if (node-in-bound-with-space? node)
                           SOLID-GREEN-SQUARE
                           SOLID-RED-SQUARE)
                       (draw-vertical-line node scene)))

;; draw-vertical-line: Node Scene -> Scene
;; GIVEN: a selected node and a scene
;; RETURNS: the scene with a blue vertical line representing the edge of the 
;; child node to be created
;; EXAMPLES: refer test cases for main function
;; STRATEGY: Structural Decomposition on node: Node
(define (draw-vertical-line node scene)
  (if (node-in-bound-with-space? node)
      (draw-vertical-line-helper (node-x-pos (node-center node))
                                 (node-sons node) scene)
      scene))

;; draw-vertical-line-helper: Real Tree Scene -> Scene
;; GIVEN: the x co-ordinate of the selected node, its sons and a scene
;; RETURNS: the scene with a blue vertical line representing the edge of the 
;; child node to be created
;; EXAMPLES: refer test cases for main function
;; STRATEGY: Function Composition 
(define (draw-vertical-line-helper par-x sons scene)
  (add-line-to-canvas scene
                      (if (empty? sons)
                          par-x
                          (- (calc-min-xco-of-sons sons)
                             SUB-X))))

; calc-min-xco-of-sons: Tree -> Real
; GIVEN: a Tree
; RETURNS: the minimum x co-ordinate of all the nodes of the tree
; EXAMPLES: refer test cases of main function
; STRATEGY: Structural Decomposition on node: Node 
(define (calc-min-xco-of-sons sons)
  (foldr
   ; Node -> NonNegInt
   ;   GIVEN: a node and the min x value
   ; RETURNS: the lowest x co-ordinate
   (lambda (node xmin)
     (min (node-x-pos (node-center node))))
   CANVAS-WIDTH
   sons))

; add-line-to-canvas: Scene Real -> Scene
; GIVEN: a scene and the x-coordinate of the line to be drawn
; RETURNS: the scene with a vertical line on the give x co-ordinate
; EXAMPLES: refer test cases for main function
; STRATEGY: Function Composition 
(define (add-line-to-canvas scene x)
  (scene+line scene
              (- x HALF-NODE-LENGTH)
              ZERO
              (- x HALF-NODE-LENGTH)
              CANVAS-HEIGHT
              ERROR-COLOR))

;;draw-unselected-node Node Scene -> Scene
;;GIVEN: a node and a scene
;;RETURNS: the scene with the given unselected node represented as outline 
;;green square
;;EXAMPLES: refer test cases
;;STRATEGY: Structural Decomposition on node: Node
(define (draw-unselected-node node scene)
  (place-node-in-world (node-x-pos (node-center node))
                       (node-y-pos (node-center node))
                       OUTLINE-GREEN-SQUARE
                       scene))

;place-node-in-world: Real Real Image Scene -> Scene
; GIVEN: the x & y co-ordinate, square structure and a scene
; RETURNS: the scene with the given node represented as a square with its
; center in the given co-ordinates
; EXAMPLES: refer test cases of main function
; STRATEGY: Function Composition
 
(define (place-node-in-world x y square scene)
  (place-image square
               x
               y
               scene))


;TEST CASES for world to scene:
(begin-for-test
  (check-equal? (world-to-scene empty)
                EMPTY-CANVAS
                "Incorrect value. Should have returned an empty world")
  (check-equal? (world-to-scene 1TREE-RT-SEL)
                SQR-LINES-1TREE-RT-SEL
                "Incorrect value. Should have returned an empty world")
  
  (check-equal? (world-to-scene ROOT-SEL-CANT-CREATE-SON)
                ROOT-SEL-CANT-CREATE-SON-IMG
                "Incorrect value. Should have returned an empty world"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;world-to-roots : World -> ListOf<Node>
;;GIVEN: a World
;;RETURNS: a list of all the root nodes in the given world.
;;Examples: 
;;(world-to-roots WORLD5) => (list NODE5)
;;(world-to-roots WORLD1) => (list NODE1)
;;Strategy: Structural Decomposition on world: World
(define (world-to-roots world)
  (world-tree world))

;;node-to-center : Node -> Posn
;;GIVEN: a Node
;;RETURNS: the center of the given node as it is to be displayed on the scene.
;;Examples:
;;(node-to-center NODE5) => POSN5
;;Strategy: Structural Decomposition on node: Node
(define (node-to-center node)
  (node-center node))

;;node-to-sons : Node -> ListOf<Node>
;;Given: a Node
;;Returns: the sons of the node
;;Examples:
;;(node-to-sons NODE5) => empty
;;Strategy:Structural Decomposition on node: Node
(define (node-to-sons node)
  (node-sons node))

;;node-to-selected? : Node -> Boolean
;;Given: a Node
;;Returns: true iff the node is selected
;;Examples:
;;(node-to-selected?  NODE5) => true
;;(node-to-selected?  NODE2) => false
(define (node-to-selected? node)
  (node-selected? node))

;;tests for node and world functions
(begin-for-test
  (check-equal? (world-to-roots WORLD5) (list NODE5))
  (check-equal? (node-to-center NODE5) POSN5)
  (check-equal? (node-to-sons NODE5) (list ))
  (check-equal? (node-to-selected?  NODE5) true))
