;;; flag.el --- main flag program -*- lexical-binding: t; comment-column: 40 -*-

(add-to-list 'load-path ".")
(load "io.el")

(defconst A//magic-number 2138)
(defconst A//flag
  (append
   A//io
   `((define fail
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

     :_start
       (call init-rand 21 37 42)        ; don't delete this one

       ;; (call rand-upto 10)
       (call do-self-check)

       (call ask 0 "2005" 0 "in what year was the 1st SFI held?")
       (call ask 0 "c" 0 "jaka firma nie chce zalatwiac praktyk gitom?\na) tauron\nb) polregio\nc) academica")
       (call ask 0 "6" 0 "how much is 2+2*2?")

       (call print-image ,(--map (logxor it A//magic-number) (string-to-list (string-as-unibyte (f-read-bytes "res/beef.jpg"))))))))
       ;; (call print-image ,(--map (logxor it A//magic-number) (string-to-list "TODO: some more stuff and sfi20{abobobababba}\n"))))))
