#lang eopl
(require racket/include)
(include "safe.rktl")
(include "errs.rktl")
(define empty-env (lambda () '()))
(define extend-env
  (lambda (var val env) (cons (cons var val) env)))
(define apply-env
  (lambda (env search-var)
    (cond ((null? env) (report-no-binding-found search-var))
          ((eqv? (caar env) search-var) (cdar env))
          (else (apply-env (cdr env) search-var)))))
(include "tests.rktl")
