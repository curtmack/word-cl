(defpackage #:word-cl
  (:use #:cl)
  (:export
   #:valid-word-p
   #:load-word-list
   #:random-elt
   #:score-guess
   #:format-guess
   #:run-game
   #:main))

(in-package :word-cl)

;;; Copyright 2022 Curtis Mackie <curtis@mackie.ninja>
;;; SPDX-Short-Identifier: Apache-2.0

(defun valid-word-p (word
                     &key
                     (word-length 5))
  "Ensure that WORD is a valid word of length WORD-LENGTH.  If it is,
returns the STRING-UPCASE of that word; otherwise, returns nil.

A valid word contains only the letters A-Z (i.e. no hyphens,
ampersands, or other symbols).  This function relies on the letters A-Z
(capital) being contiguous."
  (let ((uc-word (string-upcase word)))
    (and (= (length uc-word) word-length)
         (every 
          (lambda (c)
            (char<= #\A c #\Z))
           uc-word)
         uc-word)))

(defun load-word-list (filename
                       &key (word-length 5))
  "Load all valid words (as by VALID-WORD-P with the given WORD-LENGTH)
from a dictionary text file containing a single word on each line.  Returns
those words as a vector."
  (check-type filename (or string pathname))
  (with-open-file (stream filename :direction :input)
    (map 'vector
         #'identity
         (loop for word = (read-line stream nil :eof)
               until (eql word :eof)
               when (valid-word-p word :word-length word-length)
                 collect it))))

(defparameter *seeded* nil)
(defun ensure-seeded ()
  (unless *seeded*
    (setf *random-state* (make-random-state t)
          *seeded* t)))

(defun random-elt (sequence)
  "Select a random element of SEQUENCE (as by ELT)."
  (check-type sequence sequence)
  (ensure-seeded)
  (elt sequence (random (length sequence))))

(defconstant +csi+ (code-char #x9b))

(defun sgr (destination &rest commands)
  "Print to DESTINATION the Select Graphics Rendition commands listed by COMMANDS.

DESTINATION is interpreted as in CL:FORMAT."
  (format destination "~a~{~a~^;~}m" +csi+ commands))

(defun green-color (destination)
  "Set up the terminal to display a green letter."
  (sgr destination 30 42))
(defun yellow-color (destination)
  "Set up the terminal to display a yellow letter."
  (sgr destination 30 43))
(defun faint-color (destination)
  "Set up the terminal to display a faint (incorrect) letter."
  (sgr destination 2))
(defun reset-color (destination)
  "Reset the terminal colors."
  (sgr destination 0))

(defun check-guess (guess
                    &key
                    (word-length 5)
                    legal-words)
  "Check if GUESS is a valid word of the given WORD-LENGTH contained in the
sequence of LEGAL-WORDS.  If it is, return the STRING-UPCASE of GUESS;
otherwise, return NIL."
  (let ((uc-guess (string-upcase guess)))
    (and (= (length uc-guess) word-length)
         (find uc-guess legal-words :test #'string=)
         uc-guess)))

(defun score-guess (guessed-word secret-word)
  "Given the GUESSED-WORD and SECRET-WORD, score the guess as in Wordle.

Wordle uses a variant of Mastermind's scoring system.  The return value is a
list of cons cells, where the CAR of each cons cell contains a letter of the
guessed word (in order) and the CDR contains the score of that letter: :GREEN
for a letter in the correct position, :YELLOW for a correct letter in the wrong
position, and :FAINT for an incorrect letter."
  (let ((score (map 'list
                    (lambda (c) (cons c nil))
                    guessed-word)))
    ;; We'll do this in two passes.  The first pass will take out
    ;; all the green matches and collect the remaining letters from
    ;; the secret into a list.
    (let ((remaining-chars
           (loop for index from 0 below (length guessed-word)
                 for guessed-char = (elt guessed-word index)
                 for secret-char = (elt secret-word index)
                 when (eql guessed-char secret-char)
                   do (setf (cdr (elt score index)) :green)
                 else
                   collect secret-char)))
      ;; In the second pass, we'll apply each remaining letter
      ;; to an unassigned letter from the guess to provide the yellow
      ;; scores for those letters.  This way the total number of green
      ;; and yellow scores for a single letter will never exceed the
      ;; number of that letter in the secret.
      (loop for char in remaining-chars
            as index = (position-if
                        (lambda (pair)
                          (and (eql (car pair) char)
                               (null (cdr pair))))
                        score)
            when index
              do (setf (cdr (elt score index)) :yellow))
      score)))

(defun format-letter (destination pair)
  "Print to DESTINATION a PAIR from the scored guess.

DESTINATION is interpreted as in CL:FORMAT.

PAIR will be a cons cell containing a letter and either :GREEN, :YELLOW,
or NIL (for faint).  The letter will be printed in an appropriate color and
surrounded by [square brackets], and a space will be added afterwords."
  (destructuring-bind (char . score) pair
    (case score
      ((:green)  (green-color  destination))
      ((:yellow) (yellow-color destination))
      ((nil)     (faint-color  destination)))
    (format destination "[~a]" char)
    (reset-color destination)
    (format destination " ")))

(defun format-guess (destination scored-guess)
  "Print to DESTINATION an entire SCORED-GUESS (as in SCORE-GUESS)."
  (loop for pair in scored-guess
        do (format-letter destination pair)
        finally (format destination "~%")))

(defun prompt (destination guess-num)
  "Print to DESTINATION a prompt showing the guess number GUESS-NUM,
and ensure output is flushed before returning."
  (format destination "GUESS ~a> " guess-num)
  (finish-output destination))

(defun take-guess (io num
                   &rest check-args
                   &key word-length legal-words)
  "Take a guess from the I/O stream IO, using the guess number NUM for the prompt.
Validate it against WORD-LENGTH and LEGAL-WORDS (as in CHECK-GUESS), and loop
until a valid guess is given.  Then, return the STRING-UPCASE of that guess."
  (declare (ignorable word-length legal-words))
  (prompt io num)
  (loop for guess = (apply
                     #'check-guess
                     (read-line io)
                     check-args)
        when guess
          return it
        do (format io "Not a five-letter word~%")
        do (prompt io num)))

(defun run-game (&key
                 (num-guesses 6)
                 (io *terminal-io*)
                 words)
  "Run the game of Word-CL on the I/O stream IO, allowing NUM-GUESSES
guesses and with the word list WORDS.
  
If the word is not guessed, it's displayed and the function returns NIL.
If it is guessed, a congratulatory message is displayed and the function
returns T.  If EOF is encountered (i.e. Ctrl-D is pressed), the game
ends prematurely (as if the word was not guessed)."
  (let ((word-length (length (elt words 0)))
        (secret-word (random-elt words)))
    (flet ((finish (&rest args)
             (declare (ignorable args))
             (format io "The word was ~a~%" secret-word)))
      (handler-bind ((end-of-file #'finish))
        (loop for num from 1 to num-guesses
              as guess = (take-guess io num
                                     :word-length word-length
                                     :words words)
              do (let ((scored-guess (score-guess guess secret-word)))
                   (format-guess io scored-guess))
              when (string= guess secret-word)
                do (format io "Congratulations!~%")
                and return t
              finally (finish))))))

(defun main (&rest args)
  (declare (ignorable args))
  (with-simple-restart (abort "Exit Word-CL")
    (setf *random-state* (make-random-state t))
    (run-game :num-guesses 6
              :words (load-word-list #p"popular.txt"))))
