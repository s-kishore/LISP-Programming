;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname obstacles) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ())))
(require "extras.rkt")
(require "sets.rkt")
(require rackunit)

(provide
 position-set-equal?
 obstacle?
 blocks-to-obstacles)

;;Obstacles:
;;the problem takes a set of positions which are blocks and returns the given
;;set of positions, split into obstacles, based on whether the given set of 
;;positions are adjacent or not.

;;Problem Approach:
;;The approach taken in this problem, is to firstly form a list of all 
;;adjacent sets from the given position sets.

;;Secondly, the list of adjacent sets are merged such that, all the position 
;;sets which have the same position are merged.

;;Lastly, the duplicates which are formed from merging are removed to give the 
;;list of obstacles.


;;Data Definitions
;; A Position is a (list PosInt PosInt)
;; where the members of the list represents the position x, y and there are at 
;; most two members in the list.
;; Note: this is not to be confused with the built-in data type Posn.

;;template
;;position-fn: pos -> ?
;;(define (position-fn pos)
;;  (... (first pos)
;;       (second pos)))

;;a ListOf<Position> is one of
;;--empty
;;(cons Position ListOf<Position>)

;;template:
;;pset-fn: pset -> ?
;;(define (pset-fn pset)
;;  (cond
;;    [(empty? pset) empty]
;;    [else (... (first pset)
;;               (pset-fn (rest pset)))]))

;; A PositionSet is a ListOf<Position> without duplication.

;;a ListOf<PositionSet> is one of
;;--empty
;;--(cons PositionSet ListOf<PositionSet>)

;;template:
;;lpset-fn: lpset -> ?
;;(define (lpset-fn lpset)
;;  (cond
;;    [(empty? lpset) ...]
;;    [else (... (pset-fn (first lpset))
;;               (rest lpset))]))

;; A PositionSetSet is a list of PositionSets without duplication,
;; that is, no two position-sets denote the same set of positions.

;; a NonEmptyPositionSetSet (NEPSS)  is a ListOf<PositionSet> without duplicatio
;;and is never empty.
;;a NonEmptyListOf<PositionSet> is one of
;;--(cons PositionSet empty)
;;--(cons PositionSet ListOf<PositionSet>)

;;template:
;;nelop-fn: nelop -> ?
;;(define (nelop-fn nelop)
;;  (cond
;;    [(empty? (rest nelop)) (... (pset-fn (first nelop)))]
;;    [else (... (pset-fn (first nelop))
;;               (nelop-fn nelop))]))




;;Constant Definitions:
(define ONE 1)
(define PS-1 (list (list 1 2) (list 3 2) (list 4 1) (list 2 3) (list 3 4)))
(define PS-2 (list (list 3 2) (list 4 1) (list 3 2) (list 2 3) (list 4 1)
                   (list 3 2) (list 1 2) (list 2 3) (list 2 3) (list 3 4)))
(define PS-4 (list (list 4 1) (list 3 2) (list 1 2) (list 2 3) (list 3 4) 
                   (list 2 3)))

(define PS-5 (list (list 4 1) (list 3 2) (list 1 2) (list 2 3)
                   (list 3 4) (list 2 3) (list 1 3) (list 4 4)))
(define PSS-3 
  (list
   (list (list 1 2) (list 2 3) (list 3 2) (list 4 1) (list 3 2) (list 2 3) 
         (list 2 3) (list 3 4))
   (list (list 3 2) (list 4 1) (list 3 2) (list 2 3) (list 4 1))
   (list (list 1 2) (list 2 3) (list 3 2) (list 4 1) (list 3 2) (list 2 3)
         (list 2 3) (list 3 4) (list 3 4))
   (list (list 2 3) (list 3 4) (list 3 4))))

(define PSS-1 (list
               (list (list 1 2) (list 2 3))
               (list (list 1 3))
               (list (list 2 3) (list 3 2) (list 2 3) (list 3 4))
               (list (list 3 2) (list 4 1))
               (list (list 3 4))
               (list (list 4 1))
               (list (list 4 4))))

(define PSS-2 (list
               (list (list 4 1) (list 3 2) (list 2 3))
               (list (list 4 1) (list 3 2) (list 1 2) (list 2 3) (list 3 4))
               (list (list 1 2) (list 3 2) (list 2 3) (list 3 4))
               (list (list 3 2) (list 1 2) (list 2 3) (list 3 4))
               (list (list 2 3) (list 3 4))))
