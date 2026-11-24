(define (problem p-mine-1x6-bsc)
  (:domain mine-1x6-bsc)
  (:objects
    c00 c01 c02 c03 c04 c05 - mine-cell
  )
  (:init
    (self-mine-cell-c00 c00)
    (self-mine-cell-c01 c01)
    (self-mine-cell-c02 c02)
    (self-mine-cell-c03 c03)
    (self-mine-cell-c04 c04)
    (self-mine-cell-c05 c05)
    (uncertain-mine-cell)
  )
  (:goal (and (done)))
)
