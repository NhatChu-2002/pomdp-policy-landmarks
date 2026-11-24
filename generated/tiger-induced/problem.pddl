(define (problem p-tiger-induced)
  (:domain tiger-induced)
  (:objects
    left right - direction
  )
  (:init
    (self-direction-left left)
    (self-direction-right right)
    (uncertain-direction)
  )
  (:goal (and (done)))
)