(define PSS-6 (list
               (list (list 1 2) (list 3 2) (list 2 3) (list 3 4))
               (list (list 1 3))
               (list (list 1 2) (list 3 2) (list 4 1) (list 2 3) (list 3 4))
               (list (list 2 3) (list 3 4) (list 3 2) (list 4 1))
               (list (list 3 2) (list 2 3) (list 3 4))
               (list (list 3 2) (list 4 1))
               (list (list 4 4))))

(define PS-7
  (list
   (list 4 1)
   (list 3 2)
   (list 1 2)
   (list 2 3)
   (list 3 4)
   (list 1 2)
   (list 3 2)
   (list 2 3)
   (list 3 4)
   (list 3 2)
   (list 1 2)
   (list 2 3)
   (list 3 4)
   (list 4 1)
   (list 3 2)
   (list 2 3)
   (list 4 1)
   (list 2 3)
   (list 3 4)
   (list 3 4)))

;;blocks-to-obstacles : PositionSet -> PositionSetSet
;;GIVEN: the set of occupied positions on some chessboard
;;RETURNS: the set of obstacles on that chessboard.
;;EXAMPLES:refer test cases
;;strategy: Functional Composition
(define (blocks-to-obstacles pset)
  (if (empty? (adjacent-pair-list pset))
      empty
      (checked-no-duplicate-psetset(merged-adjacent-duplicates 
                                    (merged-obstacles-psetset
                                     (adjacent-pair-list pset))))))

;;checked-no-duplicate-psetset: PositionSetSet -> PositionSetSet
;;Given:a set of position set in which each position set is an obstacle
;;Returns:if any of the positions in a position set is found in another position
;;set in the given PositionSetSet, then the PositionSetSet is merged to remove
;;duplicate PositionSets
;;Examples:refer test cases
;;Strategy: Functional Composition
(define (checked-no-duplicate-psetset psetset)
  (if (ps-not-repeated-in-psetset? psetset)
      psetset
      (checked-no-duplicate-psetset
       (merged-adjacent-duplicates 
        (merged-obstacles-psetset psetset)))))

;;ps-not-repeated-in-psetset?: NEPSS -> Boolean
;;Given:a non empty set of position sets
;;Returns:true iff there is no repetition of the position in the subset
;;Examples:refer test cases
;;Strategy: Structural Decomposition on psetset: NEPSS
(define (ps-not-repeated-in-psetset? psetset)
  (cond
    [(empty? (rest psetset)) true ]
    [else (and (pset-not-repeated-in-psetset? (first psetset)(rest psetset))
               (ps-not-repeated-in-psetset? (rest psetset)))]))

;;pset-not-repeated-in-psetset? PositionSet PositionSetSet -> Boolean
;;Given:a set position sets , and a single position set from the given 
;;PositionSetSet
;;Returns:true iff there is no repetition of the position in the subset
;;Examples:refer test cases
;;Strategy: HOFC & Structural Decomposition on pset: PositionSet
(define (pset-not-repeated-in-psetset? pset psetset)
  (andmap 
   ;;Position -> Boolean
   ;;Given: a position 
   ;;Returns: true iff position is not repeated in parent arg psetset
   (lambda (pos) (pos-not-repeated-in-psetset? pos psetset)) pset))

;;pos-not-repeated-in-psetset?: Position NEPSS -> Boolean
;;Given:a set position sets , and a single position from the given 
;;PositionSetSet
;;Returns:true iff there is no repetition of the position in the subset
;;Examples:refer test cases
;;Strategy: Structural Decomposition in psetset: NEPSS
(define (pos-not-repeated-in-psetset? pos psetset)
  (cond
    [(empty? (rest psetset)) (not (pos-in-pset? pos (first psetset)))]
    [else (and (not (pos-in-pset? pos (first psetset)))
               (pos-not-repeated-in-psetset? pos (rest psetset)))]))


;;merged-adjacent-duplicates: NEPSS -> NEPSS
;;Given:anon empty set of position sets
;;Returns:the given set of position sets with the duplicates removed
;;Examples:refer test cases
;;Strategy:Functional Composition
(define (merged-adjacent-duplicates psetset)
  (merged-duplicates psetset psetset))

