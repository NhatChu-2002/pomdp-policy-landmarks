(define (problem p-mine-3x3-bsc)
  (:domain mine-3x3-bsc)
  (:objects
    c00 c01 c02 c10 c11 c12 c20 c21 c22 - mine-cell
  )
  (:init
    (self-mine-cell-c00 c00)
    (self-mine-cell-c01 c01)
    (self-mine-cell-c02 c02)
    (self-mine-cell-c10 c10)
    (self-mine-cell-c11 c11)
    (self-mine-cell-c12 c12)
    (self-mine-cell-c20 c20)
    (self-mine-cell-c21 c21)
    (self-mine-cell-c22 c22)
  )
  (:goal (and (done)))
)
