(define (problem p-mine-2x3-bsc)
  (:domain mine-2x3-bsc)
  (:objects
    c00 c01 c02 c10 c11 c12 - mine-cell
  )
  (:init
    (self-mine-cell-c00 c00)
    (self-mine-cell-c01 c01)
    (self-mine-cell-c02 c02)
    (self-mine-cell-c10 c10)
    (self-mine-cell-c11 c11)
    (self-mine-cell-c12 c12)
  )
  (:goal (and (done)))
)
