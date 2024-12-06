(defconst A//temp
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

    (define strcpy-from-stack           ; strcpy a c-string from stack to [0x1 ...], use 0x0 as counter so max string-length is 255
      (<- 0 0)                          ; set counter to 0
      :loop
        (& je 0 :ret)                   ; return if end of string encountered
        (pop)
        (-> 0 1)                        ; get counter
        (dup)
        (& add 1)                       ; add 1 to the counter
        (& add ,A//start-size 0);
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
        (call write-byte-at 17)         ; ret

        (pop)                           ; pop :p from stack of 1st call
        (ret))

    :_start
      (call test-memory-rewriting)
      (call test-memory-rewriting)
      ;; (__debug_print_stack)
      ;; (push 0)
      ;; (push "abcd")
      ;; (call strcpy-from-stack)
      ;; (pop)
      ;; (call memcpy 4 1 10)
      ;; (& __debug_print_region 10)

      ;; (<- 0 0 ?a ?b ?c) ;; push 0 a b c to code memory @ 0x0 (+ A//dynmem-start)
      ;; (push "abc")
      ;; (<-S 4 3)         ;; push 3 values from stack to code memory @ 0x4 (+ A//dynmem-start)
      ;; (-> 0 7)          ;; push 7 values to the stack from code memory @ 0x0 (+ A//dynmem-start)
      ;; (call print)
      ))
