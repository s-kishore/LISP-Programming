;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname pitchers) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ())))
(require rackunit)
(require rackunit/text-ui)
(require "extras.rkt")

(provide list-to-pitchers
         pitchers-to-list
         pitchers-after-moves
         make-move
         move-src
         move-tgt
         solution)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Data Definition for a Pitcher
(define-struct pitcher (id capacity content))

;; Interpretation :
;; A Pitcher is a (make-pitcher (PosInt NonNegInt NonNegInt))
;; id is the PosInt which represents the unique id of the pitcher
;; content is a number which can be equal to zero or greater
;; than zero, which represents the amount of liquid that pitcher contains
;; capacity is a number which can be equal to zero or greter than 
;; zero, which represents the holding capacity of the pitcher
;; content will always be smaller than the capacity of a pitcher

;; TEMPLATE: 
;; pitcher-fn : Pitcher -> ??
;;(define (pitcher-fn pitcher)
;;  (pitcher-id pitcher)
;;  (pitcher-capacity pitcher)
;;  (pitcher-content pitcher))

;; Data definition for PitchersInternalRep
;; the sequence of PitchersInternalRep is fixed and it is 
;; maintained here by the ids given to them and these 
;; ids are always in ascending order

;; PitchersInternalRep is a NonEmptyListOf<Pitcher> (NELOP) which is one of
;; -- (cons Pitcher empty)    (interp. Only one pitcher in the list)
;; -- (cons Pitcher NELOP)    (interp. First pitcher is followed by a
;;                            non empty list of pitchers represented by NELOP)
                                                                              
;; TEMPLATE :                                                                    
                                                                              
;; nelop-fn : NELOP -> ??                                                     
;;(define (nelop-fn nelop)                                                    
;;  (cond                                                                     
;;    [(empty? (rest nelop)) (... (pitcher-fn (first nelop)))]                
;;    [else                                                                    
;;     (... (pitcher-fn (first nelop))                                          
;;          (nelop-fn (rest nelop)))]))                                     

     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; A PitchersExternalRep is a NonEmpty<ListOfPitcherData> NELOPD 
;; -- (cons PitcherData empty)    (interp. PitchersExternalRep has just one member)
;; -- (cons PitcherData NELOPD) (interp. PitchersExternalRep has its first 
;;                               member as PitcherData and remaining elements
;;                               are other pitcherData represented by NELOPD)

;; TEMPLATE :
;; nelopd-fn : NELOPD -> ??
;;(define (nelopd-fn nelopd)
;;  (cond
;;    [(empty? (rest nelopd)) (... (pitcherdata-fn nelopd))]
;;    [else
;;     (...(pitcherdata-fn (first nelopd))
;;         (lopd-fn (rest nelopd)))]))

;; PitchersExternalRep can also be
;; -- (cons PitcherData LOPD)    (interp. list represented by first element 
;;                               as PitcherData and followed by list of 
;;                               PitcherData represented by LOPD)

;; TEMPLATE 

;; nelopd-fn : NELOPD -> ??
;;(define (nelopd-fn nelopd)
;;  (... (pitcherdata-fn (first nelopd))
;;       (lopd-fn (rest nelopd))))


;; ListOfPitcherData (LOPD) can have below representations
;; -- empty                    (interp. the list of pitcherdata is empty)
;; -- (cons PitcherData LOPD)  (interp. the list where first element is
;;                             a PitcherData while the remaining ones are 
;;                             followed by list of pitcherdata 
;;                             represented by LOPD)

;; TEMPLATE 

;; lopd-fn : LOPD -> ??
;;(define (lopd-fn lopd)
;;  (cond
;;    [(empty? lopd) ...]
;;    [else
;;     (...(pitcherdata-fn (first lopd))
;;         (lopd-fn (rest lopd)))]))

;; Data Definition for pitcherdata
;; A PitcherData can be 
;; -- (list PosInt NonNegInt)
;; Interpretation:
;; PitcherData is a list which has two elements
;; PosInt indicates the amount that pitcher holds
;; NonNegInt indicates the capacity of the pitcher

;; Here, capacity of pitcher is always greater than 
;; the actual content of pitcher