;;adjacent-pair-list: PositionSet -> NEPSS
;;Given:a set of positions
;;Returns: a set of position sets, where each position set is list of adjacent 
;;nodes
;;Examples:refer test caaes
;;Strategy:Structural Decomposition on pset: PositionSet
(define (adjacent-pair-list pset)
  (cond
    [(empty? pset) empty]
    [else (append (if (empty? (adjacent-pairs (first pset) pset))
                      (list (list (first pset)))
                      (list (adjacent-pairs (first pset) pset)))
                  (adjacent-pair-list (rest pset)))]))

;;adjacent-pairs: Position PositionSet -> PositionSet
;;Given: a Position and a PositionSet
;;Returns: a list of all positions from the given position set, which  adjacent 
;;to the given position
;;Examples:
;; pos with adjacent pos:
;;(adjacent-pairs (list 2 3) (list (list 3 2) (list 1 2)))
;;  => (list (list 2 3) (list 3 2) (list 2 3) (list 1 2))
;;pos without adjacent pos in pset:
;;(adjacent-pairs (list 5 5) (list (list 3 2) (list 1 2))) => empty
;;Strategy: Structural Decomposition on pset: PositionSet
(define (adjacent-pairs pos pset)
  (cond
    [(empty? pset) empty]
    [else  (if (adjacent? pos (first pset))
               (append (list pos (first pset))
                       (adjacent-pairs pos (rest pset)))
               (adjacent-pairs pos (rest pset)))]))

;;adjacent?: Position Position -> Boolean
;;Given:any two positions
;;Returns:true iff the given positions are adjacent to each other
;;Examples:
;;(adjacent? (list 1 2) (list 2 3)) => true
;;(adjacent? (list 5 5) (list 2 3)) => false
;;Strategy:Structural Decomposition on pos1 and pos2: Position
(define (adjacent? pos1 pos2)
  (adjacent-pos? (first pos1) (first pos2) (second pos1) (second pos2)))

;;merged-duplicates: NEPSS PositionSetSet-> NEPSS
;;Given:two positions
;;where: the second PositionSetSet is the overall set of position sets against 
;;each of its position sets are compared and merged. the first set of position 
;;set is also a subset of the second position set. 
;;Returns:a PositionSetSet where if the positon sets of the first PositionSetSet
;;are found as subset mre than once, or has exact duplicates of the position 
;;set
;;Examples:refer test cases
;;Strategy:Structural Decomposition on psetset: NEPSS
(define (merged-duplicates psetset mpsetset)
  (cond
    [(empty? (rest psetset))  (if (pset-subset-check? (first psetset) mpsetset)
                                  empty
                                  (list (first psetset)))]
    [else (if (pset-subset-check? (first psetset) mpsetset)
              (exact-pset-checked-removed (first psetset)(rest psetset) psetset)
              (append (list (first psetset))
                      (merged-duplicates (rest psetset) mpsetset)))]))


;;exact-pset-checked-removed: PositionSet PositionSetSet PositionSetSet
;;                                  -> PositionSetSet
;;Given:a position set, the remaining list from the main list and the overall 
;; set of position sets
;;Returns: if the given position set has an exact match in the main position
;;set more than once, then the duplicate position set is removed fro the overall
;;position set set.
;;Examples:refer test cases
;;Strategy:Functional Composition
(define (exact-pset-checked-removed pset remaining psetset)
  (if (exact-duplicate-pset? pset (removed-first pset psetset))
      (merged-duplicates remaining (removed-first pset psetset))
      (merged-duplicates remaining psetset)))


;;pset-subset-check?: PositionSet PositionSetSet -> Boolean
;;Given: a position set and a set of position sets
;;Returns: true iff the given position set is a subset of the given 
;;PositionSetSet
;;Examples: refer test cases
;;Strategy:Functional Composition
(define (pset-subset-check? pset psetset)
  (pset-subset? pset (removed-first pset psetset)))

;;exact-duplicate-pset? PositionSet PositionSetSet -> Boolean
;;Given: a position set and  a position set set
;;Returns: true iff an exact dupicate of the given position set is found in the 
;;given position set set
;;Examples: refer test cases
;;Strategy:HOFC
(define (exact-duplicate-pset? pset psetset)
  (ormap
   ;;PositionSet-> Boolean
   ;;Given: a position set
   ;;Returns: true iff the given position set is exactly equal to parent arg
   ;;position set psetset
   (lambda (list-pset) (position-set-equal? pset list-pset)) 
   psetset))


