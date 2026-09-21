(require (only-in racket/base with-handlers exn-message exn:fail? printf define-syntax-rule))
(define-syntax-rule (try e) (with-handlers ([exn:fail? (lambda (x) (list 'ERROR (exn-message x)))]) e))
