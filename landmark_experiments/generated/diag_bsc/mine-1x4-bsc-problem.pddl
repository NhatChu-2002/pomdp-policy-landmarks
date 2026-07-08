(define (problem p-mine-1x4-bsc)
  (:domain mine-1x4-bsc)
  (:objects
    c00 c01 c02 c03 - mine-cell
  )
  (:init
    (self-mine-cell-c00 c00)
    (self-mine-cell-c01 c01)
    (self-mine-cell-c02 c02)
    (self-mine-cell-c03 c03)
  )
  (:goal (and (done)))
)
