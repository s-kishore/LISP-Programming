;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname editor) (read-case-sensitive #t) (teachpacks ((lib "image.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ((lib "image.rkt" "teachpack" "2htdp")))))
(require "extras.rkt")
(require rackunit)
(require 2htdp/universe)

(provide 
      make-editor
      editor-pre
      editor-post
      edit)
;The text editor accepts two inputs pre and post. between the two is the cursor
;This editor should accept key events and append to the string left of the
;cursor when it a alphabet, when key event is backspace remove a letter left of
; the cursor position and on arrow keys left and right should move in the 
;respective direction

;_____________________________________________________________________________

; DATA DEFINITIONS:

(define-struct editor (pre post))

; An editor is a (make-editor pre post)
; INTERPRETATION:
;  pre - that includes the text value that preceeds the cursor
; post - that includes the text value that follows the cursor
; TEMPLATE:
;  (define editor-fn e)
;    (...
;      (editor-pre e)
;      (editor-post e))
;EXAMPLES:
;  (make-editor "kishore" "kumar")=>  (make-editor "kishore" "kumar")
;  (make-editor "First" "Second") => (make-editor "First" "Second")
;____________________________________________________________________________

; edit: string string -> string
; GIVEN: the editor and the key-event
; RETURNS: the editor after the completing editing operation
; EXAMPLES: 
;      (edit (make-editor "kishore" "kumar") "\b")
;                            => (make-editor "kishor" "kumar")
;      (edit (make-editor "kishore" "kumar") "left")
;                            => (make-editor "kishor" "ekumar")

; STRATEGY: Structural decomposition on key event ke

(define (edit edtr inpt)
  (cond [(= (string-length inpt) 1) (edit-data edtr inpt)]
        [(string=? inpt "left") (left-arrow edtr)]
        [(string=? inpt "right") (right-arrow edtr)]
        [else 
         edtr]
        ))
;_____________________________________________________________________________
; edit-data: editor string -> editor
; GIVEN: the editor and the key-event
; RETURNS: the editor after the editing
; EXAMPLES:
;     (edit-data (make-editor "kishore" "kumar") "b")
;                                     => (make-editor "kishoreb" "kumar")
;     (edit-data (make-editor "kishore" "kumar") "\u007F") 
;                                     => (make-editor "kishore" "kumar")
;
; STRATEGY: Structre De-composition on edtr:editor

(define (edit-data edtr inpt)
  (cond [(key=? "\b" inpt) (make-editor 
                            (remove-last-char edtr)
                            (editor-post edtr))]
        [(or (key=? "\t" inpt) (key=? "\u007F" inpt))
          edtr  
         ]
        
        [else
         (make-editor (string-append (editor-pre edtr) inpt)
                      (editor-post edtr))
                      ]))

;TEST CASES:
     

;_____________________________________________________________________________
; remove-last-char: editor -> editor
; GIVEN: the editor
; RETURNS: String after removing the last character of pre
; EXAMPLES:
;     (remove-last-char (make-editor "kishore" "kumar"))
;                                     => "kishor"
;     (remove-last-char (make-editor "kishoreKumar" "Selvan")) 
;                                     => (make-editor "kishoreKuma" "Selvan")
;
; STRATEGY: Structural de-composition on edtr:editor


(define (remove-last-char edtr)
  (substring (editor-pre edtr) 0 (- (string-length (editor-pre edtr)) 1)))
 

;__________________________________________________________
; left-arrow: Editor -> Editor
; GIVEN: the text editor
; RETURNS: the text editor value after the left-key operation 
; EXAMPLES:
;         (left-arrow (make-editor "kishore" "kumar") "left") 
;                                  =>(make-editor "kishor" "ekumar")
;         (left-arrow (make-editor "first" "second") "left") 
;                                  =>(make-editor "firs" "tsecond") 
;
; STRATEGY: Structural De-composition on edtr:editor
(define (left-arrow edtr)
  (make-editor (remove-last-char edtr) 
               (string-append (string-ith (editor-pre edtr) 
                                          (- (string-length (editor-pre edtr)) 1)) 
                              (editor-post edtr))))
 

;__________________________________________________________
; right-arrow: Editor -> Editor
; GIVEN: the text editor
; RETURNS: the text editor value after the right-key operation 
; EXAMPLES:
;         (right-arrow (make-editor "kishore" "kumar") "left") 
;                                  =>(make-editor "kishorek" "umar")
;         (right-arrow (make-editor "first" "second") "left") 
;                                  =>(make-editor "firsts" "econd") 
;
; STRATEGY: Structural De-composition on edtr:editor
 
 
(define (right-arrow edtr)
   (make-editor (string-append (editor-pre edtr) 
                               (string-ith (editor-post edtr) 0))
                (substring (editor-post edtr) 
                           1
                           (string-length (editor-post edtr)) )
                ))
 
;___________________________________________________________________
;TEST CASES:

(check-equal? (edit (make-editor "kishore" "kumar") "\b") 
              (make-editor "kishor" "kumar")
              "Incorrect output. should be (make-editor kishor kumar )")
(check-equal? (edit (make-editor "kishore" "kumar") "b")
              (make-editor "kishoreb" "kumar")
              "Incorrect output")
(check-equal? (edit (make-editor "kishore" "kumar") "left")
              (make-editor "kishor" "ekumar")
               "Incorrect output")
(check-equal? (edit (make-editor "kishore" "kumar") "right")
              (make-editor "kishorek" "umar")
              "Incorrect output")
(check-equal? (edit (make-editor "kishore" "kumar") "\u007F")
              (make-editor "kishore" "kumar")
              "Incorrect output")
(check-equal? (edit (make-editor "kishore" "kumar") "f1")
              (make-editor "kishore" "kumar")
              "Incorrect output")
