(define (problem p-tiger-induced-bsc)
  (:domain tiger-induced-bsc)
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
