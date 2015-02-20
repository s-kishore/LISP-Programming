;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname robot) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ())))
(require "extras.rkt")
(require "sets.rkt")
(require rackunit)



;Robot program take as input a starting position, target position and list of 
;blocked positions as input. A node is created with for the starting position 
;and passed to path-helper function which in turns calls other function to 
;retrieve the list of the valid braches of the current position and this is
;called in recursion to find all possible braches of the current position and
;braches of the braches and so on. Once the target has been reached the path
;from the starting postion to the target is calculated and retured.
;if there are no paths available to reach the destination position then the 
;program returns false

(provide path)
;_______________________________________________________________________________
;CONSTANTS

(define NORTH "north")
(define SOUTH "south")
(define EAST "east")
(define WEST "west")

(define X "x")
(define Y "y")
(define ZERO 0)
(define MINUS-ONE -1)
(define ONE 1)

;_______________________________________________________________________________
;DATA DEFINITIONS

;Position is a (list PosInt PosInt)
;INTERPRETATION:
;  a position is a list contaning the x and y coordinate of current block

;TEMPLATE:
;pos-fn: Position -> ??
#; (define (pos-fn pos)
     (... (first(pos))
      ... (second (pos))))

;a ListOf<Position> is one of
;--empty
;(cons Position ListOf<Position>)

;template:
;lop-fn: PositionSet -> ??
#;(define (lop-fn lop)
    (cond
      [(empty? lop) ...]
      [else (... (pos-fn (first lop))
                 (lop-fn (rest lop)))]))

(define-struct node (vstd-pos moves))
; A node is a (make-node Pos ListOf<Move>)

; vstd-pos INTERP: the position of the visited node
; moves:   INTERP: the sequence of moves needed to reach the vstd-pos

;TEMPLATE:
; node-fn: Node -> ??
#; (define (node-fn node)
     (... (pos-fn (vstd-pos))
          (lom-fn (node-moves node))))

; A ListOf<Node> is one of 
; -- empty                    INTERP: a empty list
; -- (cons Node ListOf<Node>) INTERP: a list with a node and a ListOf<Nodes>

;TEMPLATE:
; lon-fn : ListOf<Node> -> ??
#; (define (lon-fn lon)
     (cond [(empty? lon) ...]
           [else ... (node-fn (first lon))
                 ... (lon-fn (rest lon))]))

; A Move is a (list Direction PosInt)
; INTERP: a list containing the direction in which the robot has to move and the
;         the number of blocks it moves in that direction

; TEMPLATE:
#;(define (move-fn move)
    (... (dir-fn (first move))
     ... (second move)))

; A Direction can be one of

; -- "north" INTERP: the robot is moving in the north direction 
; -- "south" INTERP: the robot is moving in the south direction 
; -- "east" INTERP: the robot is moving in the east direction
; -- "west" INTERP: the robot is moving in the west direction 

;TEMPLATE: 
#; (define (dir-fn dir)
     (cond [(string=? dir "north") ...]
           [(string=? dir "south") ...]
           [(string=? dir "east") ...]
           [(string=? dir "west") ...]))

; A ListOf<Move> is either
; -- empty                    INTERP: a empty list
; -- (cons Move ListOf<Move>) INTERP: a list containing a move and a list of
;                                     moves to be followed after the first move

;TEMPLATE:
#; (define (lom-fn lom)
     (cond [(empty? lom)...]
           [else 
            (... (move-fn (first lom))
                 (lom-fn (rest lom)))]))

; A Plan is a ListOf<Move>

; A Maybe<Plan> is one of 
; -- false    
; -- Plan     
;INTERP: Plan is the list of moves the robot must make to reach the
;target avoiding blocks

;TEMPLATE:
; maybeplan-fn : Maybe<Plan> - ??
#; (define (maybeplan-fn maybeplan)
     (cond [(false? maybeplan) ...]
           [else (... (lom-fm maybeplan))]))

; A ListOf<PosInt> is one of 
; -- empty                        INTERP: a empty list
; -- (cons PosInt ListOf<PosInt>) INTERP: a list of Positive Integers and
;;                                        ListOf<PosInt>

;TEMPLATE: 
#;(define (lopi-fn lopi)
    (cond [(empty? lopi) ...]
          [else ... (first lopi)
                (lopi-fn (rest lopi))]))

;_______________________________________________________________________________
; path: Position Position ListOf<Position> -> Maybe<Plan>
;    GIVEN: starting, target position of the robot and position of blocks
;  RETURNS: a path that will take the robot to the target position if there is 
;           one else returns false
; EXAMPLES: Refer test cases
; STRATEGY: Function Composition

