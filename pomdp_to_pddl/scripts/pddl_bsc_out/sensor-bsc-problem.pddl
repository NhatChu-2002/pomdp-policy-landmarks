(define (problem p-sensor-bsc)
  (:domain sensor-bsc)
  (:objects
    a-ok a-faulty - sensor-a
    b-ok b-faulty - sensor-b
  )
  (:init
    (self-sensor-a-a-ok a-ok)
    (self-sensor-a-a-faulty a-faulty)
    (self-sensor-b-b-ok b-ok)
    (self-sensor-b-b-faulty b-faulty)
  )
  (:goal (and (done)))
)
