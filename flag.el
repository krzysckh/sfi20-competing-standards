(defconst A//magic-number 2138)
(defconst A//flag
  `((define print ;; c-style print
      :loop
        (& je 0 :ret)
        (pop)
        (write)
        (goto :loop)
      :ret
        (pop)
        (pop)
        (ret))

    (define unstack
      :loop
        (pop)
        (& jnempt :loop)
        (ret))

    (define fail
      (call print 0 "No.\n")
      (& div 0 0))

    (define print-image
      :print
        (& xor ,A//magic-number)
        (write)
        (& jempt :end)
        (goto :print)
      :end
        (ret))

    (define read-answer ;; reads until newline, but disregards anything after 1st char
      (read)
      :read
        (read)
        (& je 10 :ret)
        (pop)
        (pop)
        (goto :read)
      :ret
        (pop)
        (pop)
        (ret))

    (define ask ;; (char-solution 0 question)
      (call print)
      :_ask
        (call print 0 "> ")
        (call read-answer)

        (& je :ok)
        (call fail)
      :ok
        (ret))

    :_start
      (call ask ?b 0 "in what year was the 1st SFI held?\na) 2004\nb) 2005\nc) 2006\n")
      (call ask ?c 0 "jaka firma nie chce zalatwiac praktyk gitom?\na) tauron\nb) polregio\nc) academica\n")
      (call ask ?a 0 "how much is 2+2*2?\na) 6\nb) 7\nc) 8\n")

      (call unstack)

      (call print-image ,(--map (logxor it A//magic-number) (string-to-list (string-as-unibyte (f-read-bytes "res/beef.jpg")))))))
      ;; (call print-image ,(--map (logxor it A/magic-number) (string-to-list "hello"))))))