(define (path strt-pos trgt-pos blckd-lop)
  (if (is-pos-in-list? blckd-lop trgt-pos)
      false
      (path-helper strt-pos 
                   trgt-pos 
                   blckd-lop 
                   (list (make-node strt-pos empty))
                   empty)))

;_______________________________________________________________________________
; is-pos-in-list? : ListOf<Position> Position -> Boolean
;   GIVEN: a list of positions and a position
;  RETURNS: true iff the given position is in the list of positions else false
; EXAMPLES: (is-pos-in-list? '((10 10) (15 15)) (10 10)) -> true
;           (is-pos-in-list? '((12 10) (15 15)) (10 10)) -> false
; STRATEGY: Higher Order Function Composition

(define (is-pos-in-list? blckd-lop gvn-pos)
  (ormap
   ;;Position -> Boolean
   ;;Given: a Position
   ;;Returns: True iff the given position is equal to parent arg gvn-pos
   (lambda (blckd-pos)
     (equal? blckd-pos gvn-pos))
   blckd-lop))

;_______________________________________________________________________________
; in-target? : ListOf<Node> Position -> Boolean
;   GIVEN: a list of node and a position
;  RETURNS: true iff the given position is present in the list of position
; EXAMPLES: (in-target? $########### GRIZ
;           
; STRATEGY: Higher Order Function Composition

(define (in-target? lon trgt-pos)
  (ormap
   ;;Node -> Boolean
   ;;Given: a Node
   ;;Returns: True iff the given position is equal to parent arg trgt-pos   
   (lambda (node)
     (equal? (node-vstd-pos node) trgt-pos))
   lon))

;_______________________________________________________________________________
; path-helper : Position Position ListOf<Position> ListOf<Node> ListOf<Position>
;                                                                  -> Boolean
;    GIVEN: starting, target position of the robot, position of blocks, list of 
;           nodes of brahces from current node and a list of nodes checked
;  RETURNS: a path that will take the robot to the target position if there is 
;           one else returns false
; EXAMPLES: Refer test cases
; STRATEGY: Genral Recursion 

(define (path-helper strt-pos trgt-pos blckd-lop lon checked)
  (cond [(in-target? lon trgt-pos) (gen-path-to-dest lon trgt-pos)]
        [else 
         (path-helper strt-pos 
                   trgt-pos 
                   blckd-lop             
                   (rest 
                    (append lon (all-branches lon 
                                             checked 
                                             strt-pos 
                                             trgt-pos 
                                             blckd-lop)))
                   (append checked (visited-nodes lon)))]))

;_______________________________________________________________________________
; gen-path-to-dest : ListOf<Node> Position -> ListOf<Move> 
;    GIVEN: a list of nodes and the target position
;  RETURNS: the list of moves needed to reach the target position
; EXAMPLES: refer test cases
; STRATEGY: HOFC

(define (gen-path-to-dest lon trgt-pos)
  (foldr
   ; Node ListOf<Move> -> ListOf<Move>
   ; GIVEN: a node and a list of moves
   ; RETURNS: a list containing the moves if the node is the same as target
   (lambda (node base)
     (if (equal? (node-vstd-pos node) trgt-pos)
         (node-moves node)
         base))
   empty
   lon))

;_______________________________________________________________________________
; all-branches : ListOf<Node> ListOf<Position> Position Position 
;                                             ListOf<Position>  -> ListOf<Node>
;    GIVEN: the lost of nodes,a list of checked positions,source & target
;           target position of the robot and the blocked list of positions
;  RETURNS: the branches of the nodes present in the list of nodes
; EXAMPLES: Refer test cases
; STRATEGY: Structural Decomposition on lon : ListOf<Node>

(define (all-branches lon checked strt-pos trgt-pos blckd-lop)
  (calc-move (node-moves (first lon))
             (braches-from-node (node-vstd-pos (first lon))
                                strt-pos trgt-pos blckd-lop checked)))

;_______________________________________________________________________________
; braches-from-node : Position Position Position ListOf<Position> 
;                                          ListOf<Position> -> ListOf<Node>
;    GIVEN: the current position, source & target positions of the robot,
;;          blocked list of 
;           positions and checked list of positions
;  RETURNS: a list contaning the nodes after removing blocked positions and
;           repeated positions in the checked list of nodes
; EXAMPLES: Refer test cases
; STRATEGY: HOFC

(define (braches-from-node vstd-pos strt-pos trgt-pos blckd-lop checked)
  (foldr
   ; Node ListOf<Node> -> ListOf<Node>
   ;   GIVEN: a node and list of nodes which are valid braches of the node.
   ; RETURNS: a list with already checked and blocked node positions removed
   (lambda (cur-pos base)
     (if (or (is-pos-in-list? blckd-lop (node-vstd-pos cur-pos))
             (is-pos-in-list? checked (node-vstd-pos cur-pos)))
         base
         (cons cur-pos base)))
   empty
   (get-valid-branches vstd-pos strt-pos trgt-pos blckd-lop)))
         
;_______________________________________________________________________________
; get-valid-branches : Position Position Position ListOf<Position> 
;                                          -> ListOf<Node>
;    GIVEN: the current position, source & target positions and list of blocked
;           positions
;  RETURNS: a list contaning the valid nodes which are within the left and top
;           boundary
; EXAMPLES: Refer test cases
; STRATEGY: HOFC

(define (get-valid-branches vstd-pos strt-pos trgt-pos blckd-lop)
  (foldr
   ; Node ListOf<Node> -> ListOf<Node>
   ;   GIVEN: the current node & list of its brach nodes 
   ; RETURNS: a list contaning the valid nodes which are within the left and top
   ;          boundary
   (lambda (cur-pos base)
     (if (has-branches? (node-vstd-pos cur-pos) strt-pos trgt-pos blckd-lop)
         (cons cur-pos base)
         base))
   empty
   (get-all-4-braches vstd-pos)))

;_______________________________________________________________________________
; get-all-4-braches : Position -> ListOf<Node>
;    GIVEN: the current position
;  RETURNS: a list contaning all the 4 possible braches of current node
; EXAMPLES: Refer test cases
; STRATEGY: Function Composition

(define (get-all-4-braches vstd-pos)
  (list
   (make-node (change-coords-by vstd-pos Y MINUS-ONE)
              (list (list NORTH ONE)))
   (make-node (change-coords-by vstd-pos Y ONE)
              (list (list SOUTH ONE)))
   (make-node (change-coords-by vstd-pos X ONE)
              (list (list EAST ONE)))
   (make-node (change-coords-by vstd-pos X MINUS-ONE)
              (list (list WEST ONE)))))

;_______________________________________________________________________________
; has-branches? : Position Position Position ListOf<Position> -> Boolean
;    GIVEN: the current, starting and target position of the robot and the list
;           of blocked positions
;  RETURNS: true iff the current position is inside the top and left border of 
;           the board
; EXAMPLES: Refer test cases
; STRATEGY: Structural Decomposition on strt-pos, trgt-pos, cur-pos : Position

(define (has-branches? cur-pos strt-pos trgt-pos blckd-lop)
  (and (> (first cur-pos) ZERO) 
       (> (second cur-pos) ZERO)
       (<= (first cur-pos) (+ (get-max-coords (generate-lopts X blckd-lop)
                                              (max (first strt-pos) 
                                                   (first trgt-pos)))
                              ONE))
       (<= (second cur-pos) (+ (get-max-coords (generate-lopts Y blckd-lop)
                                              (max (second strt-pos) 
                                                   (second trgt-pos)))
                              ONE))))

;_______________________________________________________________________________
; generate-lopts : String ListOf<Positions> -> ListOf<PosInt>
;    GIVEN: a string denoting which co-ordinate X or Y is needed and the list 
;           of blocked positions 
;  RETURNS: a list of positive integers that denote the requested (x or y)
;           co-ordinate of the entire block list of positions
; EXAMPLES: (generate-lopts "X" '((10 20) (13 15))) -> (list 20 15)
;           (generate-lopts "Y" '((10 32) (13 13))) -> (list 10 13)
; STRATEGY: HOFC

(define (generate-lopts xy blckd-lop)
  (map 
   ; Position -> PosInt
   ;   GIVEN: a position 
   ; RETURNS: the x or y co-ordinate based on the string value in xy
   (lambda (blckd-pos)
     (if (string=? X xy)
         (first blckd-pos)
         (second blckd-pos)))
   blckd-lop))

;_______________________________________________________________________________
; get-max-coords : ListOf<PosInt> PosInt -> PosInt
;    GIVEN: a list of positive integers and a max pos int
;  RETURNS: a positive integer that denote the requested (x or y)
;           co-ordinate of the entire block list of positions
; EXAMPLES: (get-max-coords '(10 20 13 15) 15) -> 20
;           (get-max-coords '(10 20 13 40) 10) -> 40
; STRATEGY: HOFC

(define (get-max-coords locoord max-pos)
  (foldr
   ; PosInt PosInt-> PosInt
   ;    GIVEN: a positive int
   ;  RETURNS: maximum of the max-pos and given PosInt
   (lambda (coord base-max)
     (max coord base-max))
   max-pos
   locoord))

;_______________________________________________________________________________
; calc-move : ListOf<Move> ListOf<Node> -> ListOf<Node>
;    GIVEN: a list of moves and a list of nodes
;  RETURNS: a list  nodes with same consecutive moves merged as one
; EXAMPLES: refer test cases
; STRATEGY: HOFC

(define (calc-move moves lon)
  (map
   ; Node -> Node;
   ;   GIVEN: a node
   ; RETURNS: a new node with same direction consecutive moves merged as one
   (lambda (node)
     (make-node (node-vstd-pos node) (merge-moves-list moves (node-moves node)
                                                        )))
   lon))

;_______________________________________________________________________________
; merge-moves-list : ListOf<Move> ListOf<Move> -> ListOf<Move>
;    GIVEN: a list of moves and the list of moves made by current node
;  RETURNS: a list moves with same consequitive moves merged as one
; EXAMPLES: refer test cases
; STRATEGY: Structural Decomposition on moves nd-moves : ListOf<Move>

(define (merge-moves-list moves nd-moves)
  (cond [(empty? moves) nd-moves]
        [(= (length moves) ONE) (merge-moves-list-helper (first moves)
                                                         (first nd-moves)
                                                         nd-moves)]
        [else 
         (cons (first moves) (merge-moves-list (rest moves) nd-moves))]))

;_______________________________________________________________________________
; merge-moves-list-helper : Move Move ListOf<Move> -> ListOf<Move>
;    GIVEN: the move to be appended and the current move and the list of moves
;           which contain the current move
;  RETURNS: a list moves with same consequitive moves merged as one
; EXAMPLES: refer test cases
; STRATEGY: Structural Decomposition nd-moves : ListOf<Move>

(define (merge-moves-list-helper fmove fnd-moves nd-moves)
  (if (string=? (first fmove) (first fnd-moves))
      (list (list (first fmove) (+ (second fmove)
                                   (second fnd-moves))))
      (cons fmove nd-moves)))

;_______________________________________________________________________________
; visited-nodes : ListOf<Node> -> PositionSet
;    GIVEN: a list of nodes
;  RETURNS: a list containing the positions of all visited nodes
; EXAMPLES: refer test cases
; STRATEGY: HOFC

(define (visited-nodes lon)
  (map 
   ; Node -> Position
   ;   GIVEN: a node
   ; RETURNS: a position
   node-vstd-pos
   lon))

;_______________________________________________________________________________
; change-coords-by : Position String NonNegInt -> Position
;    GIVEN: the current position, String indicating which co-ordinate has to be
;           changed and the value by which it has to be changed
;  RETURNS: the position after making changes to the co-ordinates of the current
;           position
; EXAMPLES: (change-coords-by '(20 20) "x" 10) -> (list 30 20)
;           (change-coords-by '(20 20) "y" 10) -> (list 20 30)
; STRATEGY: Structural De-composition on cur-pos : Position

(define (change-coords-by cur-pos XY value)
  (if (string=? XY X)
      (list (+ (first cur-pos) value)
            (second cur-pos))
      (list (first cur-pos)
            (+ (second cur-pos) value))))

;_______________________________________________________________________________

; TEST CASES



(begin-for-test 
  (check-equal? (path (list 1 2) (list 8 13) (list (list 1 3) (list 8 12)))
                (list (list "east" 1) (list "south" 11) (list "east" 6))
                "Incorect Path")
  (check-equal? (path (list 1 2) (list 8 13) (list (list 8 13)))
                false
                "Incorrect Output. Should be false")
    
  (check-equal? (path-helper (list 1 2) (list 4 5) (list (list 2 3))
                             (list (make-node (list 4 5) 
                                              (list (list "north" 1))))
                             (list (list 3 3)))
                (list (list "north" 1))
                "Incorrect Output")
  
    
  (check-equal? (in-target? (list 
                             (make-node (list 4 5) (list (list "north" 1)))) 
                            (list 4 5)) 
                true)
  (check-equal? (gen-path-to-dest (list (make-node (list 4 5) 
                                                   (list (list "north" 1)))) 
                                  (list 4 5))
                '(("north" 1)))
  (check-equal? (visited-nodes (list (make-node (list 4 5) 
                                                   (list (list "north" 1)))))
                (list (list 4 5))))