;;removed-first:PositionSet PositionSetSet -> PositionSetSet
;;Given:a position set and set of position sets
;;Returns:if the given position set is found in the given set of position sets, 
;;then a new set of position sets with the first instance of the position set
;;removed
;;Examples:refer test cases
;;Strategy:HOFC
(define (removed-first pset mpsetset)
  (filter 
   ;;PositionSet -> Boolean
   ;;Given: a position set
   ;;Returns: if given position not equal to parent argument pset
   (lambda (list-pset) (not (equal? pset list-pset)))
   mpsetset))

;;removed-duplicates:PositionSet -> PositionSet
;;Given:a set of positions
;;Returns:the given set of positions, with the duplicate positions removed
;;Examples:refr test cases
;;Strategy:Structural Decomposition on pset: PositionSet
(define (removed-duplicates pset)
  (cond
    [(empty? pset) empty]
    [else (if (member? (first pset) (rest pset))
              (removed-duplicates (rest pset))
              (cons 
               (first pset) (removed-duplicates (rest pset))))]))


;;pset-subset?:PositionSet PositionSetSet-> Boolean
;;Given: a position set and a set of position sets
;;Returns: true iff the given position set is a subset of the given 
;;PositionSetSet
;;Examples: refer test cases
;;Strategy:HOFC
(define (pset-subset? pset psetset)
  (ormap 
   ;;PositionSet -> Boolean
   ;;Given: a position set
   ;;Returns: true iff the given position set is a subset of the parent arg pset
   (lambda (list-pset)(contained-in? pset list-pset)) psetset))

;;contained-in?: PositionSet PositionSet -> Boolean
;;Given:a position set and the main set of positions
;;Returns: true iff the given position set is contained in the main position set
;;Examples:refer test cases
;;Strategy:HOFC
(define (contained-in? pset main-pset)
  (andmap 
   ;;Positon -> Boolean
   ;;Given: any position
   ;;Returns: true iff the given position is contained in the parent 
   ;;arg main-pset
   (lambda (pos) (pos-in-pset? pos main-pset))
   pset))

