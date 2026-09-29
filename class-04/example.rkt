#lang eopl

;; 1. 定義語法樹數據類型
(define-datatype lc-exp lc-exp?
  (var-exp
   (var symbol?))
  (lambda-exp
   (bound-var symbol?)
   (body lc-exp?))
  (app-exp
   (rator lc-exp?)
   (rand lc-exp?)))

;; 2. 建立一個具體的 AST 實例
(define test-ast
  (app-exp
   (lambda-exp 'x (var-exp 'x))
   (var-exp 'y)))

;; 3. 求值此實例
test-ast
