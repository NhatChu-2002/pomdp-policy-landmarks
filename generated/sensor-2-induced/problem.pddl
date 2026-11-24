(define (problem p-sensor-2-induced)
  (:domain sensor-2-induced)
  (:objects
    a-ok a-faulty - sensor-a
    b-ok b-faulty - sensor-b
  )
  (:init
    (self-sensor-a-a-ok a-ok)
    (self-sensor-a-a-faulty a-faulty)
    (uncertain-sensor-a)
    (self-sensor-b-b-ok b-ok)
    (self-sensor-b-b-faulty b-faulty)
    (uncertain-sensor-b)
  )
  (:goal (and (done)))
)
