#lang eopl

(define identifier? symbol?)          ; not defined in the book

(define-datatype lc-exp lc-exp?       ; p.46
  (var-exp
   (var identifier?))
  (lambda-exp
   (bound-var identifier?)
   (body lc-exp?))
  (app-exp
   (rator lc-exp?)
   (rand lc-exp?)))

;; not defined in the book; any error reporter works
(define report-invalid-concrete-syntax
  (lambda (datum)
    (eopl:error 'parse-expression "invalid concrete syntax ~s" datum)))

(define parse-expression              ; p.53
  (lambda (datum)
    (cond
      ((symbol? datum) (var-exp datum))
      ((pair? datum)
       (if (eqv? (car datum) 'lambda)
           (lambda-exp
            (car (cadr datum))
            (parse-expression (caddr datum)))
           (app-exp
            (parse-expression (car datum))
            (parse-expression (cadr datum)))))
      (else (report-invalid-concrete-syntax datum)))))

(parse-expression '(lambda (x) (f (f x))))
