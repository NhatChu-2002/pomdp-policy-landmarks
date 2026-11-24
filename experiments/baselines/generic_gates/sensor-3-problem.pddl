(define (problem p-sensor-3-bsc)
  (:domain sensor-3-bsc)
  (:objects
    1-ok 1-faulty - sensor-1
    2-ok 2-faulty - sensor-2
    3-ok 3-faulty - sensor-3
  )
  (:init
    (self-sensor-1-1-ok 1-ok)
    (self-sensor-1-1-faulty 1-faulty)
    (uncertain-sensor-1)
    (self-sensor-2-2-ok 2-ok)
    (self-sensor-2-2-faulty 2-faulty)
    (uncertain-sensor-2)
    (self-sensor-3-3-ok 3-ok)
    (self-sensor-3-3-faulty 3-faulty)
    (uncertain-sensor-3)
  )
  (:goal (and (done)))
)
