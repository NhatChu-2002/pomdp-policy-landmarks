(define (problem p-mine-3x2-bsc)
  (:domain mine-3x2-bsc)
  (:objects
    c00 c01 c10 c11 c20 c21 - mine-cell
  )
  (:init
    (self-mine-cell-c00 c00)
    (self-mine-cell-c01 c01)
    (self-mine-cell-c10 c10)
    (self-mine-cell-c11 c11)
    (self-mine-cell-c20 c20)
    (self-mine-cell-c21 c21)
  )
  (:goal (and (done)))
)
