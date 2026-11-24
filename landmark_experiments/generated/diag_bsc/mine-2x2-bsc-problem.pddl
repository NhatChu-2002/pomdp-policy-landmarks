(define (problem p-mine-2x2-bsc)
  (:domain mine-2x2-bsc)
  (:objects
    c00 c01 c10 c11 - mine-cell
  )
  (:init
    (self-mine-cell-c00 c00)
    (self-mine-cell-c01 c01)
    (self-mine-cell-c10 c10)
    (self-mine-cell-c11 c11)
    (uncertain-mine-cell)
  )
  (:goal (and (done)))
)
