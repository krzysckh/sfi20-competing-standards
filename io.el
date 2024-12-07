;;; io.el --- io/data helpers for flag.el -*- lexical-binding: t; comment-column: 40 -*-

(defconst A//io
  `((define print                       ; c-style print
      :loop
        (& je 0 :ret)
        (pop)
        (write)
        (goto :loop)
      :ret
        (pop)
        (pop)
        (ret))

    (define println
      (call print)
      (push 0)
      (push 10)
      (call print)
      (ret))

    (define strlen                      ; c-style strlen from stack. max-len = 255. uses 0x0
      (<- 0 0)                          ; set counter to 0
      :loop
        (& je 0 :ret)                   ; jump to :ret if found null terminator
        (pop)                           ; pop last v
        (pop)                           ; pop je 0
        (-> 0 1)                        ; push last value of counter to the stack
        (& add 1)                       ; increment counter
        (<-S 0 1)                       ; write to 0x0 1 value from stack
        (goto :loop)                    ; recur
      :ret
        (pop)                           ; pop 0 from je
        (pop)                           ; pop :ret from je
        (-> 0 1)
        (ret))                          ; return value from 0x0

    (define strmov-from-stack           ; move a c-string from stack to [0x1 ...], use 0x0 as counter so max string-length is 255
      (<- 0 0)                          ; set counter to 0
      :loop
        (& je 0 :ret)                   ; return if end of string encountered
        (pop)
        (-> 0 1)                        ; get counter
        (dup)
        (& add 1)                       ; add 1 to the counter
        (& add ,A//start-size 0)
        (swp)                           ; <---------------------------------+
        (wmem)                          ; save counter to 0x0               |
        (& add ,A//start-size)          ; add A//start-size to old counter -+
        (& add 1)                       ; add 0x1 as that's where the string will be stored
        (swp)
        (wmem)                          ; write char to memory
        (goto :loop)                    ; recur
      :ret
        (pop)                           ; pop 0 from je
        (pop)                           ; pop :ret from je
        (-> 0 1)                        ; return n of bytes written
        (dup)
        (& add 1)
        (& add ,A//start-size)
        (& wmem 0)                      ; finish the string in memory with 0
        (ret))

    (define write-byte-at               ;; ptr b -> ptr + 1
      (<-S 0 1)                         ; save b to 0x0
      (dup)                             ; dup ptr to save it
      (-> 0 1)                          ; restore b
      (wmem)                            ; write b to ptr
      (& add 1)
      (ret))                            ; return ptr + 1

    (define test-memory-rewriting
      :p
        (call print 0 "hello\n")
        (push :p)
        (call write-byte-at 0)          ; \
        (call write-byte-at 10)         ; |
        (call write-byte-at 0)          ; |
        (call write-byte-at 0)          ; |
        (call write-byte-at 0)          ; / push \n

        (call write-byte-at 0)          ; \
        (call write-byte-at ?i)         ; |
        (call write-byte-at 0)          ; |
        (call write-byte-at 0)          ; |
        (call write-byte-at 0)          ; / push ?i

        (call write-byte-at 0)          ; \
        (call write-byte-at ?H)         ; |
        (call write-byte-at 0)          ; |
        (call write-byte-at 0)          ; |
        (call write-byte-at 0)          ; / push ?H

        (call write-byte-at 11)         ; write
        (call write-byte-at 11)         ; write
        (call write-byte-at 11)         ; write
        (call write-byte-at 18)         ; ret

        (pop)                           ; pop :p from stack of 1st call
        (ret))

    (define reverse-string
      (call strmov-from-stack)          ; move string from stack to 0x1
      (<-S 0 1)                         ; save len to 0x0
      (push 0)                          ; end the string with 0
      (push 0)                          ; init ctr to 0
      :loop
        (-> 0 1)                        ; read len
        (& je :ret)                     ; return when ctr == len
        (pop)                           ; throw len out
        (dup)
        (& add 1)                       ; add start of string [0x1] to ctr
        (& add ,A//start-size)          ; add start of memory to ctr
        (pmem)                          ; push to stack from memory
        (swp)
        (& add 1)                       ; increment ctr
        (goto :loop)
      :ret
        (pop)
        (pop)
        (ret))

    (define read-line
      (push 0)
      :loop
        (read)
        (& je 10 :ret)
        (pop)
        (goto :loop)
      :ret
        (pop)
        (pop)
        (call reverse-string)
        (ret))

    (define drain!                      ; drain stack upto 0
      :loop
        (& je 0 :ret)
        (pop)
        (pop)
        (goto :loop)
      :ret
        (pop)
        (pop)
        (ret))

    (define strcmp                      ; 0 string 0 string -> 1=true | 0=false
      (call strmov-from-stack)
      (pop)                             ; dispose the length returned by strmov
      (<- 0 ,(+ 1 A//start-size))       ; initialize counter to 0x1 + A//start-szie
      :loop
        (-> 0 1)                        ; get couter
        (pmem)
        (& je :maybe-loop)
        (goto :diff)
      :maybe-loop
        (& je 0 :same)
        (pop)
        (pop)
        (pop)
        (-> 0 1)
        (& add 1)
        (<-S 0 1)                       ; increment counter
        (goto :loop)
      :same
        (pop)
        (pop)
        (pop)
        (& ret 1)
      :diff
        (call drain!)
        (& ret 0))

    ;; https://www.stix.id.au/wiki/Fast_8-bit_pseudorandom_number_generator
    (define rand
      (-> #x103 1)                      ; x++
      (& add 1)
      (<-S #x103 1)
      (-> #x100 1)                      ; get a
      (-> #x102 1)                      ; get c
      (xor)                             ; (a ^ c)  <-+
      (-> #x103 1)                      ; get x      |
      (xor)                             ; ... ^ x  <-+
      (<-S #x100 1)                     ; a = ... ---+
      (-> #x100 2)                      ; get a, b
      (add)
      (<-S #x101 1)                     ; b = b + a
      (push 1)
      (-> #x101 1)                      ; get b
      (>>)                              ; b >> 1   <-+
      (-> #x102 1)                      ; get c      |
      (add)                             ; c + ...  <-+
      (-> #x100 1)                      ; get a      |
      (xor)                             ; ... ^ a  <-+
      (<-S #x102 1)                     ; c = ... ---+

      (-> #x102 1)                      ; return c
      (ret)
      )

    (define init-rand                   ;; c b a
      (<-S #x100 3)                     ; rand data kept at [a=0x100, b=0x101, c=0x102, x=0x103]
      (call rand)
      (pop)
      (ret))

    (define not
      (& je 0 :z)
      (pop)
      (pop)
      (& ret 0)
      :z
        (pop)
        (pop)
        (& ret 1))

    (define lt                          ;; b a -> a < b ? 1 : 0
      (sub)
      (& jlz :lower)
      (pop)
      (& ret 0)
      :lower
        (pop)
        (& ret 1))

    (define <
      (call lt)
      (ret))

    (define gt
      (call lt)
      (call not)
      (ret))

    (define >
      (call gt)
      (ret))

    (define modulo                      ;; b a -> a % b (stores data in [0x0, 0x1] so a and b < 256)
      (<-S 0 2)                         ; save a to 0x0 and b to 0x1
      :loop
        (-> 0 2)
        (swp)
        (call <)
        (& jne 0 :ok)                   ; if a > b
        (pop)                           ;
        (pop)                           ; pop jne vals
        (-> 0 2)                        ; get [a b]
        (swp)                           ; [a b] -> [b a]
        (sub)
        (<-S 0 1)                       ; save a-b to 0x0 if a>b
        (goto :loop)
      :ok                               ; else
        (pop)
        (pop)
        (-> 0 1)                        ; return a
        (ret))

     (define rand-upto                  ; (call rand-upto maxv) => rand() % maxv
       (call rand)
       (call modulo)
       (ret))

    ))
