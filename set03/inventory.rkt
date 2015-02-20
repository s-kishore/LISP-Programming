;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname inventory) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ())))
(require rackunit/text-ui)
(require rackunit)
(require "extras.rkt")

; Invetory containing a set of functions for manipulating the inventory of a 
; bookstore, represented as a list of books. It contains a list of functions
; that help in manuplating of stock and extracting of information from current
; stock in the book store.
; bookstore periodically reorders books from the publisher. For each book, there
; is at most one outstanding reorder. If there is no reorder, the reorder status
; must represent this information. If there is a reorder, the re-order status 
; contains the number of days until the the next shipment of this book is 
; expected to arrive, and the number of copies expected to arrive at that time.

(provide make-reorder
         make-book
         make-line-item
         inventory-potential-profit 
         inventory-total-volume  
         price-for-line-item
         fillable-now?
         days-til-fillable
         price-for-order
         inventory-after-order
         increase-prices
         reorder-present?
         make-empty-reorder)
;_______________________________________________________________________________
;DATA DEFINITIONS:

(define-struct book (isbn title author publshr uprice ucost copies reordrst 
                          cuft))

; A Book is a 
;(make-book Integer String String String NonNegInt NonNegInt Integer Reorders
;                                                                       Real)

;INTERPRETATION:

;    isbn -> is the international standard book number that uniquely identifies
;            each book
;   title -> is the title of the book
;  author -> is the name of the author of the book
; publshr -> is the name of the publisher of that book
;  uprice -> is the unit price of the book given by value in dollars and cents
;            multiplied by 100 (i.e $14.99 -> 1499)
;   ucost -> is the unit cost of the book to the book store. Calculated using 
;            the same method as unit price
;  copies -> is the number copies available in stock
; reordrst-> is the reorder status of the book which by itself is a structure
;    cuft -> is the volume of space occupied by the book in cubic feet

; TEMPLATE:
; book-fn : book -> ??
; (define (book-fn b)
;   (...
;    (book-isbn b)
;    (book-title b)
;    (book-author b)
;    (book-publshr b)
;    (book-uprice b)
;    (book-ucost b)
;    (book-copies b) 
;    (book-reordrst b)
;    (book-cuft b)))

;_______________________________________________________________________________

(define-struct reorders (present? nxtshpmnt newcopies))

; A Reorders is a 
;(make-reorder Character PosInt PosInt)

; INTERPRETATION:
;  present? -> is the indicator, weather there has been a reorder or not
;      true -> Reorder placed
;     false -> Reorder not placed
; nxtshpmnt -> is the number of days until the the next shipment of a particular
;              book is expected to arrive
; newcopies -> is the number of copies expected to arrive

