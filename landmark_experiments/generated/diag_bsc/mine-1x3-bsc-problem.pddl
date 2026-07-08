(define (problem p-mine-1x3-bsc)
  (:domain mine-1x3-bsc)
  (:objects
    c00 c01 c02 - mine-cell
  )
  (:init
    (self-mine-cell-c00 c00)
    (self-mine-cell-c01 c01)
    (self-mine-cell-c02 c02)
  )
  (:goal (and (done)))
)
