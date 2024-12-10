;;; asm.el --- assembler for the ad hoc ctf vm -*- lexical-binding: t; comment-column: 40 -*-

;; Author: Krzysztof Michałczyk <kpm@krzysckh.org>
;; Version: 0.0
;; Keywords: asm, ctf
;; Package-Requires: ((emacs "28.2") (s "1.8.0") (f "0.16.0"))

;; Commentary:
;; warning: 0x0 for memory stuff is actually 0x0 + A//start-size
;;          this is caused by the 1st call to jmp to :_start
;;
;; code memory usage
;; 5 bytes for 1st jump to :_start
;; A//dyn-memory bytes of zeroes
;; N bytes of your code


(require 'dash)
(require 'f)

(defconst A/dyn-memory 2048)
(defconst A//start-size 6)
(defconst A//dynmem-start A//start-size)

(defconst A/basic-op-table
  ;; sym  id
  '((push 0)
    (pop 1)
    (swp 3)
    (sub 4)
    (add 5)
    (mul 6)
    (div 7)
    (xor 8)
    (<< 9)
    (>> 10)
    (write 11)
    (read 12)
    (je 13)
    (jne 14)
    (jlz 15)
    (call 16)
    (goto 17)
    (ret 18)
    (dup 19)
    (jempt 20)
    (jnempt 21)
    (wmem 22)
    (pmem 23)
    (ctf 24)

    (__debug_print_stack 100 0)
    (__debug_print_region 101 1)
    ))

(defun A/definitionp (instr)
  "return t if `instr' is an assembler definition, nil otherwise"
  (and
   (listp instr)
   (> (length instr) 2)
   (eq (car instr) 'define)
   (symbolp (cadr instr))))

(defun A/funcallp (instr)
  "return t if `instr' is an assembler simple funcall, nil otherwise"
  (and
   (listp instr)
   (> (length instr) 2)
   (eq (car instr) '&)))

(defun A/to-int32 (num)
  "convert a lisp number `num' to a list of bytes"
  (when (>= num (lsh 1 31))
    (error "number %s is too big to encode" num))
  (when (< num (- 0 (lsh 1 31)))
    (error "number %s is too small to encode" num))
  (reverse
   (vector
    (logand (ash num -24) #xff)
    (logand (ash num -16) #xff)
    (logand (ash num -8) #xff)
    (logand (ash num 0) #xff))))

(defun A//push (val env &optional noerr)
  "compile a push expression for `val' in `env'"
  (cond
   ((numberp val) (vconcat (vector (A//OP 'push)) (A/to-int32 val)))
   ((characterp val) (vconcat (vector (A//OP 'push)) (A/to-int32 val)))
   ((listp val) (-reduce #'vconcat (--map (A//push it env) (reverse val))))
   ((stringp val) (-reduce #'vconcat (--map (A//push it env) (reverse (string-to-list val)))))
   ((keywordp val) (let ((place (cdr (assoc val env))))
                     (if place
                         (vconcat (vector (A//OP 'push)) (A/to-int32 place))
                       (if noerr
                         (vconcat (vector (A//OP 'push)) (A/to-int32 0))
                         (error "undeclared identifier: %s" val)))))
   (t
    (error "invalid value to push: %s" val))))

(defun A//call (exp env)
  "compile code for a call, (call func-name arg1 arg2 arg3). args are pushed and and function gets called"
  (let ((place (cdr (assoc (cadr exp) env)))
        (args (cddr exp)))
    (if place
        (vconcat
         (-reduce #'vconcat (-map #'(lambda (x) (A//push x env)) args))
         (A//push place env)
         (vector (A//OP 'call)))
      (error "undeclared identifier: %s" (cadr exp)))))

(defun A//mem-write-p (exp)
  (and
   (listp exp)
   (>= (length exp) 2)
   (eq (car exp) '<-)))

(defun A//mem-write-stack-p (exp)
  (and
   (listp exp)
   (>= (length exp) 2)
   (eq (car exp) '<-S)))

(defun A//mem-read-p (exp)
  (and
   (listp exp)
   (>= (length exp) 2)
   (eq (car exp) '->)))

(defun A//OP (sym)
  (cadr (assoc sym A/basic-op-table)))

(defun A//wmem (exp env &optional noerr)
  (let ((vs (cddr exp)))
    (apply
     #'vconcat
     (cl-loop for i from 0 to (- (length vs) 1)
              for val = (vconcat (A//push (+ A//dynmem-start (cadr exp) i) env noerr) (A//push (nth i vs) env noerr) (vector (A//OP 'wmem)))
              collect val))))

(defun A//wmem-from-stack (exp env &optional noerr)
  (apply
   #'vconcat
   (cl-loop for i from 0 to (- (caddr exp) 1)
            for val = (vconcat (A//push (+ A//dynmem-start (cadr exp) i) env noerr) (vector
                                                                                     (A//OP 'swp)
                                                                                     (A//OP 'wmem)))
            collect val)))

(defun A//rmem (exp env &optional noerr)
  (apply
   #'vconcat
   (cl-loop for i from 0 to (- (caddr exp) 1)
            for val = (vconcat (A//push (+ A//dynmem-start (cadr exp) i) env noerr) (vector (A//OP 'pmem)))
            collect val)))

(defun A//compile-basic (exp env)
  "compile a basic expression `exp' in environment `env'"
  (let ((op (car exp)))
    (cond
     ((A/funcallp exp) (A//funcall-basic (cdr exp) env))
     ((A//mem-write-p exp) (A//wmem exp env))
     ((A//mem-write-stack-p exp) (A//wmem-from-stack exp env))
     ((A//mem-read-p exp) (A//rmem exp env))
     ((eq op 'push) (A//push (cadr exp) env))
     ((eq op 'call) (A//call exp env))
     ((eq op 'goto)
      (let ((place (cdr (assoc (cadr exp) env))))
        (if place
            (vconcat (A//push place env) (vector (A//OP 'goto)))
          (error "undeclared identifier: %s" (cadr exp)))))
     (t
      (if (> (length exp) 1)
          (error "too much args for %s. if you want to push values before calling an op, use the & macro." exp)
        (let ((op (cadr (assoc (car exp) A/basic-op-table))))
          (if op
              (vector op)
            (error "couldn't find op %s in A/basic-op-table" exp))))))))

(defun A//funcall-basic (exp env)
  (vconcat
   (-reduce #'vconcat (-map #'(lambda (x) (A//push x env)) (cdr exp)))
   (A//compile-basic (list (car exp)) env)))

;; TODO: hell
(defun A//op-byte-len (op)
  (cond
   ((eq (car op) 'push) (length (A//push (cadr op) nil t)))
   ((eq (car op) 'call) (+ 6 (-sum (--map (length (A//push it nil t)) (cddr op)))))
   ((eq (car op) 'goto) 6)
   ((A/funcallp op) (+ 1 (-reduce #'+ (--map (length (A//push it nil t)) (cddr op)))))
   ((A//mem-write-p op) (length (A//wmem op nil t)))
   ((A//mem-read-p op) (length (A//rmem op nil t)))
   ((A//mem-write-stack-p op) (length (A//wmem-from-stack op nil t)))
   (t
    1)))

(defun A//compile-definition (code env memptr acc)
  (let* ((def (car code))
         (name (cadr def))
         (func (cddr def))
         (local-env nil)
         (func-location memptr)
         (bin nil))

    ;; save local-env
    (dolist (op func)
      (if (keywordp op)
          (push (cons op memptr) local-env)
        (setq memptr (+ memptr (A//op-byte-len op)))))

    ;; compile code
    (dolist (op func)
      (when (listp op)
        (setq bin (vconcat bin (A//compile-basic op (append local-env env))))))

    (A//compile
     (cdr code)
     (append `((,name . ,func-location)) env)
     memptr
     (vconcat acc bin))))

(defun A//call-start-prepend-memory (bin env)
  (vconcat
   (A//push :_start env)
   (vector (A//OP 'goto))
   (make-vector A/dyn-memory 0)
   bin))

(defun A//compile (code env memptr &optional acc)
  (cond
   ((null code) (A//call-start-prepend-memory acc env))
   ((keywordp (car code)) (A//compile (cdr code) (append `((,(car code) . ,memptr)) env) memptr acc))
   ((A/definitionp (car code)) (A//compile-definition code env memptr acc))
   ((listp (car code)) (A//compile (cdr code) env (+ memptr 1) (vconcat acc (A//compile-basic (car code) env))))
   (t
    (error "unknown op: %s" (car code)))))

(defun A/compile (code &optional outfile)
  "compile `code', if defined, write output data to `outfile'"
  (let ((program (A//compile code nil (+ A//start-size A/dyn-memory))))
    (if outfile
        (f-write-bytes (apply #'unibyte-string (append program nil)) outfile)
      program)))

(provide 'asm)
;;; asm.el ends here
