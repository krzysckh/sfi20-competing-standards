;;; flag.el --- main flag program -*- lexical-binding: t; comment-column: 40 -*-

(add-to-list 'load-path ".")
(load "io.el")

(defun A//xor (str num)
  (--map (logxor it num) (string-to-list str)))

(defconst A//euler-question
  "If the numbers 1 to 5 are written out in words: one, two, three, four, five,
then there are 3 + 3 + 5 + 4 + 4 = 19 letters used in total.

if all numbers from 1 to 1000 (one thousand) were written out it words, how many letters would be used?

NOTE: Do not count spaces or hyphens. For example, 342 (three hundred and forty-two)
contains 23 letters and 115 (one hundred and fifteen) contains 20 letters.
The use of \"and\" when writing out numbers is in compliance with British usage.

")

(defconst A//euler-answer "21124")

(defconst A//magic-number 2138)
(defconst A//flag
  (append
   A//io
   `((define-noreturn fail
       (call print 0 "No.\n")
       (& div 0 0))

     (define selfcheck-sub-test
       (call print 0 ".")
       (ret))

     (define selfcheck-fail
       (call println 0 "Some self-checks failed. Please check your vm implementation")
       (call fail)
       (ret))

     ;; TODO: more self checks
     (define do-self-check
       (call println 0 "Will do a self check, please hold")
       (call selfcheck-sub-test)

       (call println 0 "\nAll tests OK.")
       (ret)

       :fail
         (call selfcheck-fail)
       )

     (define print-image
       :print
         (& xor ,A//magic-number)
         (write)
         (& jempt :end)
         (goto :print)
       :end
         (ret))

     (define ask                        ;; (0 solution 0 question)
       (call println)
       :_ask
         (call print 0 "> ")
         (call read-line)
         (call strcmp)

         (& jne 0 :ok)
         (call fail)
       :ok
         (pop)
         (pop)
         (ret))

     ;; https://projecteuler.net/problem=17
     (define ask-euler
       (call print 0 ,A//euler-question)
       (call print 0 "> ")
       (call read-line)
       (push 0)
       (push ,A//euler-answer)          ; yeah it can be read from the stack lol
       (call strcmp)
       (& jne 0 :ok)
       (call fail)
       :ok
         (pop)
         (pop)
         (ret)
       )

     (define troll                      ;; 0 string
       :loop
         (& je 0 :ret)
         (pop)
         (& xor 42)
         (ctf)
         (goto :loop)
       :ret
         (pop)
         (pop)
         (ret))

     :_start
       (call init-rand 21 37 42)        ; don't delete this one

       ;; (call rand-upto 10)
       (call do-self-check)

       (call ask 0 "2005" 0 "in what year was the 1st SFI held?")
       (call ask 0 "yes" 0 "was Larry Wall ever a speaker at SFI? [yes/no]")
       (call ask 0 "6" 0 "how much is 2+2*2?")

       (call troll 0 ,(A//xor "umm, hii! thanks for tuning in to the CTF stack, i'm really glad you decided to see what's here, but unfortunately - the flag isn't there. instead i have a small hint: use pipes :33" 42))

       (call ask-euler)

       (call ask 0 "no" 0 "were you sniffing through the stack to find the answers faster? [yes/no]")

       (call println 0 "congrats!")

       (call print-image ,(A//xor (string-as-unibyte (f-read-bytes "res/beef.jpg")) A//magic-number)))))
       ;; (call print-image ,(--map (logxor it A//magic-number) (string-to-list "TODO: some more stuff and sfi20{abobobababba}\n"))))))
