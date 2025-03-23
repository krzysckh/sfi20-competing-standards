;;; examples.el --- some examples -*- lexical-binding: t; comment-column: 40 -*-

(add-to-list 'load-path ".")
(load "io.el")

(defvar A//fizzbuzz
  (append
   A//io
   `(;; pretty bad print-number, as modulo uses memory directly
     ;; so n can be 0-255 lmao
     (define print-number               ; n -> n (uses 0x2 as ptr 0x3... as buf)
       (dup)                            ; n -> n' n
       (<- 2 3)                         ; set ptr to 3
       :loop
         (& je 0 :finish)               ; while (n != 0)
         (pop)                          ; cleanup je call
         (dup)                          ; n   -> n n
         (& swp 10)                     ; n 10 -> 10 n
         (call modulo)                  ; n n -> n last-digit
         (-> 2 1)                       ; n last-digit ctr
         (& add ,A//start-size)
         (swp)
         (wmem)                         ; n ctr last-digit -> n
         (-> 2 1)                       ; n ctr
         (& add 1)                      ; \
         (<-S 2 1)                      ; / write(0x2, ++ctr)
         (push 10)                      ; n 10   \
         (swp)                          ; 10 n   /
         (div)                          ; well this is an awkward way of doing division
         (goto :loop)
       :finish
         (pop)
         (pop)
         (push 1)
         (-> 2 1)
         (sub)
       :get                             ; get the reversed list string back from mem
         (& je 2 :ret)
         (pop)
         (dup)                          ; ptr -> ptr ptr
         (& add ,A//start-size)
         (pmem)                         ; -> ptr n
         (& add ?0)                     ; -> ptr char
         (write)                        ; -> ptr
         (push 1)
         (swp)
         (sub)
         (goto :get)
       :ret
         (pop)
         (pop)
         (& write ?\n)                  ; finish with a newline
         (ret))

     (define mod                        ; modulo w/ swapped args
       (swp)
       (call modulo)
       (ret))

     (define main
       (push 100)                       ; max
       (push 1)                         ; current

       :loop
         (& je :end)

         (dup) (call mod 15)
         (& je 0 :fizzbuzz) (pop) (pop)
         (dup) (call mod 3)
         (& je 0 :fizz) (pop) (pop)
         (dup) (call mod 5)
         (& je 0 :buzz) (pop) (pop)

         (call print-number)
         (& add 1)
         (goto :loop)

       :fizzbuzz
         (pop) (pop)
         (call println 0 "FizzBuzz")
         (& add 1)
         (goto :loop)
       :fizz
         (pop) (pop)
         (call println 0 "Fizz")
         (& add 1)
         (goto :loop)
       :buzz
         (pop) (pop)
         (call println 0 "Buzz")
         (& add 1)
         (goto :loop)

       :end
       (ret))

     :_start
       (call main))))
