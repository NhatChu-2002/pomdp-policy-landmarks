(define (problem p-rocksample-4-bsc)
  (:domain rocksample-4-bsc)
  (:objects
    r1-good r1-bad - rock-1
    r2-good r2-bad - rock-2
    r3-good r3-bad - rock-3
    r4-good r4-bad - rock-4
  )
  (:init
    (self-rock-1-r1-good r1-good)
    (self-rock-1-r1-bad r1-bad)
    (uncertain-rock-1)
    (self-rock-2-r2-good r2-good)
    (self-rock-2-r2-bad r2-bad)
    (uncertain-rock-2)
    (self-rock-3-r3-good r3-good)
    (self-rock-3-r3-bad r3-bad)
    (uncertain-rock-3)
    (self-rock-4-r4-good r4-good)
    (self-rock-4-r4-bad r4-bad)
    (uncertain-rock-4)
  )
  (:goal (and (done)))
)
