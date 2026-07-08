(define (problem p-tiger-bsc)
  (:domain tiger-bsc)
  (:objects
    left right - direction
  )
  (:init
    (self-direction-left left)
    (self-direction-right right)
  )
  (:goal (and (done)))
)
