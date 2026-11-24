(define (domain channel-bsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types channel - object)
  (:predicates
    (self-channel-c1 ?x - channel)
    (self-channel-c2 ?x - channel)
    (self-channel-c3 ?x - channel)
    (k-channel ?x - channel)
    (k-not-channel ?x - channel)
    (committed-channel)
    (neg-committed-channel)
    (confirmed-channel)
    (uncertain-channel)
    (done)
  )
  (:action sense-signal-c1-0
    :parameters (?x-channel-c1 - channel)
    :precondition (and
      (self-channel-c1 ?x-channel-c1)
      (uncertain-channel))
    :effect (and
      (not (uncertain-channel))
      (k-channel ?x-channel-c1))
  )
  (:action sense-signal-c2-1
    :parameters (?x-channel-c2 - channel)
    :precondition (and
      (self-channel-c2 ?x-channel-c2)
      (uncertain-channel))
    :effect (and
      (not (uncertain-channel))
      (k-channel ?x-channel-c2))
  )
  (:action sense-signal-c3-2
    :parameters (?x-channel-c3 - channel)
    :precondition (and
      (self-channel-c3 ?x-channel-c3)
      (uncertain-channel))
    :effect (and
      (not (uncertain-channel))
      (k-channel ?x-channel-c3))
  )
  (:action sense-noise-c2-3
    :parameters (?x-channel-c1 - channel ?x-channel-c2 - channel)
    :precondition (and
      (self-channel-c1 ?x-channel-c1)
      (self-channel-c2 ?x-channel-c2)
      (k-channel ?x-channel-c1))
    :effect (and
      (k-not-channel ?x-channel-c2))
  )
  (:action sense-noise-c3-4
    :parameters (?x-channel-c1 - channel ?x-channel-c3 - channel)
    :precondition (and
      (self-channel-c1 ?x-channel-c1)
      (self-channel-c3 ?x-channel-c3)
      (k-channel ?x-channel-c1))
    :effect (and
      (k-not-channel ?x-channel-c3))
  )
  (:action sense-noise-c1-5
    :parameters (?x-channel-c2 - channel ?x-channel-c1 - channel)
    :precondition (and
      (self-channel-c2 ?x-channel-c2)
      (self-channel-c1 ?x-channel-c1)
      (k-channel ?x-channel-c2))
    :effect (and
      (k-not-channel ?x-channel-c1))
  )
  (:action sense-noise-c3-6
    :parameters (?x-channel-c2 - channel ?x-channel-c3 - channel)
    :precondition (and
      (self-channel-c2 ?x-channel-c2)
      (self-channel-c3 ?x-channel-c3)
      (k-channel ?x-channel-c2))
    :effect (and
      (k-not-channel ?x-channel-c3))
  )
  (:action sense-noise-c1-7
    :parameters (?x-channel-c3 - channel ?x-channel-c1 - channel)
    :precondition (and
      (self-channel-c3 ?x-channel-c3)
      (self-channel-c1 ?x-channel-c1)
      (k-channel ?x-channel-c3))
    :effect (and
      (k-not-channel ?x-channel-c1))
  )
  (:action sense-noise-c2-8
    :parameters (?x-channel-c3 - channel ?x-channel-c2 - channel)
    :precondition (and
      (self-channel-c3 ?x-channel-c3)
      (self-channel-c2 ?x-channel-c2)
      (k-channel ?x-channel-c3))
    :effect (and
      (k-not-channel ?x-channel-c2))
  )
  (:action sense-signal-c2-9
    :parameters (?x-channel-c1 - channel)
    :precondition (and
      (self-channel-c1 ?x-channel-c1)
      (k-channel ?x-channel-c1))
    :effect (and
      (not (k-channel ?x-channel-c1))
      (uncertain-channel))
  )
  (:action sense-signal-c3-10
    :parameters (?x-channel-c1 - channel)
    :precondition (and
      (self-channel-c1 ?x-channel-c1)
      (k-channel ?x-channel-c1))
    :effect (and
      (not (k-channel ?x-channel-c1))
      (uncertain-channel))
  )
  (:action sense-signal-c1-11
    :parameters (?x-channel-c2 - channel)
    :precondition (and
      (self-channel-c2 ?x-channel-c2)
      (k-channel ?x-channel-c2))
    :effect (and
      (not (k-channel ?x-channel-c2))
      (uncertain-channel))
  )
  (:action sense-signal-c3-12
    :parameters (?x-channel-c2 - channel)
    :precondition (and
      (self-channel-c2 ?x-channel-c2)
      (k-channel ?x-channel-c2))
    :effect (and
      (not (k-channel ?x-channel-c2))
      (uncertain-channel))
  )
  (:action sense-signal-c1-13
    :parameters (?x-channel-c3 - channel)
    :precondition (and
      (self-channel-c3 ?x-channel-c3)
      (k-channel ?x-channel-c3))
    :effect (and
      (not (k-channel ?x-channel-c3))
      (uncertain-channel))
  )
  (:action sense-signal-c2-14
    :parameters (?x-channel-c3 - channel)
    :precondition (and
      (self-channel-c3 ?x-channel-c3)
      (k-channel ?x-channel-c3))
    :effect (and
      (not (k-channel ?x-channel-c3))
      (uncertain-channel))
  )
  (:action commit-channel
    :parameters (?x - channel)
    :precondition (and
      (k-channel ?x)
      (not (committed-channel)))
    :effect (and
      (committed-channel))
  )
  (:action neg-commit-channel
    :parameters (?x - channel)
    :precondition (and
      (k-not-channel ?x)
      (not (neg-committed-channel)))
    :effect (and
      (neg-committed-channel))
  )
  (:action confirm-channel
    :parameters (?x - channel)
    :precondition (and
      (committed-channel)
      (neg-committed-channel)
      (k-channel ?x)
      (not (confirmed-channel)))
    :effect (and
      (confirmed-channel))
  )
  (:action finish
    :parameters ()
    :precondition (and
      (confirmed-channel))
    :effect (and
      (done))
  )
)
