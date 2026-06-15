(define (problem p-tiger-trace-fsc)
  (:domain tiger-trace-fsc)
  (:objects
    nroot nseen-left nseen-right ncommit - node
    left right - direction
  )
  (:init
    (at nroot)
    (commit-node ncommit)
    (trans-left nroot nseen-left)
    (writes-k-direction nroot nseen-left left)
    (trans-right nroot nseen-right)
    (writes-k-direction nroot nseen-right right)
    (trans-left nseen-left ncommit)
    (writes-knot-direction nseen-left ncommit right)
    (trans-right nseen-left nroot)
    (no-write nseen-left nroot)
    (trans-left nseen-right nroot)
    (no-write nseen-right nroot)
    (trans-right nseen-right ncommit)
    (writes-knot-direction nseen-right ncommit left)
  )
  (:goal (and (done)))
)
