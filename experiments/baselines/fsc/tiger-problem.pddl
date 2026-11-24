(define (problem p-tiger)
  (:domain tiger)
  (:objects
    nroot nl1 nr1 ncommit - node
    left right - direction
  )
  (:init
    (at nroot)
    (commit-node ncommit)
    (trans-growl-left nroot nl1)
    (writes-k-direction nroot nl1 left)
    (trans-growl-right nroot nr1)
    (writes-k-direction nroot nr1 right)
    (trans-growl-left nl1 ncommit)
    (writes-knot-direction nl1 ncommit right)
    (trans-growl-right nr1 ncommit)
    (writes-knot-direction nr1 ncommit left)
    (trans-growl-right nl1 nroot)
    (no-write nl1 nroot)
    (trans-growl-left nr1 nroot)
    (no-write nr1 nroot)
  )
  (:goal (and (done)))
)