;;position-set-equal? PositionSet PositionSet -> Boolean
;;Given:any two position sets
;;Returns:true iff the given position sets contain the exact same position in
;;any order
;;Examples:
;;(position-set-equal? (list (list 1 2) (list 2 3)) (list (list 2 3)(list 1 2))
;;                       => true
;;(position-set-equal? (list (list 4 4) (list 2 3)) (list (list 2 3)(list 1 2))
;;                       => false
;;Strategy:Functional Composition
(define (position-set-equal? pset1 pset2)
  (and (= (length pset1) (length pset2))
       (pset-equal? pset1 pset2)))

;;pset-equal?:  PositionSet PositionSet -> Boolean
;;Given:any two position sets
;;Returns:true iff the all the positions in the first position set is contained 
;;in the second position set
;;Examples:
;;(pset-equal? (list (list 1 2) (list 2 3)) (list (list 2 3)(list 1 2)(list 3 4)
;;                       => true
;;(pset-equal? (list (list 4 4) (list 2 3)) (list (list 2 3)(list 1 2))
;;                       => false
;;Strategy:HOFC
(define (pset-equal? pset1 pset2)  
  (andmap
   ;;Position -> Boolean
   ;;Given: a position
   ;;Returns: true iff the given position is found in parent arg pset2
   (lambda (pos) (pos-in-pset? pos pset2))
   pset1))

;;pos-in-pset?: Position PositionSet -> Boolean
;;Given:a Position and a PositionSet
;;Returns:returns true iff the given position is contained in the given position
;;set
;;Examples:
;;(pos-in-pset? (list 1 2) (list (list 1 2) (list 2 3))) => true
;;(pos-in-pset? (list 3 4) (list (list 1 2) (list 2 3))) => false
;;Strategy: HOFC
(define (pos-in-pset? pos pset)
  (ormap 
   ;;Position -> Boolean
   ;;Given: a position
   ;;Returns: true if the given position is equal to the parent arg pos
   (lambda (list-pos) (equal? pos list-pos))
   pset))


;;adjacent-pos?: PosInt PosInt PosInt PosInt -> Boolean
;;Given:the x and y coordinates of two positions
;;Returns:true iff the given two positions x and y coordinates are adjacent to
;;each other
;;Examples:
;;(adjacent-pos? 1 2 2 3) => true
;;(adjacent-pos? 1 4 2 5) => false
;;Strategy:Functional Composition
(define (adjacent-pos? x1 x2 y1 y2)
  (or (and (= x2 (- x1 ONE)) (or (= y2 (- y1 ONE)) (= y2 (+ y1 ONE))))
      (and (= x2 (+ x1 ONE)) (or (= y2 (- y1 ONE)) (= y2 (+ y1 ONE))))))


;;merged-obstacles-psetset: PositionSetSet -> PositionSetSet
;;Given:a PositionSetSet
;;Returns: if the sets of the set of position sets have any position found in 
;;another position set , then the two position sets are merged.
;;Examples:refer test cases
;;Strategy:Functional Composition
(define (merged-obstacles-psetset psetset)
  (merged-obstacles psetset psetset))

;;merged-obstacles: PositionSetSet PositionSetSet -> PositionSetSet
;;Given:a set of position sets and a main set of position sets
;;Returns:if the sets of the set of position sets have any position found in 
;;the main position set , then the two position sets are merged.
;;Examples:refer test cases
;;Strategy:HOFC
(define (merged-obstacles psetset main-psetset)
  (foldr
   ;;PositionSet PositionSetSet -> PositionSetSet
   ;;Given: a position set and output for rest of the parent list 
   ;;Returns: if the given position set has any position found in 
   ;;the main position set , then the two position sets are merged.
   (lambda (pset rest) (append (list (removed-duplicates 
                                      (compared-merged pset main-psetset)))
                               rest))
   empty
   psetset))

;;compared-merged:PositionSet PositionSetSet -> PositionSet
;;Given:a position set and a main set of position sets
;;where: a main position set contains the list of position sets which have not
;;been identified to contain duplicate positions in position sets
;;Returns:if the positions of the given set of positions have any position 
;;found in the main position set , then the two position sets are merged.
;;Examples:refer test cases
;;Strategy: Structural Decomposition on pset: PositionSet
(define (compared-merged pset psetset)
  (cond
    [(empty? pset) empty]
    [else  (if (empty? (compare-pos-psetset (first pset) psetset))
               (append (list (first pset))
                       (compared-merged (rest pset) psetset)) 
               (append (compare-pos-psetset (first pset) psetset)
                       (compared-merged
                        (rest pset) 
                        (matched-pset-removed (first pset) psetset))))]))

;;compare-pos-psetset: Position PositionSetSet -> PositionSetSet
;;Given:a position and a set of position sets
;;Returns:if the given positions is equal to  any position 
;;found in the given set of  position sets, then the two position
;;sets are merged.
;;Examples:refer test cases
;;Strategy:Structural Decomposition on psetset: PositionSetSet
(define (compare-pos-psetset pos psetset)
  (cond 
    [(empty? psetset) empty]
    [else (if (pos-in-pset? pos (first psetset))
              (append (first psetset) (compare-pos-psetset pos (rest psetset)))
              (compare-pos-psetset pos (rest psetset)))]))

;;matched-pset-removed: Position PositionSetSet -> PositionSetSet
;;Given: a position and a set of position sets
;;Returns:the given set of position sets with the position sets containing the
;;given position removed
;;Examples:refer test cases
;;Strategy:Structural Decomposition on psetset: PositionSetSet
(define (matched-pset-removed pos psetset)
  (cond 
    [(empty? psetset) empty]
    [else (if (pos-in-pset? pos (first psetset))
              (matched-pset-removed pos (rest psetset))
              (append (list (first psetset)) 
                      (matched-pset-removed pos (rest psetset))))]))

;;obstacle?: PositionSet -> Boolean
;;Given: a set of positions
;;Returns:  true iff the set of positions would be an obstacle if they
;;were all occupied and all other positions were vacant. 
;;Examples: refer test cases
;;Strategy: Functional Composition
(define (obstacle? pset)
  (= (length (blocks-to-obstacles pset)) ONE))


(begin-for-test
  (check-equal? (blocks-to-obstacles PS-5) 
                (list (list (list 4 1) (list 3 2) (list 1 2) (list 3 4)
                            (list 2 3)) (list (list 1 3)) (list (list 4 4))))
  (check-true (obstacle? PS-4))
  (check-true (position-set-equal? (list (list 1 2) (list 2 3)) 
                                   (list (list 2 3) (list 1 2))))
  (check-equal? (removed-duplicates 
                 (list (list 3 2) (list 4 1) (list 3 2) (list 2 3)
                       (list 4 1) (list 3 2) (list 1 2) (list 2 3)
                       (list 2 3) (list 3 4)))
                (list (list 4 1) (list 3 2) (list 1 2) (list 2 3) (list 3 4)))
  (check-equal? (matched-pset-removed (list 2 3) PSS-1)
                (list (list (list 1 3)) (list (list 3 2) (list 4 1)) 
                      (list (list 3 4)) (list (list 4 1)) (list (list 4 4))))
  (check-equal? (compare-pos-psetset (list 2 3) PSS-1) 
                (list (list 1 2) (list 2 3) (list 2 3)
                      (list 3 2) (list 2 3) (list 3 4)))
  (check-equal? (merged-obstacles-psetset PSS-1) PSS-6)
  (check-equal? (merged-obstacles PSS-1 PSS-1) PSS-6)
  (check-equal? (merged-duplicates PSS-6 PSS-6)
                (list (list (list 1 3)) (list (list 1 2) (list 3 2) 
                                              (list 4 1) (list 2 3) 
                                              (list 3 4))
                      (list (list 3 2) (list 4 1)) (list (list 4 4))))
  (check-equal? (compared-merged   (list (list 1 2) (list 2 3))
                                   (list  (list (list 1 2) (list 2 3))
                                          (list (list 2 3) (list 3 2) 
                                                (list 2 3) (list 3 4))))
                (list (list 1 2) (list 2 3) (list 2 3) (list 3 2)
                      (list 2 3) (list 3 4)))
  (check-equal? (removed-first  PS-4 PSS-2)
                (list
                 (list (list 4 1) (list 3 2) (list 2 3))
                 (list (list 4 1) (list 3 2) (list 1 2) (list 2 3) (list 3 4))
                 (list (list 1 2) (list 3 2) (list 2 3) (list 3 4))
                 (list (list 3 2) (list 1 2) (list 2 3) (list 3 4))
                 (list (list 2 3) (list 3 4))))
  (check-false (pset-subset?   PS-4 
                               (list
                                (list (list 4 1) (list 3 2) (list 2 3))
                                (list (list 1 2) (list 3 2)
                                      (list 2 3) (list 3 4))
                                (list (list 3 2) (list 1 2)
                                      (list 2 3) (list 3 4))
                                (list (list 2 3) (list 3 4)))))
  (check-equal? (checked-no-duplicate-psetset PSS-2)
                (list (list (list 4 1) (list 3 2) (list 1 2)
                            (list 2 3) (list 3 4))))
  (check-false (ps-not-repeated-in-psetset? PSS-2))
  (check-false (pset-not-repeated-in-psetset? PS-4 PSS-2))
  (check-false (pos-not-repeated-in-psetset? (list 1 2) PSS-2))
  (check-equal? (adjacent-pair-list PS-4) 
                (list
                 (list (list 4 1) (list 3 2))
                 (list (list 3 2) (list 2 3) (list 3 2) (list 2 3))
                 (list (list 1 2) (list 2 3) (list 1 2) (list 2 3))
                 (list (list 2 3) (list 3 4))
                 (list (list 3 4) (list 2 3))
                 (list (list 2 3))))
  (check-equal? (merged-adjacent-duplicates PSS-2)
                (list (list (list 4 1) (list 3 2) (list 1 2) (list 2 3)
                            (list 3 4)) (list (list 3 2) (list 1 2)
                                              (list 2 3) (list 3 4))))
  
  (check-equal? (exact-pset-checked-removed PS-5 PSS-1 PSS-2)
                (list (list (list 1 3)) (list (list 2 3) (list 3 2) 
                                              (list 2 3) (list 3 4)) 
                      (list (list 3 2) (list 4 1)) 
                      (list (list 4 1)) (list (list 4 4))))
  (check-true (pset-subset-check? PS-1 PSS-3))
  (check-false (exact-duplicate-pset? PS-1 PSS-3))
  (check-true (contained-in? PS-1 PS-5))
  (check-true (pset-equal? PS-1 PS-1) )
  (check-false (pset-equal? PS-5 PS-1) )
  (check-equal? (compared-merged PS-1 PSS-2) PS-7)
  (check-equal? (blocks-to-obstacles (list)) empty))