;; TEMPLATE :
;; pitcherdata-fn : PitcherData -> ??
;;(define (pitcherdata-fn pd)
;;  (...(first pd) (rest pd)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Data Definition for move
(define-struct move (src tgt))
;; A Move is (make-move PosInt PosInt)
;; WHERE: src and tgt are different
;; INTERP: (make-move i j) means pour from pitcher i to pitcher j.

;; TEMPLATE :

;; move-fn : Move -> ??
;;(define (move-fn move)
;;  (move-src move)
;;  (move-tgt move))

;; A NonEmptyListOf<Move> (NELOM) is one of
;; -- (cons Move empty)    (interp. there is only one move)
;; -- (cons Move NELOM)    (interp. NELOM has its first member as 
;;                                Move and remaining elements are other
;;                                Move represented by NELOM)

;; TEMPLATE :
;; nelom-fn : NELOM -> ??
;;(define (nelom-fn nelom)
;;  (cond
;;    [(empty? (rest nelom)) (... (move-fn (first nelom)))]
;;    [else
;;     (...(move-fn (first nelom))
;;         (nelom-fn (rest nelom)))]))


;; NELOM can also be represented as 
;; -- (cons Move LOM)

;; TAMPLATE
;; nelom-fn : NELOM -> ??
;;(define (nelom-fn nelom)
;;  (... (move-fn (first nelom))
;;       (lom-fn (rest nelom))))

;; LOM is either
;; -- empty      (interp. list can be empty)
;; -- (cons Move LOM)   (interp. list may have first element as Move
;;                      and remaining elements are LOM)

;; TEMPLATE
;; lom-fn : LOM -> ??
;;(define (lom-fn lom)
;;  (cond
;;    [(empty? lom) ...]
;;    [else
;;     (... (move-fn (first lom))
;;          (lom-fn (rest lom)))]))


;; A NonEmpty<ListOfPitchers> (NELOPS) is one of

;; --(cons PitchersInternalRep empty)         interp : A List containing only one Pitchers
;; --(cons PitchersInternalRep NELOPS)        interp : a List containing a
;;                                 pitchers followed by NELOPS

;; template
;; nelops-fn : NELOPS -> ???
;;(define (nelops-fn nelops)
;;  (cond
;;    [(empty? (rest nelops)) (...(nelop-fn (first nelops)))]
;;    [else
;;     (... (nelop-fn (first nelops))
;;          (nelops-fn (rest nelops)))]))

;; A NonEmpty<ListOfPitchers> (NELOPS) can also be represented as 
;; (cons PitchersInternalRep LOPS) interp : A List containing one pitchers followed by LOPS
;;                               

;; template
;; nelops-fn : NELOPS -> ???
;;(define (nelops-fn nelops)
;;  (... (nelops-fn (first nelops)) (lops-fn (rest nelops))))

;; Data Definition for ListOf<PitchersInternalRep>

;; A LOPS is ListOf<PitchersInternalRep> which is one of

;; -- empty interp : the list is empty
;; -- (cons Pitcher LOP) interp : the list has one pitchers followed by
;; LOPS

;; template
;; lops-fn : LOPS -> ???
;;(define (lops-fn lops)
;;  (cond
;;    [(empty? lops) ...]
;;    [else
;;     (... (nelop-fn (first lops))
;;          (lops-fn (rest lops)))]))


;; A Maybe<ListOf<Move>> is one of

;; -- false             interp : it is false
;; -- ListOf<Move>      interp : it contains a ListOf<Move>
       
;; TEMPLATE
;; mlom-fn : Maybe<ListOf<Move> -> ???
;;(define (mlom-fn mlom)
;;  (cond
;;    [(false ? mlom) ...]
;;    [else ...]))


;; Data Definition of Node

(define-struct node (pitchers moves))

;; A Node is (make-node PitchersInternalRep ListOf<Move>)
;; interpretation:
;; pitchers is the NEListof<Pitcher>
;; moves is the Listof<Move> required to get to that Listof<Pitcher>

;; TEMPLATE :
;; node-fn : Node -> ??
;;(define (node-fn n)
;;  (...(node-pitchers n)
;;      (node-moves n)))

;; A NonEmptyListof<Node> (NELON) is one of

;; -- (cons Node empty)      (interp. where there is only one node in the 
;;                            list and rest is empty)
;; -- (cons Node NELON)      (interp. where first element is Node while
;;                            rest others are represented by NELON which is
;;                            NonEmptyListofNode)

;; TEMPLATE
;; nelon-fn : Node -> ??
;;(define (nelon-fn nelon)
;;  (cond
;;    [(empty? (rest nelon) ... (node-fn (first nelon)))]
;;    [else
;;     (... (node-fn (first nelon))
;;          (nelon-fn (rest nelon)))]))

;; A NonEmptyListof<Node> (NELON) can also be represented as 
;; (cons Node LON)       (interp. where first element is represented by Node 
;;                        while others are represented by Listof<Node>)

;; nelon-fn : Node -> ??
;;(define (nelon-fn nelon)
;;  (node-fn (first nelon))
;;  (lon-fn (rest nelon)))

;; Listof<Node> 

;; LON can be one of
;; -- empty             (interp. where list is empty)
;; -- (cons Node LON)   (interp. where first element is Node
;;                       and remaining ones are followed by representation LON)

;; lon-fn : LON -> ??
;;(define (lon-fn lon)
;;  [(empty? lon) ...]
;;  [(node-fn (first lon))
;;   (lon-fn (rest lon))])

;; A Maybe<Listof<Node>> is one of 
;; -- false              (interp. it is false)
;; -- Listof<Node>       (interp. it has Listof<Node>)

;; TEMPLATE :
;; mlon-fn : MaybeListof<Node> -> ??
;;(define (mlon-fn mlon)
;;  (cond
;;    [(false? mlon) ...]
;;    [else
;;     ...]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CONTANTS
(define ONE 1)
(define ZERO 0)
(define TWO 2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; list-to-pitchers : PitchersExternalRep -> PitchersInternalRep
;; GIVEN : a PitchersExternalRep
;; RETURNS: your internal representation of the given input.
;; Examples : (list-to-pitchers (list (list 6 7)) =>
;; (list (make-pitcher 1 6 7))
;; STRATEGY: Function Composition

(define (list-to-pitchers internalrep) ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;change
  (list-to-pitchers-helper ONE internalrep))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; list-to-pitchers-helper : PosInt PitchersExternalRep -> PitchersInternalRep
;; GIVEN : a PitchersExternalRep which is the list representation 
;; of pitchers
;; WHERE : n is an index of a pitcher, and will increase one at each recursion.
;; RETURNS : a list of pitcher which corresponds to the 
;; internal representation of a pitcher
;; STRATEGY: Structural Decomposition on lrep : PitchersExternalRep

(define (list-to-pitchers-helper n lrep)
  (cons (pitcher-first n (first lrep))
        (pitcher-rest (add1 n) (rest lrep))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; pitcher-first : PosInt pitcherdata -> Pitcher
;; GIVEN : a list pitcherdata where first element is the capacity of the 
;; pitcher while the second is the actual content of the given pitcher 
;; WHERE : n is the context argument which holds the index
;; of a pitcher.
;; Also, the content of the pitchr is always smaller than
;; its capacity
;; RETURNS : a pitcher like the original one but with content
;; and capacity given by a list pitcherdata
;; Examples : (pitcher-first 7 (list 7 6)) =>
;; (make-pitcher 7 7 6)
;; STRATEGY: Structural Decomposition on pitcherdata : pitcherdata
(define (pitcher-first n pitcherdata)
  (make-pitcher n (first pitcherdata) (second pitcherdata)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; pitcher-rest: PosInt LOPD -> ListOf<Pitcher>
;; GIVEN : a list pitcherdata where first element is the capacity of the 
;; pitcher while the second is the actual content of the given pitcher 
;; WHERE : n is the context argument which holds the index of a pitcher.
;; Also, the content of the pitcher is always smaller than
;; its capacity
;; RETURNS : a list of pitcher with index numbers attached to each
;; pitcherdata
;; Examples : (pitcher-rest 9 (list (list 7 6) (list 8 3))) =>
;; (list (make-pitcher 9 7 6) (make-pitcher 10 8 3))
;; STRATEGY: Structural Decomposition on pitcherdata : pitcherdata
(define (pitcher-rest n lopd)
  (cond
    [(empty? lopd) empty]
    [else
     (cons (pitcher-first n (first lopd))
           (pitcher-rest (add1 n) (rest lopd)))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; pitchers-to-list : PitchersInternalRep -> PitchersExternalRep
;; GIVEN: an internal representation of a set of pitchers
;; RETURNS: a PitchersExternalRep that represents them.
;; Examples : (pitchers-to-list (list (make-pitcher 1 8 7)  
;; (make-pitcher 2 9 4))) =>
;; (list (list 8 7) (list 9 4))
;; STRATEGY: Structural Decomposition on Pitchers

(define (pitchers-to-list nelop)
  (cons (pitcher-list (first nelop)) 
        (pitchers-list (rest nelop))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; pitcher-list : Pitcher -> pitcherdata
;; GIVEN : a Pitcher
;; RETURNS : a pitcherdata, which is a list having two elements
;; in which first is the capacity of the pitcher while another one
;; is the content of a pitcher
;; Examples : (pitcher-list (make-pitcher 8 9 5)) =>
;; (list 9 5)
;; STRATEGY: Structural Decomposition on pitcher : Pitcher

(define (pitcher-list p)
  (list (pitcher-capacity p) (pitcher-content p)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; pitchers-list : ListOf<Pitcher> -> ListOf<pitcherdata>
;; GIVEN : List of pitcher
;; RETURNS : a list of pitcherdata, which itself is a 
;; list of two elements where first element is holding capacity of 
;; the pitcher while the second is the actual content of pitcher
;; Examples : (pitchers-list (list (make-pitcher 1 3 2)
;; (make-pitcher 5 9 3))) =>
;; (list (list 3 2) (list 9 3))
;; STRATEGY: HOFC

(define (pitchers-list lop)
  (map
   (lambda (l)
     ;; GIVEN : a pitcher
     ;; RETURNS : a list of pitcherdata with two elements
     ;; where first element is the holding capacity while the other 
     ;; one is actual content of a pitcher
     (pitcher-list l)) lop))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; pitchers-after-moves : PitchersInternalRep ListOf<Move> 
;;                        -> PitchersInternalRep
;; GIVEN: An internal representation of a set of pitchers, and a sequence
;; of moves
;; WHERE: every move refers only to pitchers that are in the set of pitchers.
;; RETURNS: the internal representation of the set of pitchers that should
;; result after executing the given list of moves, in order, on the given
;; set of pitchers.
;; Examples : (pitchers-after-moves (list (make-pitcher 1 5 3)
;; (make-pitcher 2 9 4))
;;                        (list (make-move 1 2))) =>
;; (list (make-pitcher 1 5 0) (make-pitcher 2 9 7))
;; STRATEGY: Structural Decomposition on lom : ListOf<Move>

(define (pitchers-after-moves nelop lom)
  (cond
    [(empty? lom) nelop]
    [else
     (pitchers-after-moves
      (local
        (
         ;; pitcher-at-src : Move PitchersInternalRep -> Pitcher
         ;; Given : a move and pitchers which is NELOP
         ;; RETURNS: Pitcher after src in move is applied
         ;; STRATEGY: Structural Decomposition on lom : ListOf<Move>
         ;;                   and Structural Decomposition on Move
         (define pitcher-at-src
           (get-new-pitcher (move-src (first lom)) nelop))
         ;; pitcher-at-tgt : Move PitchersInternalRep -> Pitcher
         ;; Given : a move and pitchers which is NELOP
         ;; RETURNS: Pitcher after tgt in move is applied
         ;; STRATEGY: Structural Decomposition on lom : ListOf<Move>
         ;;                   and Structural Decomposition on Move
         (define pitcher-at-tgt
           (get-new-pitcher (move-tgt (first lom)) nelop)))
        (pitchers-after-move-helper pitcher-at-src pitcher-at-tgt nelop))
      (rest lom))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; pitchers-after-move-helper : Pitcher Pitcher PitchersInternalRep 
;;                              -> PitchersInternalRep
;; GIVEN : a source pitcher pitcher-at-src, a target pitcher pitcher-at-tgt 
;; pitchers and a list of pitchers 
;; WHERE: pitcher-at-src and pitcher-at-tgt are two context parameters
;; that represent a pitcher from which liquid is to be poured into other,
;; and a pitcher to which the liquid is to be poured respectively.
;; RETURNS : a new list of pitchers after move has been executed
;; Examples : (pitchers-after-move-helper (make-pitcher 1 3 2)
;; (make-pitcher 2 4 3)
;;            (list (make-pitcher 1 3 2) (make-pitcher 2 4 3))) =>
;; (list (make-pitcher 1 3 1) (make-pitcher 2 4 4))
;; STRATEGY: HOFC

(define (pitchers-after-move-helper pitcher-at-src pitcher-at-tgt nelop)
  (map
   ;; Pitcher -> Pitcher
   ;; GIVEN: a pitcher before move
   ;; RETURNS: a pitcher after the move has been executed
   ;; STRATEGY: Function Composition
   (lambda(p)
      (new-pitcher-after-move pitcher-at-src pitcher-at-tgt p))
    nelop))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; new-pitcher-after-move : Pitcher Pitcher Pitcher -> Pitcher
;; GIVEN : a source pitcher, a target pitcher and pitcher 
;; RETURNS : the pitcher same as previous if source and target are not
;; among the pitchers. Else, returns new pitcher after move
;; Examples : (new-pitcher-after-move (make-pitcher 1 3 2) (make-pitcher 2 4 3)
;;                                    (make-pitcher 3 6 5)) =>
;;                                    (make-pitcher 3 6 5)
;; STRATEGY: Structural Decomposition on p : Pitcher

(define (new-pitcher-after-move pitcher-at-src pitcher-at-tgt p)
  (if (check-pitcher-id p pitcher-at-src)
     (make-pitcher (pitcher-id p)
                   (pitcher-capacity p)
                   (content-from-src
                    (pitcher-content p) pitcher-at-tgt))
     (if (check-pitcher-id p pitcher-at-tgt)
     (make-pitcher (pitcher-id p)
                   (pitcher-capacity p)
                   (content-from-tgt
                    (pitcher-content p) (pitcher-capacity p) pitcher-at-src))
     p)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; check-pitcher-id : Pitcher Pitcher -> Boolean
;; GIVEN: two pitchers (here pitchers is not a list pitchers)
;; WHERE: np is a source pithcer or a target pitcher
;; RETURNS: true if the two pitchers have the same pitcher id
;; STRATEGY: Structural Decomposition on p : Pitcher

(define (check-pitcher-id p1 p2)
  (= (pitcher-id p1) (pitcher-id p2)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; content-from-src : NonNegInt Pitcher -> NonNegInt
;; GIVEN : a NonNegInt which is the amount of liquid to be taken 
;; out from source pitcher and the source pitcher
;; RETURNS : a content left after taking out the amount from source
;; Examples : (content-from-src 2 (make-pitcher 1 6 5)) => 1
;; STRATEGY: Structural Decomposition on p : Pitcher

(define (content-from-src cont p)
  (if (>=  (pitcher-capacity p) (+ (pitcher-content p) cont))
      ZERO
      (- cont (- (pitcher-capacity p) (pitcher-content p)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; content-from-tgt : NonNegInt PosInt Pitcher -> NonNegInt
;; GIVEN : a content which is of target pitcher and 
;; capacity which also is of target pitcher and the 
;; target pitcher itself
;; RETURNS : contents of target pitcher after move has been executed
;; Examples : (content-from-tgt 5 10 (make-pitcher 1 3 2)) => 7
;; STRATEGY: Structural Decomposition on p : Pitcher

(define (content-from-tgt cont cap p)
  (if (>= cap (+ cont (pitcher-content p)))
     (+ cont (pitcher-content p))
     cap))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; get-new-pitcher : NonNegInt PitchersInternalReps -> Pitcher
;; GIVEN : an id and list of pitchers
;; RETURNS : a Pitcher just like original which matches the 
;; given id
;; Examples : (get-new-pitcher 1 (list (make-pitcher 1 3 2)
;;             (make-pitcher 2 4 3))) =>
;; (make-pitcher 1 3 2)
;; STRATEGY: HOFC

(define (get-new-pitcher n nelop)
  (foldr
    ( 
     ;; Pitcher -> Pitcher
     ;; Given: a Pitcher
     ;; Returns : the pitcher which matches the id.
     lambda(p y)
      (if (= n (pitcher-id p)) p y))
    empty
    nelop))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; solution : NEListOf<PosInt> PosInt -> Maybe<ListOf<Move>>
;; GIVEN: a list of the capacities of the pitchers and the goal amount
;; RETURNS: a sequence of moves which, when executed from left to right,
;; results in one pitcher (not necessarily the first pitcher) containing
;; the goal amount. Returns false if no such sequence exists.
;; Examples : (solution (list 3 4) 2) => false
;; STRATEGY: Function Composition

(define (solution neloc goal)
  (if (goal-is-bigger-than-capacity? neloc goal)
      false
      (solution-helper (list (make-node (new-pitchers neloc) empty))
                    goal empty)))

;; solution-helper : NEListOf<Node> PosInt ListOf<Pitcher>-> Maybe<ListOf<Move>>
;; GIVEN : non-empty list of Node, a goal amount and list of pitchers which are
;; traversed
;; WHERE : lont is a PitchersInternalRep which is list of nodes traversed
;; AND: nodes is the set of most recent added nodes
;; RETURNS : a sequence of moves which need to be performed in order to 
;; get a pitcher with required amount of goal
;; Termination Argument : At every recursive call, the set of nodes NOT in
;; lont decreases
;; Halting Measure : Recursion terminates when goal is in nodes or the set 
;; difference of nodes and lont is null 
;; (length (set-diff (find-pitchers nodes) lont))
;; Examples : see tests
;; STRATEGY: General Recursion

(define (solution-helper nodes goal lont)
  (local (
          ;; has-goal? : goal NEListOf<Node> -> Maybe<ListOf<Move>>
          ;; Given : Goal and non empty list of nodes
          ;; Returns : true if goal is in the nodes
          ;; and it returns the particular moves of that Pitchers
          ;; if not in nodes, it will return false
          ;; STRATEGY: Function Composition
          (define has-goal? (goal-has-mached? goal nodes))
          ;; pitchers-not-in-td
          ;; : NEListOf<Node> ListOf<Pitcher> -> ListOf<Pitcher>
          ;; Given : a non empty list of nodes and list of traversed Pitchers.
          ;; Returns : empty if all nodes in nodes are in lont else returns
          ;; pitchers which are not in lont
          ;; STRATEGY: Function Composition
          (define pitchers-not-in-td
            (set-diff
             (find-pitchers nodes) lont)))
    (cond
      [(not (false? has-goal?)) (reverse has-goal?)]
      [(empty? pitchers-not-in-td) false]
       [else
       (solution-helper (succerssor-nodes-after-move 
                         (construct-nodes nodes pitchers-not-in-td))
                        goal (append-traversed-nodes lont nodes))])))

;; goal-is-bigger-than-capacity? : NEListOf<PosInt> PosInt -> Boolean
;; GIVEN: non-empty list of capacities of pitchers and the goal amount
;; RETURNS: returns true iff the goal capacity is less than the maximum 
;; capacity of a pitcher
;; Examples : see tests
;; Design Strategy: HOFC
 
(define (goal-is-bigger-than-capacity? neloc goal)
  (andmap
   ;; NonNegInt -> Boolean
   ;; GIVEN: capacity of a pitcher
   ;; RETURNS: true iff capacity is less than goal
   (lambda(q)
     (< q goal))
   neloc))

;; new-pitchers : NEListOf<PosInt> -> PitchersInternalRep
;; GIVEN: a non-empty list of capacities
;; RETURNS: a list of pitchers in their internal representation form
;; Examples : (new-pitchers (list 5 4)) =>
;; (list (make-pitcher 1 5 5) (make-pitcher 2 4 0))
;; STRATEGY: Structural Decomposition on loc : NEListOf<PosInt>

(define (new-pitchers loc)
  (cons (make-pitcher ONE (first loc) (first loc))
        (new-pitchers-helper TWO (rest loc))))

;; new-pitchers-helper: PosInt NEListOf<PosInt> -> PitchersInternalRep
;; GIVEN: a id number, and a non-empty list of capacities of pitchers
;; WHERE: id is the number which indicated pitcher-id in the list
;; RETURNS: list of pitchers in the form of its internal representation
;; Examples : (new-pitchers-helper 1 (list 3 4))
;; (list (make-pitcher 1 3 0) (make-pitcher 2 4 0))
;; STRATEGY: Structural Decomposition on loc : NEListOf<PosInt>

(define (new-pitchers-helper id loc)
  (cond
    [(empty? loc) empty]
    [else (cons (make-pitcher id (first loc) ZERO)
                (new-pitchers-helper (add1 id) (rest loc)))]))

;; goal-has-mached? : PosInt NEListOf<Node> -> MaybeListOf<Move>
;; GIVEN : a goal amount to be achieved and a non-empty list of Node
;; RETURNS : Listof<Move> for particular Node, false if no goal is not
;; present in Node
;; Example : see tests
;; STRATEGY: HOFC
(define (goal-has-mached? goal nodes)
  (local (
          ;; goal-in-moves? : PosInt Node -> Boolean
          ;; GIVEN: a goal amount and a node
          ;; RETURNS: true iff any pitcher contains quantity matching goal
          ;; STRATEGY: Structural Decomposition on n : Node
          (define (goal-in-moves? g n)
            (include-goal? g (node-pitchers n))))
    (foldr
     ;; Node ListOf<Nodes> -> MaybeListOf<Move>
     ;; GIVEN: a Node and a list of nodes for rest
     ;; RETURNS: list of moves of that particular node and
     ;;          false if the goal is not present in the node else
     (lambda (n r) (if (goal-in-moves? goal n) 
                        (node-moves n) r))
      false 
      nodes)))

;; include-goal? : PosInt PitchersInternalRep -> Boolean
;; GIVEN: goal and list of pitchers
;; RETURNS: true if any pitcher from list contains quantity equal goal amount
;; EXAMPLE: see tests
;; DESIGN STRATEGY: HOFC

(define (include-goal? goal lop)
  (ormap
   (lambda (p)
     ;; Pitcher -> Boolean
     ;; GIVEN: a pitcher
     ;; RETURNS: true iff the pitcher contains quantity equal goal amout
     ;; STRATEGY: Function Composition
     (= goal (pitcher-content p)))
   lop))

;; set-diff : ListOf<Pitcher> ListOf<Pitcher> -> ListOf<PitchersInternalRep>
;; GIVEN: a list of Pitchers lp and a list of traversed Pitchers td
;; RETURNS: all elements of lp that are NOT elements in td
;; Examples : see tests
;; STRATEGY: HOFC

(define (set-diff lop lotp)
  (filter
   ;; Pitcher -> Boolean
   ;; GIVEN: a Pitcher 
   ;; RETURNS: true iff the pitcher is not in the given 
   ;;          list of traversed Pitchers
   ;; Design Strategy: Function Composition 
    (lambda (n) (not (my-member? n lotp)))
    lop))

;; my-member? : Pitcher ListOf<Pitcher> -> Boolean
;; GIVEN: a Pitcher and a list of Pitchers
;; RETURNS: true iff the given Pitcher is the member of the given list
;; Examples: see tests
;; STRATEGY: HOFC

(define (my-member? p lop)
  (ormap
   ;; Pitcher -> Boolean
   ;; GIVEN: a Pitcher
   ;; RETURNS: true iff the given pitcher is in lp
   ;; Design Strategy: Function Composition
    (lambda (z) (equal? p z))
    lop))

;; find-pitchers : NEListOf<Nodes> -> ListOf<Pitchers>
;; Given : A Non Empty list of nodes
;; Returns : The Pitchers in those nodes in a list
;; Example : (find-pitchers (make-node INITIAL empty) = (list INITIAL)
;; STRATEGY: HOFC

(define (find-pitchers nodes)
  (map
   (lambda (n)
     ;; Node -> PitchersInternalRep
     ;; Given: A Node
     ;; Returns: Pitchers in that node.
     (node-pitchers n))
   nodes))

;; succerssor-nodes-after-move : NEListOf<Node> -> NEListOf<Node>
;; Given : A non-empty list of nodes
;; Returns : Immediate successors of Nodes when move is applied
;; Example : 
;; (succerssor-nodes-after-move 
;;           (list (make-node (list (make-pitcher 1 3 2) 
;; (make-pitcher 2 4 3)) (list (make-move 1 2))))) =>
;; (list
;; (make-node (list (make-pitcher 1 3 1) (make-pitcher 2 4 4)) 
;; (list (make-move 1 2) (make-move 1 2)))
;; (make-node (list (make-pitcher 1 3 3) (make-pitcher 2 4 2)) 
;; (list (make-move 2 1) (make-move 1 2))))
;; STRATEGY: Structural Decomposition on nodes : NEListOf<Nodes>

(define (succerssor-nodes-after-move nodes)
  (local (
          ;; moves : PitchersInternalRep -> NEListOf<Moves>
          ;; Given : a list of pitchers
          ;; Returns : every possible move for a pitcher
          ;; STRATEGY: Structural Decomposition on Node
          
          (define moves (get-move-paths (node-pitchers (first nodes))))
          
          ;; children : PitchersInternalRep NEListOf<Move> ListOf<Move> -> NEListOf<Node>
          ;; Given : list of pitchers, non-empty list of 
          ;; moves and list of moves 
          ;; Returns : List of Node after applying moves
          ;; STRATEGY: Structural Decomposition on Node
          
          (define children (succerssor-nodes-after-move-helper
                            (node-pitchers (first nodes))
                            moves (node-moves (first nodes)))))
    (cond
      [(empty? (rest nodes)) children]
      [else (append
             children
             (succerssor-nodes-after-move (rest nodes)))])))

;; get-move-paths : PitchersInternalRep -> ListOfMoves
;; GIVEN: list of pitchers
;; RETURNS: list of all possible moves on the given list of pitchers
;; EXAPLE: (get-move-paths (list(make-pitcher 1 5 4)
;; (make-pitcher 2 7 0))) =
;; (list (make-move 1 2))
;; DESIGN STRATEGY: Function Composition
(define (get-move-paths lop)
  (get-move-paths-list (get-src lop) 
                       (get-tgt lop)))

;; get-src : PitchersInternalRep -> PitchersInternalRep
;; GIVEN: list of pitchers
;; RETURNS: possible pitchers from list
;; EXAMPLE: see tests
;; DESIGN STRATEGY: HOFC

(define (get-src nelop)
  (foldr
   (lambda (p r)
     ;; Pitcher LOP -> PitchersInternalRep
     ;; Given : A Pitcher and LOP for rest
     ;; Returns : Pitchers for that list.
     ;; STRATEGY: Function Composition
     (append (check-src p) r))
   empty
   nelop))

;; check-src : Pitcher -> PitchersInternalRep
;; GIVEN: a pitcher
;; RETURNS: a list contaning given pitcher if it is not empty else empty
;; EXAMPLE: see tests
;; DESIGN STRATEGY: Structural DEcomposition on p : Pitcher
(define (check-src p)
  (if (> (pitcher-content p) 0)
      (list p)
      empty))

;; get-tgt : PitchersInternalRep -> PitchersInternalRep
;; GIVEN: list of pitchers
;; RETURNS: all possible target pitchers from list
;; EXAMPLE: see tests
;; DESIGN STRATEGY: HOFC

(define (get-tgt nelop)
  (foldr
   (lambda (p r)
     ;; Pitcher LOP -> PitchersInternalRep
     ;; Given : A Pitcher and LOP for rest
     ;; Returns : Pitchers for that list.
     (append (check-tgt p)
             r))
   empty
   nelop))

;; check-tgt : Pitcher -> PitchersInternalRep
;; GIVEN: a pitcher
;; RETURNS: a list if pitcher content minus
;; pitcher capacity is greater than zero
;; EXAMPLE: see tests
;; DESIGN STRATEGY: Structural DEcomposition on p : Pitcher
(define (check-tgt p)
  (if (> (- (pitcher-capacity p) (pitcher-content p)) 0)
      (list p)
      empty))

;; get-move-paths-list : PitchersInternalRep PitchersInternalRep -> ListOf<Move>
;; GIVEN: a list of source pitchers and a list of target pitchers
;; RETURNS: list of all moves on src and tgt pitchers
;; EXAMPLE: (get-move-paths-list (list (make-pitcher 1 3 2))
;; (list (make-pitcher 2 4 3))) =>
;; (list (make-move 1 2))
;; DESIGN STRATEGY: HOFC

(define (get-move-paths-list source target)
  (foldr
   (lambda (src r)
     ;; Pitcher PitchersInternalRep -> ListOf<Move>
     ;; Given : Pitcher and a list of pitchers for rest
     ;; Returns : ListOfMove for that pitcher
     (append (get-move-paths-list-helper (pitcher-id src) target)
             r))
   empty
   source))
 
;; get-move-paths-list-helper: PosInt PitchersInternalRep -> ListOf<Move>
;; GIVEN: id of source pitcher and list of target pitchers
;; RETURNS: list of all possible moves on given source pitcher and list
;; of target pitchers
;; EXAMPLE: (get-move-paths-list-helper 3 (list (make-pitcher 1 3 2)
;; (make-pitcher 2 4 3))) =>
;; (list (make-move 3 1) (make-move 3 2))
;; DESIGN STRATEGY: HOFC

(define (get-move-paths-list-helper id target)
  (foldr
   ;; Pitcher ListOf<Move> -> ListOf<Move>
   ;; Given : Pitcher and ListOfmoves for rest
   ;; Returns : a list of move for that pitcher
   ;; STRATEGY: Function Composition
   (lambda (tgt r)
   (append (possible-moves id tgt) r))
   empty
   target))

;; possible-moves : PosInt Pitcher -> ListOf<Move>
;; GIVEN: id of source pitcher and target pitcher
;; RETURNS: list of all possible moves on given source pitcher 
;; and target pitcher
;; EXAMPLE: (possible-moves 1 (make-pitcher 1 3 2))=> empty
;; DESIGN STRATEGY: Structural Decomposition on p: Pitcher

(define (possible-moves id p)
  (if (= id (pitcher-id p))
      empty
      (cons (make-move id (pitcher-id p)) empty)))

;; succerssor-nodes-after-move-helper : 
;; PitchersInternalRep Listof<Move> NEListOf<Move> -> NEListOf<Node>
;; Given : Pitchers ,list of all Possible Moves for that pitchers
;; and the Moves of that pitchers.
;; Returns : The immediate List of Nodes obtained after applying moves
;; to those pitchers
;; Examples : 
;; (succerssor-nodes-after-move-helper (list (make-pitcher 1 3 2)
;; (make-pitcher 2 4 3)) 
;; (list (make-move 1 2)) (list (make-move 1 2)))=>
;; (list (make-node (list (make-pitcher 1 3 1) (make-pitcher 2 4 4))
;; (list (make-move 1 2) (make-move 1 2))))
;; STRATEGY: HOFC 

(define (succerssor-nodes-after-move-helper p lom pms)
  (local (
          ;;first-node : PitchersInternalRep Move ListOfMoves -> Node
          ;;Given: Pitchers , a move and the parent moves
          ;;Returns : A Node corressponding to that move.
          ;;STRATEGY: Function Composition
          (define (first-node pt m lms)
            (make-node
             (pitchers-after-moves pt (list m))
             (append (list m) lms))))
    (map
     ;;PitchersInternalRep Move -> Node
     ;;Given: a move
     ;;Returns : A Node corressponding to that move.
     ;;STRATEGY: Function Composition
     (lambda (m) (first-node p m pms))
     lom)))

;; construct-nodes : NEListOf<Node> NEListOf<Pitcher> -> NEListOf<Node>
;; GIVEN : a non-empty list of node and a non-empty list of pitcher.
;; Returns : a non-empty list of nodes of the given list of pitchers.
;; Examples : see tests
;; STRATEGY: Structural Decomposition on nelop : NEListOf<Pitcher>.

(define (construct-nodes nodes nelop)
  (local (
          ;; check-nodes : PitchersInternalRep ListOf<Node> -> Maybe<Node>
          ;; Given : Pitchers and List Of Node
          ;; Returns : False iff the Pitchers is not in the ListOfNode
          ;; else returns the node of that pitchers
          ;; STRATEGY : Function Composition
          
          (define check-nodes (has-node (first nelop) nodes)))
    (cond
      [(empty? (rest nelop)) (if (false? check-nodes) empty
                             (cons check-nodes empty))]
      [else (if (false? check-nodes)
                (construct-nodes nodes (rest nelop))
                (cons check-nodes (construct-nodes nodes (rest nelop))))]))) 

;; has-node : PitchersInternalRep NEListOf<Node> -> Maybe<Node>
;; GIVEN : a list of pitcher and a non-empty list of nodes
;; RETURNS : false only if pitcher is not in ListofNode 
;; else returns node of a pitcher
;; Example : see tests
;; STRATEGY: HOFC

(define (has-node pitchers n)
  (foldr
   ;; Node ListOf<Node> -> Maybe<Node>
   ;; GIVEN : A Node and a list of Node for rest
   ;; RETURNS : true if the node is in the list of pitcher 
   (lambda (n r)
     (if (equal? pitchers (node-pitchers n)) n r))
   false
   n))

;; append-traversed-nodes :  PitchersInternalRep NEListOf<Node> -> PitchersInternalRep
;; GIVEN : A traversed list of pitchers td and a non-empty list of nodes
;; WHERE : td is the context argument which represents the 
;; listofpitchers already traversed.
;; RETURNS : A new non-empty list of pitchers where the given nodes pitchers are
;; appended to the given list
;; Examples : see tests
;; STRATEGY: Structural Decomposition on nodes : NEListOf<Nodes>

(define (append-traversed-nodes td nodes)
  (cond
    [(empty? (rest nodes)) (append td (list (node-pitchers (first nodes))))]
    [else (cons
           (node-pitchers (first nodes))
           (append-traversed-nodes td (rest nodes)))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; EXAMPLES FOR TESTS
(define TEST-CASE-1 (list 10 7 3))
(define GOAL-TEST-CASE-1 5)
(define TEST-CASE-2 (list 8 5 3))
(define GOAL-TEST-CASE-2 4)

(define MOVES-TEST-CASE-1 (list (make-move 1 2) 
                                (make-move 2 3) 
                                (make-move 3 1) 
                                (make-move 2 3) 
                                (make-move 3 1) 
                                (make-move 2 3)
                                (make-move 1 2) 
                                (make-move 2 3)))

(define MOVES-TEST-CASE-2 (list (make-move 1 2) 
                                (make-move 2 3)
                                (make-move 3 1)
                                (make-move 2 3)
                                (make-move 1 2)
                                (make-move 2 3)))

(define GOAL-TEST-EXAMPLE
  (list
   (make-node
    (list (make-pitcher 1 10 5) (make-pitcher 2 7 0)
          (make-pitcher 3 3 3))
    (list (make-move 1 3)))))

(define GOAL-TEST-EXAMPLE-SOLN 
  (list (make-move 1 3)))

(define GET-CHILDREN-EXAMPLE-1 
  (list
   (make-node
    (list (make-pitcher 1 8 3) (make-pitcher 2 5 5) (make-pitcher 3 3 0))
    (list (make-move 1 2)))
   (make-node
    (list (make-pitcher 1 8 5) (make-pitcher 2 5 0) (make-pitcher 3 3 3))
    (list (make-move 1 3)))))

(define NELOP-EXAMPLE
  (list
   (list (make-pitcher 2 5 5)(make-pitcher 1 8 3)(make-pitcher 3 3 0))
   (list (make-pitcher 2 5 0)(make-pitcher 1 8 5)(make-pitcher 3 3 3))))

(define SOLVE-FALSE-CASE-EXAMPLE (list 7 5 10))
(define SOLVE-FALSE-CASE-GOAL-AMOUNT 1)

(define SAMPLE-GOAL 5)

(define PITCHERS-1 (list (make-pitcher 1 5 3) (make-pitcher 2 9 4)))
(define MOVES-1 (list (make-move 1 2)))
(define RESULT-1 (list (make-pitcher 1 5 0) (make-pitcher 2 9 7)))

(define SAMPLE-PITCHER-1 (make-pitcher 1 6 5))
(define CONTENT-TGT-1 5)
(define CAPACITY-TGT-1 10)
(define SAMPLE-PITCHER-2 (make-pitcher 1 10 7))
(define PITCHER-1 (make-pitcher 1 4 3))
(define PITCHER-2 (make-pitcher 2 5 3))
(define PITCHER-3 (make-pitcher 5 9 4))
(define PITCHERS-TO-LIST-REPRESENTATION
  (list (make-pitcher 1 8 7)(make-pitcher 2 4 3)))
(define PITCHERS-TO-LIST (list (list 8 7) (list 4 3)))
(define LIST-TO-PITCHERS-LIST (list (list 7 6) (list 9 7)))
(define LIST-TO-PITCHERS-REPRESENTATION (list (make-pitcher 1 7 6)
                                              (make-pitcher 2 9 7)))
(define PITCHER-5 (make-pitcher 1 10 7))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tests :

;;tests for list-to-pitchers
(begin-for-test 
  (check-equal?
   (list-to-pitchers LIST-TO-PITCHERS-LIST)
   LIST-TO-PITCHERS-REPRESENTATION
   "When list representation is given, function must return internal 
    representation"))

;;tests for pitchers-to-list
(begin-for-test 
  (check-equal? 
   (pitchers-to-list PITCHERS-TO-LIST-REPRESENTATION)
   PITCHERS-TO-LIST
   "When Pitchers are given to function, PitchersExternalRep must be returned"
   ))

;;tests for moves-tests
(begin-for-test 
  (check-equal?
   (pitchers-after-moves PITCHERS-1 MOVES-1)
   RESULT-1
   "When move is applied to a list of pitchers, resultant list must be 
    returned")
  
  (check-equal?
   (content-from-src TWO SAMPLE-PITCHER-1)
   ONE 
   "Test to check if content gets returned properly from source when removed") 
  
  (check-equal?
   (content-from-tgt CONTENT-TGT-1 CAPACITY-TGT-1 PITCHER-5)
   CAPACITY-TGT-1
   "Test to check if content gets removed properly when removed from target ")
  
  (check-equal?
   (new-pitcher-after-move PITCHER-1 PITCHER-2 PITCHER-3)
   PITCHER-3
   "Test to check if ids dont match, the pitcher must return as is"))

;;tests for solution
(begin-for-test
  
  (check-equal?
    (solution (list 3 4) 5) false)

  (check-equal?
    (solution TEST-CASE-1 GOAL-TEST-CASE-1)
    MOVES-TEST-CASE-1
    "solution should return set of moves to be performed to achieve
    the goal amount")
  
  (check-equal?
    (solution TEST-CASE-2 GOAL-TEST-CASE-2)
    MOVES-TEST-CASE-2
    "test case for the other combinations of pitchers and other goal amount")
  
  (check-equal?
    (construct-nodes GET-CHILDREN-EXAMPLE-1 NELOP-EXAMPLE)
    empty
    "Result is empty because nodes and nelop are not equal")
  
  (check-equal?
    (goal-has-mached? SAMPLE-GOAL GOAL-TEST-EXAMPLE)
    GOAL-TEST-EXAMPLE-SOLN
    "Function must return list of moves as the goal has been reached")
  
  (check-equal?
    (solution SOLVE-FALSE-CASE-EXAMPLE SOLVE-FALSE-CASE-GOAL-AMOUNT)
    false
    "When goal amount is greater than capacity, function returns false"))
