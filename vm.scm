;; -*- mode: scheme; compile-command: "printf '2005\\nyes\\n6\\n21124\\nno\\n' | ol -r vm.scm flag.bin | tail -c +729 > /tmp/a.jpg && sxiv /tmp/a.jpg" -*-

(import
 (owl toplevel)
 (prefix (owl sys) sys/))

(define (i32->number lst)
  (fold (λ (a b) (bior (<< a 8) b)) 0 (reverse lst)))

(define (pops l)
  (if (null? l)
      (error "attempting to pop out of an empty stack " #f)
      (values (cdr l) (car l))))

(define (push ip stack call-stack ctf-stack code cont)
  (cont (+ ip 5)
        (cons (i32->number `(,(vref code (+ ip 1))
                             ,(vref code (+ ip 2))
                             ,(vref code (+ ip 3))
                             ,(vref code (+ ip 4))))
              stack)
        call-stack
        ctf-stack
        code))

(define (pop ip stack call-stack ctf-stack code cont)
  (lets ((stack _ (pops stack)))
    (cont (+ ip 1) stack call-stack ctf-stack code)))

(define (swp ip stack call-stack ctf-stack code cont)
  (lets ((stack a (pops stack))
         (stack b (pops stack)))
    (cont (+ ip 1) (cons b (cons a stack)) call-stack ctf-stack code)))

(define (make-mathop op)
  (λ (ip stack call-stack ctf-stack code cont)
    (lets ((stack a (pops stack))
           (stack b (pops stack)))
      (cont (+ ip 1) (cons (op a b) stack) call-stack ctf-stack code))))

(define sub (make-mathop -))
(define add (make-mathop +))
(define mul (make-mathop *))
(define div (make-mathop /))
(define xor (make-mathop bxor))
(define <<  (make-mathop <<))
(define >>  (make-mathop >>))

(define (write ip stack call-stack ctf-stack code cont)
  (lets ((stack a (pops stack)))
    (write-bytes stdout (list a))
    (cont (+ ip 1) stack call-stack ctf-stack code)))

(define (read ip stack call-stack ctf-stack code cont)
  (cont (+ ip 1) (cons (ref (sys/read stdin 1) 0) stack) call-stack ctf-stack code))

(define (je ip stack call-stack ctf-stack code cont)
  (lets ((stack a (pops stack))
         (stack b (pops stack))
         (stack c (pops stack))
         (stack (cons b (cons c stack))))
    (if (= b c)
        (cont a stack call-stack ctf-stack code)
        (cont (+ ip 1) stack call-stack ctf-stack code))))

(define (jne ip stack call-stack ctf-stack code cont)
  (lets ((stack a (pops stack))
         (stack b (pops stack))
         (stack c (pops stack))
         (stack (cons b (cons c stack))))
    (if (not (= b c))
        (cont a stack call-stack ctf-stack code)
        (cont (+ ip 1) stack call-stack ctf-stack code))))

(define (jlz ip stack call-stack ctf-stack code cont)
  (lets ((stack a (pops stack))
         (stack b (pops stack))
         (stack (cons b stack)))
    (if (< b 0)
        (cont a stack call-stack ctf-stack code)
        (cont (+ ip 1) stack call-stack ctf-stack code))))

(define (call ip stack call-stack ctf-stack code cont)
  (lets ((stack a (pops stack)))
    (cont a stack (cons (+ ip 1) call-stack) ctf-stack code)))

(define (goto ip stack call-stack ctf-stack code cont)
  (lets ((stack a (pops stack)))
    (cont a stack call-stack ctf-stack code)))

(define (ret ip stack call-stack ctf-stack code cont)
  (lets ((call-stack a (pops call-stack)))
    (cont a stack call-stack ctf-stack code)))

(define (dup ip stack call-stack ctf-stack code cont)
  (lets ((_ a (pops stack)))
    (cont (+ ip 1) (cons a stack) call-stack ctf-stack code)))

(define (jempt ip stack call-stack ctf-stack code cont)
  (lets ((stack a (pops stack)))
    (if (null? stack)
        (cont a stack call-stack ctf-stack code)
        (cont (+ ip 1) stack call-stack ctf-stack code))))

(define (jnempt ip stack call-stack ctf-stack code cont)
  (lets ((stack a (pops stack)))
    (if (not (null? stack))
        (cont a stack call-stack ctf-stack code)
        (cont (+ ip 1) stack call-stack ctf-stack code))))

(define (wmem ip stack call-stack ctf-stack code cont)
  (lets ((stack a (pops stack))
         (stack b (pops stack)))
    (cont (+ ip 1) stack call-stack ctf-stack (vector-set code b (modulo a 256)))))

(define (pmem ip stack call-stack ctf-stack code cont)
  (lets ((stack a (pops stack)))
    (cont (+ ip 1) (cons (vref code a) stack) call-stack ctf-stack code)))

(define (ctf ip stack call-stack ctf-stack code cont)
  (lets ((stack a (pops stack)))
    (cont (+ ip 1) stack call-stack (append (list a) ctf-stack) code)))

(define (debug-print-stack ip stack call-stack ctf-stack code cont)
  (print stack)
  (cont (+ ip 1) stack call-stack ctf-stack code))

(define (debug-print-region ip stack call-stack ctf-stack code cont)
  (print "region:")
  (lets ((stack a (pops stack)))
    (for-each (λ (n) (print (vref code n))) (iota a 1 (+ a 10)))
    (cont (+ ip 1) stack call-stack ctf-stack code)))

(define disp-table
  `((0  . ,push)
    (1  . ,pop)
    (3  . ,swp)
    (4  . ,sub)
    (5  . ,add)
    (6  . ,mul)
    (7  . ,div)
    (8  . ,xor)
    (9  . ,<<)
    (10 . ,>>)
    (11 . ,write)
    (12 . ,read)
    (13 . ,je)
    (14 . ,jne)
    (15 . ,jlz)
    (16 . ,call)
    (17 . ,goto)
    (18 . ,ret)
    (19 . ,dup)
    (20 . ,jempt)
    (21 . ,jnempt)
    (22 . ,wmem)
    (23 . ,pmem)
    (24 . ,ctf)

    (100 . ,debug-print-stack)
    (101 . ,debug-print-region)
    ))

(define (disp ip stack call-stack ctf-stack code)
  (if (>= ip (vector-length code))
      (begin
        (print-to stderr "ctf-stack: " (list->string (reverse ctf-stack)))
        0)
      (let ((f (cdr (assoc (vref code ip) disp-table))))
        (f ip stack call-stack ctf-stack code disp))))

(λ (args)
  (let ((code (list->vector (file->list (cadr args)))))
    (disp 0 #n #n #n code)))