; TEMPLATE:
; (define (reorders-fn r)
;   (...
;    (reorders-present? r)
;    (reorders-nxtshpment r)
;    (reorders-newcopies r))

;_______________________________________________________________________________

(define-struct line-item (isbn quantity))

; A LineItem is a
;(make-line-item Integer Integer)
;     isbn -> international standard book number that uniquely identifies
;             each book
; quantity -> is the number of a copies of a particular book needed 

; TEMPLATE:
; line-item-fn : LineItem -> ??
; (define (line-item-fn lineitem1)
;   (... (line-item-isbn lineitem1)
;        (line-item-quantity lineitem1)))

;_______________________________________________________________________________
; A MaybeInteger is one of:
; -- Integer
; -- false

;_______________________________________________________________________________
; An order is a ListOf<LineItem> and is one of
; -- empty
; -- (cons LineItem Order)

; INTERPRETATION:
; empty                        -- an empty order
; (cons LineItem Order)        -- an order containing the line item
;
; TEMPLATE:
; order-fn : Order -> ??
; (define (order-fn order1)
;   (cond
;     [(empty? order1)...]
;     [else (...
;            (first order1)
;            (order-fn (rest order1)))]))
;_______________________________________________________________________________
; An Inventory is a ListOf<Books> and is one of
; -- empty
; -- (cons Book Inventory)
; INTERPRETATION:
; empty                       -- an empty inventory
; (cons Book Inventory)       -- Inventory contains books
;
; TEMPLATE:
; inventory-fn : Inventory -> ??
; (define (inventory-fn inv)
;   (cond
;     [(empty? inv)...]
;     [else
;      ( ...(first inv)
;           (inventory-fn (rest inv)))]))

;_______________________________________________________________________________

;CONSTANTS
(define NUMBER-ONE 1)
(define NOT-FILLABLE 1000.5)

; TEST CASE CONSTANTS: 
(define BOOK1 (make-book 0474541342 "FamousFive" "Enid Bly" "Hodder" 1800 1500
                         6 (make-reorders false 0 0) 108))

(define BOOK2 (make-book 0473123344 "WingsofFire" "DAK" "INDIA" 5000 4000
                         1 (make-reorders true 15 5) 87))

(define BOOK3 (make-book 0874512344 "Fire" "DAK" "INDIA" 4000 3500
                         3 (make-reorders true 5 5) 87))

(define BOOK2-AFT-RISE-10 (make-book 0473123344 "WingsofFire" "DAK" "INDIA" 5500
                                     4000 1 (make-reorders true 15 5) 87))

(define BOOK3-AFT-RISE-10 (make-book 0874512344 "Fire" "DAK" "INDIA" 4400 3500
                                     3 (make-reorders true 5 5) 87))

(define BOOK1-COPIES-5 (make-book 0474541342 "FamousFive" "Enid Bly" "Hodder" 
                                  1800 1500 5 (make-reorders false 0 0) 108)) 

(define 3-BOOK-INVENTORY 
  (cons BOOK1 (cons BOOK2 (cons BOOK3 empty))))

(define 2-BOOK-INVENTORY 
  (cons BOOK1 (cons BOOK2 empty)))

(define 3-BOOK-INVENTORY-AFT-ORDER 
  (cons BOOK1-COPIES-5
        (cons BOOK2 
              (cons (make-book 0874512344 "Fire" "DAK" "INDIA" 4000 3500 2 
                               (make-reorders true 5 5) 87)empty))))

(define 3-BOOK-INVENTORY-AFT-RISE-10
  (cons BOOK1 (cons BOOK2-AFT-RISE-10
                    (cons BOOK3-AFT-RISE-10 empty))))

(define LINEITEM-UNAVAILABLE (make-line-item 04745413229 5))
(define LINEITEM-UNAVAILABLE2 (make-line-item 04745418829 3))
(define LINEITEM-UNAVAILABLE-AFT-SHPMNT (make-line-item 0473123344 25))

(define LINEITEM-AVAILABLE (make-line-item 0474541342 1))
(define LINEITEM-AVAILABLE2 (make-line-item 0874512344 1))
(define LINEITEM-AVAILABLE-AFT-SHPMNT (make-line-item 0874512344 6))
(define LINEITEM-AVAILABLE-AFT-SHPMNT2 (make-line-item 0473123344 6))

(define ORDER-UNAVAILABLE (cons LINEITEM-UNAVAILABLE (cons LINEITEM-AVAILABLE
                                                           empty)))
(define ORDER-AVAILABLE (cons LINEITEM-AVAILABLE (cons LINEITEM-AVAILABLE2
                                                       empty)))

(define ORDER-UNAVAILABLE-AFT-SHPMNT (cons LINEITEM-AVAILABLE 
                                           (cons LINEITEM-UNAVAILABLE-AFT-SHPMNT
                                                 empty)))
(define ORDER-AVAILABLE-AFT-SHPMNT 
  (cons LINEITEM-AVAILABLE 
        (cons LINEITEM-AVAILABLE-AFT-SHPMNT
              (cons LINEITEM-AVAILABLE-AFT-SHPMNT2
                    empty))))

;_______________________________________________________________________________
; calc-potential-profit: Inventory ->  Integer
;    GIVEN: an inventory
;  RETURNS: the total profit, in USD*100, for all the items in stock(i.e., how 
;           much the bookstore would profit if it sold all books in inventory).
; EXAMPLES: (calc-potential-profit 2-BOOK-INVENTORY) -> 100
;           (calc-potential-profit 3-BOOK-INVENTORY) -> 73
; STRATEGY: Function Composition


(define (calc-potential-profit invtry)
  (+ (profit-from-book-copies(get-first-list invtry))
     (if (empty? (get-rest-list invtry))
         0
         (calc-potential-profit (get-rest-list invtry)))))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions


;_______________________________________________________________________________
; profit-from-book-copies: Book ->  Integer
;    GIVEN: an inventory
;  RETURNS: the total profit, in USD*100, for all the items in stock(i.e., how 
;           much the bookstore would profit if it sold all books in inventory).
; EXAMPLES: (profit-from-book-copies BOOK1) -> 100
; STRATEGY: Structural decomposition on book1 : Book


(define (profit-from-book-copies book1)
  (/ (* (book-copies book1) 
        (- (book-uprice book1) (book-ucost book1))) 100))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; inventory-potential-profit : Inventory ->  Integer
;    GIVEN: an inventory
;  RETURNS: the total profit, in USD*100, for all the items in stock(i.e., how 
;           much the bookstore would profit if it sold all books in inventory).
; EXAMPLES: Refer testcases for example
; STRATEGY: Function Composition

(define (inventory-potential-profit invtry)
  (cond [(empty? invtry) 0]
        [else (calc-potential-profit invtry)]))

;TEST CASES:
(begin-for-test 
  (check-equal? (inventory-potential-profit 3-BOOK-INVENTORY)
                43
                "Incorrect answer. Wrong profit calculation")
  (check-equal? (inventory-potential-profit empty)
                0
                "Incorrect Answer. Inventory Empty, Profit should be 0"))


;_______________________________________________________________________________
; inventory-total-volume : Inventory -> Real
;    GIVEN: an inventory
;  RETURNS: the total volume needed to store all the books in the inventory
; EXAMPLES: Refer testcases for example
; STRATEGY: Function Composition

(define (inventory-total-volume invtry)
  (if (empty? invtry)
      0
      (calc-volume-of-inventory invtry)))

;TEST CASES:
(begin-for-test
  (check-equal? (inventory-total-volume 3-BOOK-INVENTORY)
                996
                "Incorrect Answer. Inventory volume should be 996")
  (check-equal? (inventory-total-volume empty)
                0
                "Incorrect Answer. Inventory Empty, Profit should be 0"))

;_______________________________________________________________________________
; calc-volume-of-inventory : Inventory -> Real
;    GIVEN: an inventory
;  RETURNS: the total volume needed to store all the books in the inventory
; EXAMPLES: (calc-volume-of-inventory 3-BOOK-INVENTORY)-> 568 GRIZ
;           (calc-volume-of-inventory INVTRY2)-> 132  GRIZ -real value
; STRATEGY: Function Composition


(define (calc-volume-of-inventory invtry)
  (+ (volume-of-book-copies (get-first-list invtry))
     (if (empty? (get-rest-list invtry))
         0
         (calc-volume-of-inventory (get-rest-list invtry)))))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; volume-of-book-copies : Book -> Real
;    GIVEN: an Book
;  RETURNS: the total volume needed to store all the copies of one book
; EXAMPLES: (volume-of-book-copies BOOK1)-> 568 GRIZ
;           (calc-volume-of-inventory BOOK2)-> 132  GRIZ -real value
; STRATEGY: Structural decomposition on book1 : Book

(define (volume-of-book-copies book1)
  (* (book-copies book1) (book-cuft book1)))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; price-for-line-item : Inventory LineItem -> MaybeInteger
;    GIVEN: an inventory and a line item
;  RETURNS: the price for that line item (the quantity times the unit price for
;           that item). Returns false if that isbn does not exist in inventory.
; EXAMPLES: (price-for-line-item 3-BOOK-INVENTORY LINEITEM-UNAVAILABLE)-> false
;           (price-for-line-item 3-BOOK-INVENTORY LINEITEM-AVAILABLE)-> 132 
; STRATEGY: Structural Decomposition on lineitem1 : Line-Item

(define (price-for-line-item invtry lineitem1)
  (if (or (empty? lineitem1) (empty? invtry))
      false
      (price-of-line-item-helper invtry 
                                 (line-item-isbn lineitem1)
                                 (line-item-quantity lineitem1))))

;TEST CASES:
(begin-for-test
  (check-equal? (price-for-line-item 3-BOOK-INVENTORY LINEITEM-AVAILABLE)
                1800
                "Incorrect Answer. Inventory volume should be 1800")
  
  (check-equal? (price-for-line-item 3-BOOK-INVENTORY empty)
                false
                "Incorrect Answer. Lineitem empty.")
  
  (check-equal? (price-for-line-item 3-BOOK-INVENTORY LINEITEM-UNAVAILABLE)
                false
                "Incorrect Answer. Lineitem not available."))

;_______________________________________________________________________________
; price-of-line-item-helper : Inventory Integer PosInt -> MaybeInteger
;    GIVEN: an inventory and Lineitem's isbn and quantity
;  RETURNS: the price for that line item (the quantity times the unit price for
;            that item). Returns false if that isbn does not exist in inventory.
; EXAMPLES: (price-of-line-item-helper 3-BOOK-INVENTORY 0474521344 1)-> false
;           (price-of-line-item-helper 3-BOOK-INVENTORY 0474541342 2)-> 1800 
; STRATEGY: Function Composition

(define (price-of-line-item-helper invtry isbn quantity)
  (cond [(empty? (get-book invtry isbn))
         false]
        
        [else (multiply-quantity-price (get-book invtry isbn)
                                       quantity)]))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; multiply-quantity-price : Book PosInt -> PosInt
;    GIVEN: a book and the quantity required
;  RETURNS: the price for that line item (the quantity times the unit price for
;            that item).
; EXAMPLES: (multiply-quantity-price BOOK1 1)-> false
; STRATEGY: Structural decomposition on book1 : Book

(define (multiply-quantity-price book1 quantity )
  (* quantity (book-uprice book1)))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; fillable-now? : Order Inventory -> Boolean.
;    GIVEN: an order and an inventory
;  RETURNS: true iff there are enough copies of each book on hand to fill the 
;           order.
; EXAMPLES: (fillable-now? ORDER-UNAVAILABLE 3-BOOK-INVENTORY )-> false
;           (fillable-now? ORDER-AVAILABLE 3-BOOK-INVENTORY )-> true
; STRATEGY: Function Composition  

(define (fillable-now? order invtry)
  (if (or (empty? order) (empty? invtry))
      false
      (fillable-now-helper order invtry)
      ))

;TEST CASES:
(begin-for-test
  (check-equal? (fillable-now? ORDER-AVAILABLE 3-BOOK-INVENTORY)
                true
                "Incorrect Answer. Order is available")
  
  (check-equal? (fillable-now? ORDER-UNAVAILABLE 3-BOOK-INVENTORY)
                false
                "Incorrect Answer. order is unavailable.")
  
  (check-equal? (fillable-now? ORDER-UNAVAILABLE empty)
                false
                "Incorrect Answer. Inventory is empty."))

;_______________________________________________________________________________
; fillable-now-helper : Order Inventory -> Boolean.
;    GIVEN: an order and an inventory
;  RETURNS: true iff there are enough copies of each book on hand to fill the 
;           order.
; EXAMPLES: (fillable-now-helper ORDER-UNAVAILABLE 3-BOOK-INVENTORY )-> false
;           (fillable-now-helper ORDER-AVAILABLE 3-BOOK-INVENTORY )-> true
; STRATEGY: Function Composition  


(define (fillable-now-helper order invtry)
  (if (empty? order)
      true
      (and (is-book-in-stock (get-first-list order) invtry)
           (fillable-now-helper (get-rest-list order) invtry))))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; days-til-fillable : Order Inventory -> MaybeInteger
;    GIVEN: an order and an inventory
;  RETURNS: the number of days until the order is fillable, assuming all the 
;           shipments come in on time.  Returns false if there won't be enough
;           copies of few book,even after the next shipment of that book comes
; EXAMPLES: (days-til-fillable ORDER-AVAILABLE 3-BOOK-INVENTORY) -> 0
;           (days-til-fillable ORDER-UNAVAILABLE 3-BOOK-INVENTORY) -> false
; STRATEGY: Function Composition  

(define (days-til-fillable order invtry)
  (if(fillable-now? order invtry)
     0
     (days-till-fillable-helper order invtry)))

;TEST CASES:
(begin-for-test
  (check-equal? (days-til-fillable ORDER-AVAILABLE 3-BOOK-INVENTORY)
                0
                "Incorrect Answer. Order is fillable today.Value should be 0")
  
  (check-equal? (days-til-fillable ORDER-UNAVAILABLE-AFT-SHPMNT 
                                   3-BOOK-INVENTORY)
                false
                "Incorrect Answer. order is unavailable.")
  
  (check-equal? (days-til-fillable ORDER-AVAILABLE-AFT-SHPMNT 3-BOOK-INVENTORY)
                15
                "Incorrect Answer. Order fillable after 15 days."))

;_______________________________________________________________________________
; days-till-fillable-helper : Order Inventory -> MaybeInteger
;    GIVEN: an order and an inventory
;  RETURNS: the number of days until the order is fillable, assuming all the 
;           shipments come in on time.  Returns false if there won't be enough
;           copies of few book,even after next shipment of that book comes in
; EXAMPLES: (days-till-fillable-helper ORDER-AVAILABLE 3-BOOK-INVENTORY) -> 0
;           (days-till-fillable-helper ORDER-UNAVAILABLE-AFT-SHPMNT 
;                                                      3-BOOK-INVENTORY) -> 5
; STRATEGY: Function Composition 


(define (days-till-fillable-helper order invtry)
  (if (= (calc-days-till-fillable order invtry) NOT-FILLABLE)
      false
      (calc-days-till-fillable order invtry)))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; days-till-fillable-helper : Order Inventory -> Integer
;    GIVEN: an order and an inventory
;  RETURNS: the number of days until the order is fillable. Returns NOT-FILLABLE
;           if there wont be enough copies of few book,even after the next
;           shipment of that book comes in
; EXAMPLES: (calc-days-till-fillable ORDER-AVAILABLE 3-BOOK-INVENTORY) -> 0
;           (calc-days-till-fillable ORDER-UNAVAILABLE-AFT-SHPMNT 
;                                                      3-BOOK-INVENTORY) -> 15
; STRATEGY: Function Composition 

(define (calc-days-till-fillable order invtry)
  (max (if (integer? (calc-days-till-fillable-helper (get-first-list order) 
                                                     invtry))
           (calc-days-till-fillable-helper (get-first-list order) invtry)
           NOT-FILLABLE)
       (if (empty? (get-rest-list order))
           0
           (calc-days-till-fillable (get-rest-list order) invtry))))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; calc-days-till-fillable-helper : LineItem Inventory -> MaybeInteger
;    GIVEN: an order and an inventory
;  RETURNS: the number of days until the order is fillable. Returns NOT-FILLABLE
;           if there wont be enough copies of few book,even after the next
;           shipment of that book comes in
; EXAMPLES: (calc-days-till-fillable-helper LINEITEM-AVAILABLE
;                                                      3-BOOK-INVENTORY) -> 0
;           (calc-days-till-fillable-helper LINEITEM-AVAILABLE-AFT-SHPMNT 
;                                                      3-BOOK-INVENTORY) -> 5
; STRATEGY: Structural Decomposition on lineitem1 : Line-Item

(define (calc-days-till-fillable-helper lineitem1 invtry)
  (is-quantity-enough-after-ro invtry 
                               (line-item-isbn lineitem1)
                               (line-item-quantity lineitem1)))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; is-quantity-enough-after-ro : Inventory Integer PosInt -> MaybeInteger
;    GIVEN: an Invetory, isbn and quatity required
;  RETURNS: the number of days until the order is fillable. Returns false
;           if there wont be enough copies of few book,even after the next
;           shipment of that book comes in
; EXAMPLES: (is-quantity-enough-after-ro 3-BOOK-INVENTORY 0474541342 2) -> 0
;           (calc-days-till-fillable-helper 3-BOOK-INVENTORY 0473123344 4) -> 5
; STRATEGY: Function Composition


(define (is-quantity-enough-after-ro invtry isbn quantity)
  (if (>= (quantity-after-reorder (get-book invtry isbn))
          quantity)
      (get-days-nxtshipment (book-reordrst (get-book invtry isbn)))
      false))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; get-days-nxtshipment : Reorder -> NonNegInt
;    GIVEN: a Reorder
;  RETURNS: the number of days the next shipment arrives.
; EXAMPLES: (get-days-nxtshipment (make-reorders true 2 5) -> 2
; STRATEGY: Structural Decomposition reorders1 : Reorder

(define (get-days-nxtshipment reorders1)
  (reorders-nxtshpmnt reorders1))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; quantity-after-reorder : Book -> NonNegInt
;    GIVEN: a Book
;  RETURNS: the quantity of books avaialble after the next shipment arrives.
; EXAMPLES: (quantity-after-reorder BOOK2)-> 6
; STRATEGY: Structural Decomposition book1 : Book

(define (quantity-after-reorder book1)
  (+ (get-reorder-quantity (book-reordrst book1))
     (book-copies book1)))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; get-reorder-quantity : Reorder -> NonNegInt
;    GIVEN: a Book
;  RETURNS: the quantity of books avaialble after the next shipment arrives.
; EXAMPLES: (quantity-after-reorder BOOK2)-> 6
; STRATEGY: Structural Decomposition reorder1 : Reorders

(define (get-reorder-quantity reorder1)
  (if (reorders-present? reorder1)
      (reorders-newcopies reorder1)
      0))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; price-for-order : Inventory Order -> NonNegInt
;    GIVEN: An Inventory and an Order
;  RETURNS: the total price for the given order, in USD*100.  The price does not
;           depend on whether any particular line item is in stock.  Line items
;           for an ISBN that is not in the inventory count as 0.
; EXAMPLES: (price-for-order 3-BOOK-INVENTORY ORDER-AVAILABLE)-> 5800
;           (price-for-order 3-BOOK-INVENTORY empty) -> 0
; STRATEGY: Function Composition

(define (price-for-order invtry order)
  (if (or (empty? order) (empty? invtry))
      0
      (price-for-order-helper invtry order)))

;TEST CASES:
(begin-for-test
  (check-equal? (price-for-order 3-BOOK-INVENTORY ORDER-AVAILABLE)
                5800
                "Incorrect Answer.Value should be 5800")
  
  (check-equal? (price-for-order 3-BOOK-INVENTORY ORDER-UNAVAILABLE)
                1800
                "Incorrect Answer. order is available for 1800 .")
  
  (check-equal? (price-for-order 3-BOOK-INVENTORY empty)
                0
                "Incorrect Answer. Order is empty."))

;_______________________________________________________________________________
; price-for-order-helper : Inventory Order -> NonNegInt
;    GIVEN: An Inventory and an Order
;  RETURNS: the total price for the given order, in USD*100.  The price does not
;           depend on whether any particular line item is in stock.  Line items
;           for an ISBN that is not in the inventory count as 0.
; EXAMPLES: (price-for-order-helper 3-BOOK-INVENTORY ORDER-AVAILABLE)-> 5800
; STRATEGY: Function Composition

(define (price-for-order-helper invtry order)
  (if (empty? order)
      0
      (+ (calc-book-ordr-price (get-first-list order) invtry)
         (price-for-order-helper  invtry (get-rest-list order)))))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; calc-book-ordr-price : LineItem Inventory -> NonNegInt
;    GIVEN: A LineItem and an Inventory
;  RETURNS: the total price for the given Lineitem, in USD*100. The price does 
;           not depend on whether any particular line item is in stock.
;           Line items for an ISBN that is not in the inventory count as 0.
; EXAMPLES: (calc-book-ordr-price LINEITEM-AVAILABLE 3-BOOK-INVENTORY)-> 1800
;           (calc-book-ordr-price LINEITEM-UNAVAILABLE 3-BOOK-INVENTORY) -> 0
; STRATEGY: Function Composition

(define (calc-book-ordr-price lineitem1 invtry)
  (if (integer? (price-for-line-item invtry lineitem1))
      (price-for-line-item invtry lineitem1)
      0))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; inventory-after-order : Inventory Order -> Inventory.
;    GIVEN: an inventory and an order
;    WHERE: the order is fillable now
;  RETURNS: the inventory after the order has been filled.
; EXAMPLES: (inventory-after-order 3-BOOK-INVENTORY ORDER-AVAILABLE-AFT-SHPMNT)
;                                                 -> 3-BOOK-INVENTORY-AFT-ORDER
;           (inventory-after-order 3-BOOK-INVENTORY ORDER-UNAVAILABLE) 
;                                                -> 3-BOOK-INVENTORY
; STRATEGY: Function Composition

(define (inventory-after-order invtry order)
  (if (fillable-now? order invtry)
      (inventory-after-order-helper order invtry)
      invtry))

;TEST CASES:
(begin-for-test
  (check-equal? (inventory-after-order 3-BOOK-INVENTORY 
                                       ORDER-AVAILABLE-AFT-SHPMNT)
                3-BOOK-INVENTORY
                "Incorrect Answer. Should return the same Inventory")
  
  (check-equal? (inventory-after-order 3-BOOK-INVENTORY 
                                       ORDER-UNAVAILABLE-AFT-SHPMNT)
                3-BOOK-INVENTORY
                "Incorrect Answer. Should return the same Inventory.")
  
  (check-equal? (inventory-after-order 3-BOOK-INVENTORY ORDER-AVAILABLE)
                3-BOOK-INVENTORY-AFT-ORDER
                "Incorrect Answer. Invetory should be less by order quantity.")
  
  (check-equal? (inventory-after-order 3-BOOK-INVENTORY empty)
                3-BOOK-INVENTORY
                "Incorrect Answer. Order is empty."))

;_______________________________________________________________________________
; inventory-after-order-helper: Order Inventory  -> Inventory.
;    GIVEN: an  order and an Inventory
;  RETURNS: the inventory after the order has been filled.
; EXAMPLES: (inventory-after-order-helper ORDER-AVAILABLE 
;                                3-BOOK-INVENTORY) -> 3-BOOK-INVENTORY-AFT-ORDER
;           (inventory-after-order-helper ORDER-UNAVAILABLE-AFT-SHPMNT 
;                                3-BOOK-INVENTORY) -> 3-BOOK-INVENTORY
; STRATEGY: Function Composition

(define (inventory-after-order-helper order invtry)
  (if (empty? order)
      invtry
      (inventory-after-order-helper (get-rest-list order)        
                                    (rebuild-invtry-quantity 
                                     (get-first-list order) 
                                     invtry))))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling functions

;_______________________________________________________________________________
; rebuild-invtry-quantity: LineItem Inventory  -> Inventory.
;    GIVEN: an inventory and an order
;  RETURNS: the inventory after the LineItem has been filled.
; EXAMPLES: (rebuild-invtry-quantity LINEITEM-AVAILABLE 
;                                3-BOOK-INVENTORY) -> 3-BOOK-INVENTORY-AFT-LINE1
;           (inventory-after-order-helper LINEITEM-UNAVAILABLE 
;                                 3-BOOK-INVENTORY) -> 3-BOOK-INVENTORY
; STRATEGY: Structural Decomposition lineitem1 : LineItem

(define (rebuild-invtry-quantity lineitem1 invtry)
  (rebuild-invtry-quantity-helper (get-book invtry (line-item-isbn lineitem1))
                                  (line-item-isbn lineitem1)
                                  (line-item-quantity lineitem1)
                                  invtry))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; rebuild-invtry-quantity-helper Book PosInt Inventory -> Inventory.
;    GIVEN: A book, quantity and an Inventory
;  RETURNS: The inventory after the order has been filled.
; EXAMPLES: (rebuild-invtry-quantity-helper BOOK1 2 3-BOOK-INVENTORY)
;                                                  -> 3-BOOK-INVENTORY-AFT-LINE1
;           (rebuild-invtry-quantity-helper BOOK1 0 3-BOOK-INVENTORY)
;                                                  -> 3-BOOK-INVENTORY
; STRATEGY: Function Composition

(define (rebuild-invtry-quantity-helper book1 isbn quantity invtry)
  (list* (rebuild-invtry-book book1 isbn quantity invtry)
         (if (empty? (get-rest-list invtry))
             empty
             (rebuild-invtry-quantity-helper book1
                                             isbn
                                             quantity 
                                             (get-rest-list invtry)))))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; rebuild-invtry-book Book Integer PosInt Invetory -> Book.
;    GIVEN: A book, ISBN, quantity and an Inventory
;  RETURNS: the same book iff the book's isbn and the isbn passed doesn't match.
;           else create a new copy of the book with the copies less by quantity.
; EXAMPLES: (rebuild-invtry-book BOOK1 0474541344 1 3-BOOK-INVENTORY) 
;                                                        -> BOOK1-COPIES-5
; STRATEGY: Structural Decomposition book1 : Book

(define (rebuild-invtry-book book1 isbn quantity invtry)
  (if (= (book-isbn (get-first-list invtry)) isbn)
      (rebuild-book book1 quantity)
      (get-first-list invtry)))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; rebuild-book: Book PosInt -> Book.
;    GIVEN: an inventory and an order
;  RETURNS: the book after reducing the copies by the order quantity.
; EXAMPLES: (rebuild-book BOOK1 1) -> BOOK1-AFT-LINEITEM
; STRATEGY: Structural Decomposition book1 : Book

(define (rebuild-book book1 quantity)
  (make-book (book-isbn book1)     (book-title book1)
             (book-author book1)   (book-publshr book1)
             (book-uprice book1)   (book-ucost book1)
             (- (book-copies book1) quantity)
             (book-reordrst book1) (book-cuft book1)))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; increase-prices : Inventory String Real -> Inventory
;    GIVEN: an inventory, a publisher, and a percentage,
;  RETURNS: an inventory like the original, but all items by that publisher
;           have their unit prices increased by the given percentage. If the 
;           increased price is a non-integer, it may be either raised or 
;           truncated to next lowest integer price in USD*100.
; EXAMPLES: (increase-prices 3-BOOK-INVENTORY "INDIA" 10)
;                                              -> 3-BOOK-INVENTORY-AFT-RISE-10
; STRATEGY: Function Composition

(define (increase-prices invtry publshr percent)
  (if (or (empty? invtry) (empty? publshr) (= percent 0))
      invtry
      (increase-prices-helper invtry publshr percent)))

;TEST CASES:
(begin-for-test
  (check-equal? (increase-prices 3-BOOK-INVENTORY "INDIA" 0) 
                3-BOOK-INVENTORY
                "Incorrect Answer. Should return the same Inventory")
  
  (check-equal? (increase-prices 3-BOOK-INVENTORY "INDIA" 10)
                3-BOOK-INVENTORY-AFT-RISE-10
                "Incorrect Answer. Should return 3-BOOK-INVENTORY-AFT-RISE-10"))

;_______________________________________________________________________________
; increase-prices-helper : Inventory String Real -> Inventory
;    GIVEN: an inventory, a publisher, and a percentage,
;  RETURNS: an inventory like the original, but all items by that publisher
;           have their unit prices increased by the given percentage. If the 
;           increased price is a non-integer, it may be either raised or 
;           truncated to next lowest integer price in USD*100.
; EXAMPLES: (increase-prices 3-BOOK-INVENTORY "INDIA" 10)
;                                              -> 3-BOOK-INVENTORY-AFT-RISE-10
; STRATEGY: Function Composition

(define (increase-prices-helper invtry publshr percent)
  (list* (increase-book-price (get-first-list invtry) publshr percent)
         (if (empty? (get-rest-list invtry))
             empty
             (increase-prices-helper (get-rest-list invtry) publshr percent))))
;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; increase-book-price : Book String Real -> Book
;    GIVEN: a book, a publisher, and a percentage,
;  RETURNS: an book with its price increased by the given percentage and rounded
; EXAMPLES: (increase-book-price BOOK3 "INDIA" 10)  -> BOOK3-AFT-RISE-10
; STRATEGY: Structural Decomposition book1 : Book

(define (increase-book-price book1 publshr percent)
  (if (string-ci=? (book-publshr book1) publshr)
      (increase-book-price-helper book1 percent)
      book1))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; increase-book-price-helper : Book Real -> Book
;    GIVEN: a book and a percentage,
;  RETURNS: an book with its price increased by the given percentage and rounded
; EXAMPLES: (increase-book-price-helper BOOK3 10)  -> BOOK3-AFT-RISE-10
; STRATEGY: Structural Decomposition book1 : Book

(define (increase-book-price-helper book1 percent)
  (make-book (book-isbn book1)     (book-title book1)
             (book-author book1)   (book-publshr book1)
             (calc-book-new-price (book-uprice book1) percent)
             (book-ucost book1)    (book-copies book1)
             (book-reordrst book1) (book-cuft book1)))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; calc-book-new-price : NonNegInt Real -> NonNegInt
;    GIVEN: price of book and a percentage,
;  RETURNS: the price increased by the given percentage and rounded
; EXAMPLES: (calc-book-new-price 20 10)  -> 22
; STRATEGY: Function composition

(define (calc-book-new-price price percent)
  (round (* price (+ (/ percent 100) 1))))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; make-empty-reorder : Any -> ReorderStatus
;    GIVEN: Any. Ignores its argument
;  RETURNS: a ReorderStatus showing no pending re-order. 
; EXAMPLES: (make-empty-reorder 20)  -> (make-reorders false 0 0)
; STRATEGY: Function composition

(define (make-empty-reorder x)
  (make-reorders false 0 0))

;TEST CASES:
(begin-for-test
  (check-equal? (make-empty-reorder 20)
                (make-reorders false 0 0)
                "Incorrect Output. Should have produced a empty Reorder"))
;_______________________________________________________________________________
; make-reorder : PosInt PosInt -> ReorderStatus
;    GIVEN: a number of days and a number of copies
;  RETURNS: a ReorderStatus with the given data.
; EXAMPLES: (make-reorder 10 5)  -> (make-reorders true 10 5)
; STRATEGY: Function composition

(define (make-reorder x y)
  (make-reorders true x y))

;TEST CASES:
(begin-for-test
  (check-equal? (make-reorder 10 5)
                (make-reorders true 10 5)
                "Incorrect. Should produced a reorder with 10 days & 5 books"))
;_______________________________________________________________________________
; COMMON FUNCTIONS

; is-book-in-stock : LineItem Inventory -> Boolean
;    GIVEN: a LineItem and an Inventory
;  RETURNS: true iff the reqired book is available in inventory else false
; EXAMPLES: (is-book-in-stock LINEITEM-AVAILABLE 3-BOOK-INVENTORY) -> true
;           (is-book-in-stock LINEITEM-UNAVAILABLE 3-BOOK-INVENTORY) -> false
; STRATEGY:  Structural Decomposition lineitem1 : LineItem

(define (is-book-in-stock lineitem1 invtry)
  (if (empty? (get-book invtry (line-item-isbn lineitem1)))
      false
      (enough-copies-available? (line-item-quantity lineitem1)
                                (get-book invtry (line-item-isbn lineitem1)))))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; enough-copies-available? : PosInt Book -> Boolean
;    GIVEN: the quantity needed and a book
;  RETURNS: true iff the reqired quantity of book is available 
; EXAMPLES: (enough-copies-available? 10 BOOK1) -> false
;           (enough-copies-available? 1 BOOK1) -> true
; STRATEGY:  Structural Decomposition book1 : Book

(define (enough-copies-available? qneeded book1)
  (if (>= (book-copies book1) qneeded)
      true
      false))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; get-book : Inventory Integer -> Book
;    GIVEN: the Inventory & ISBN
;  RETURNS: the book whose isbn is given from the inventory
; EXAMPLES: (get-book 3-BOOK-INVENTORY 0474541344) -> BOOK1
; STRATEGY:  Structural Decomposition book1 : Book

(define (get-book invtry isbn)
  (if (= isbn 
         (book-isbn (book-entry invtry isbn)))
      (book-entry invtry isbn)
      empty))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; book-entry : Inventory Integer -> Book
;    GIVEN: the Inventory & ISBN
;  RETURNS: the book whose isbn is given from the inventory
; EXAMPLES: (book-entry 3-BOOK-INVENTORY 0474541344) -> BOOK1
; STRATEGY:  Function Composition

(define (book-entry invtry isbn)
  (list-ref invtry (find-idx-of-isbn invtry isbn)))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; find-idx-of-isbn: Inventory Integer -> NonNegInt
;    GIVEN: the Inventory & ISBN
;  RETURNS: the index of book whose isbn is given in the inventory
; EXAMPLES: (find-idx-of-isbn 3-BOOK-INVENTORY 0474541344) -> 0
; STRATEGY:  Function Composition

(define (find-idx-of-isbn invtry isbn)
  (- (length invtry)
     (length-of-list-from-req-book invtry isbn)))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; length-of-list-from-req-book: Inventory Integer -> PosInt
;    GIVEN: the Inventory & ISBN
;  RETURNS: the length of the list from the book whose ISBN is given in the
;            inventory
; EXAMPLES: (find-idx-of-isbn 3-BOOK-INVENTORY 0474541344) -> 2
; STRATEGY:  Function Composition

(define (length-of-list-from-req-book invtry isbn)
  (if (memq isbn (make-isbn-list invtry))
      (length (memv isbn (make-isbn-list invtry)))
      (length invtry)))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; make-isbn-list: Inventory -> LOISBN 
;    GIVEN: the Inventory & ISBN
;  RETURNS: list of ISBN created from the given inventory
; EXAMPLES: (make-isbn-list 3-BOOK-INVENTORY) 
;                      -> (cons 0474541344 (cons 0473123344 (cons 0874512344))))
; STRATEGY:  Structural Decomposition on Book

(define (make-isbn-list invtry)
  (if (empty? invtry)
      empty
      (cons (book-isbn (get-first-list invtry)) 
            (make-isbn-list (get-rest-list invtry)))))

;TEST CASES:
;  All possible cases have been tested by using testcases from calling function

;_______________________________________________________________________________
; reorder-present? Reoreder -> Boolean 
;    GIVEN: the reorder structure
;  RETURNS: true iff a reorder is present else false 

(define (reorder-present? reordr)
  (reorders-present? reordr))

;TEST CASES:
(begin-for-test 
  (check-equal? (reorder-present? (make-reorders false 0 0))
                false))

;_______________________________________________________________________________
; get-first-list List -> any/c
;    GIVEN: a list 
;  RETURNS: the first element of the list
; STRATEGY:  Structural Decomposition on list1 : List

(define (get-first-list list1)
  (first list1))
;_______________________________________________________________________________
; get-rest-list List -> any/c
;    GIVEN: a list 
;  RETURNS: the rest of the list after first element
; STRATEGY:  Structural Decomposition on list1 : List

(define (get-rest-list list1)
  (rest list1))
;_______________________________________________________________________________