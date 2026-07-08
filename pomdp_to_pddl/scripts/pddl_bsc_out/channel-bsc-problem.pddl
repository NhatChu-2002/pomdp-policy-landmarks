(define (problem p-channel-bsc)
  (:domain channel-bsc)
  (:objects
    c1 c2 c3 - channel
  )
  (:init
    (self-channel-c1 c1)
    (self-channel-c2 c2)
    (self-channel-c3 c3)
  )
  (:goal (and (done)))
)
