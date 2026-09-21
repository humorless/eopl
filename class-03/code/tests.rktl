(define e
  (extend-env 'd 6
    (extend-env 'y 8
      (extend-env 'x 7
        (extend-env 'y 14 (empty-env))))))
(printf "result: ~s\n" (list (apply-env e 'd) (apply-env e 'x) (apply-env e 'y)))
(printf "e: ~s\n" e)
(printf "small: ~s\n" (extend-env 'x 7 (empty-env)))
(printf "unbound z: ~s\n" (try (apply-env e 'z)))
