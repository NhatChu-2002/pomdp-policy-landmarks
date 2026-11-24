(define (domain sensor-3-bsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types sensor-1 - object sensor-2 - object sensor-3 - object)
  (:predicates
    (self-sensor-1-1-ok ?x - sensor-1)
    (self-sensor-1-1-faulty ?x - sensor-1)
    (self-sensor-2-2-ok ?x - sensor-2)
    (self-sensor-2-2-faulty ?x - sensor-2)
    (self-sensor-3-3-ok ?x - sensor-3)
    (self-sensor-3-3-faulty ?x - sensor-3)
    (k-sensor-1 ?x - sensor-1)
    (k-not-sensor-1 ?x - sensor-1)
    (committed-sensor-1)
    (uncertain-sensor-1)
    (k-sensor-2 ?x - sensor-2)
    (k-not-sensor-2 ?x - sensor-2)
    (committed-sensor-2)
    (uncertain-sensor-2)
    (k-sensor-3 ?x - sensor-3)
    (k-not-sensor-3 ?x - sensor-3)
    (committed-sensor-3)
    (uncertain-sensor-3)
    (done)
  )
  (:action sense-1-agree-0
    :parameters (?x-sensor-1-1-ok - sensor-1)
    :precondition (and
      (self-sensor-1-1-ok ?x-sensor-1-1-ok)
      (uncertain-sensor-1))
    :effect (and
      (not (uncertain-sensor-1))
      (k-sensor-1 ?x-sensor-1-1-ok))
  )
  (:action sense-1-disagree-1
    :parameters (?x-sensor-1-1-faulty - sensor-1)
    :precondition (and
      (self-sensor-1-1-faulty ?x-sensor-1-1-faulty)
      (uncertain-sensor-1))
    :effect (and
      (not (uncertain-sensor-1))
      (k-sensor-1 ?x-sensor-1-1-faulty))
  )
  (:action sense-1-agree-2
    :parameters (?x-sensor-1-1-ok - sensor-1 ?x-sensor-1-1-faulty - sensor-1)
    :precondition (and
      (self-sensor-1-1-ok ?x-sensor-1-1-ok)
      (self-sensor-1-1-faulty ?x-sensor-1-1-faulty)
      (k-sensor-1 ?x-sensor-1-1-ok)
      (not (k-not-sensor-1 ?x-sensor-1-1-faulty)))
    :effect (and
      (k-not-sensor-1 ?x-sensor-1-1-faulty))
  )
  (:action sense-1-disagree-3
    :parameters (?x-sensor-1-1-faulty - sensor-1 ?x-sensor-1-1-ok - sensor-1)
    :precondition (and
      (self-sensor-1-1-faulty ?x-sensor-1-1-faulty)
      (self-sensor-1-1-ok ?x-sensor-1-1-ok)
      (k-sensor-1 ?x-sensor-1-1-faulty)
      (not (k-not-sensor-1 ?x-sensor-1-1-ok)))
    :effect (and
      (k-not-sensor-1 ?x-sensor-1-1-ok))
  )
  (:action sense-1-disagree-4
    :parameters (?x-sensor-1-1-ok - sensor-1 ?x-sensor-1-1-faulty - sensor-1)
    :precondition (and
      (self-sensor-1-1-ok ?x-sensor-1-1-ok)
      (self-sensor-1-1-faulty ?x-sensor-1-1-faulty)
      (k-sensor-1 ?x-sensor-1-1-ok)
      (not (k-not-sensor-1 ?x-sensor-1-1-faulty)))
    :effect (and
      (not (k-sensor-1 ?x-sensor-1-1-ok))
      (uncertain-sensor-1))
  )
  (:action sense-1-agree-5
    :parameters (?x-sensor-1-1-faulty - sensor-1 ?x-sensor-1-1-ok - sensor-1)
    :precondition (and
      (self-sensor-1-1-faulty ?x-sensor-1-1-faulty)
      (self-sensor-1-1-ok ?x-sensor-1-1-ok)
      (k-sensor-1 ?x-sensor-1-1-faulty)
      (not (k-not-sensor-1 ?x-sensor-1-1-ok)))
    :effect (and
      (not (k-sensor-1 ?x-sensor-1-1-faulty))
      (uncertain-sensor-1))
  )
  (:action sense-2-agree-6
    :parameters (?x-sensor-2-2-ok - sensor-2)
    :precondition (and
      (self-sensor-2-2-ok ?x-sensor-2-2-ok)
      (uncertain-sensor-2))
    :effect (and
      (not (uncertain-sensor-2))
      (k-sensor-2 ?x-sensor-2-2-ok))
  )
  (:action sense-2-disagree-7
    :parameters (?x-sensor-2-2-faulty - sensor-2)
    :precondition (and
      (self-sensor-2-2-faulty ?x-sensor-2-2-faulty)
      (uncertain-sensor-2))
    :effect (and
      (not (uncertain-sensor-2))
      (k-sensor-2 ?x-sensor-2-2-faulty))
  )
  (:action sense-2-agree-8
    :parameters (?x-sensor-2-2-ok - sensor-2 ?x-sensor-2-2-faulty - sensor-2)
    :precondition (and
      (self-sensor-2-2-ok ?x-sensor-2-2-ok)
      (self-sensor-2-2-faulty ?x-sensor-2-2-faulty)
      (k-sensor-2 ?x-sensor-2-2-ok)
      (not (k-not-sensor-2 ?x-sensor-2-2-faulty)))
    :effect (and
      (k-not-sensor-2 ?x-sensor-2-2-faulty))
  )
  (:action sense-2-disagree-9
    :parameters (?x-sensor-2-2-faulty - sensor-2 ?x-sensor-2-2-ok - sensor-2)
    :precondition (and
      (self-sensor-2-2-faulty ?x-sensor-2-2-faulty)
      (self-sensor-2-2-ok ?x-sensor-2-2-ok)
      (k-sensor-2 ?x-sensor-2-2-faulty)
      (not (k-not-sensor-2 ?x-sensor-2-2-ok)))
    :effect (and
      (k-not-sensor-2 ?x-sensor-2-2-ok))
  )
  (:action sense-2-disagree-10
    :parameters (?x-sensor-2-2-ok - sensor-2 ?x-sensor-2-2-faulty - sensor-2)
    :precondition (and
      (self-sensor-2-2-ok ?x-sensor-2-2-ok)
      (self-sensor-2-2-faulty ?x-sensor-2-2-faulty)
      (k-sensor-2 ?x-sensor-2-2-ok)
      (not (k-not-sensor-2 ?x-sensor-2-2-faulty)))
    :effect (and
      (not (k-sensor-2 ?x-sensor-2-2-ok))
      (uncertain-sensor-2))
  )
  (:action sense-2-agree-11
    :parameters (?x-sensor-2-2-faulty - sensor-2 ?x-sensor-2-2-ok - sensor-2)
    :precondition (and
      (self-sensor-2-2-faulty ?x-sensor-2-2-faulty)
      (self-sensor-2-2-ok ?x-sensor-2-2-ok)
      (k-sensor-2 ?x-sensor-2-2-faulty)
      (not (k-not-sensor-2 ?x-sensor-2-2-ok)))
    :effect (and
      (not (k-sensor-2 ?x-sensor-2-2-faulty))
      (uncertain-sensor-2))
  )
  (:action sense-3-agree-12
    :parameters (?x-sensor-3-3-ok - sensor-3)
    :precondition (and
      (self-sensor-3-3-ok ?x-sensor-3-3-ok)
      (uncertain-sensor-3))
    :effect (and
      (not (uncertain-sensor-3))
      (k-sensor-3 ?x-sensor-3-3-ok))
  )
  (:action sense-3-disagree-13
    :parameters (?x-sensor-3-3-faulty - sensor-3)
    :precondition (and
      (self-sensor-3-3-faulty ?x-sensor-3-3-faulty)
      (uncertain-sensor-3))
    :effect (and
      (not (uncertain-sensor-3))
      (k-sensor-3 ?x-sensor-3-3-faulty))
  )
  (:action sense-3-agree-14
    :parameters (?x-sensor-3-3-ok - sensor-3 ?x-sensor-3-3-faulty - sensor-3)
    :precondition (and
      (self-sensor-3-3-ok ?x-sensor-3-3-ok)
      (self-sensor-3-3-faulty ?x-sensor-3-3-faulty)
      (k-sensor-3 ?x-sensor-3-3-ok)
      (not (k-not-sensor-3 ?x-sensor-3-3-faulty)))
    :effect (and
      (k-not-sensor-3 ?x-sensor-3-3-faulty))
  )
  (:action sense-3-disagree-15
    :parameters (?x-sensor-3-3-faulty - sensor-3 ?x-sensor-3-3-ok - sensor-3)
    :precondition (and
      (self-sensor-3-3-faulty ?x-sensor-3-3-faulty)
      (self-sensor-3-3-ok ?x-sensor-3-3-ok)
      (k-sensor-3 ?x-sensor-3-3-faulty)
      (not (k-not-sensor-3 ?x-sensor-3-3-ok)))
    :effect (and
      (k-not-sensor-3 ?x-sensor-3-3-ok))
  )
  (:action sense-3-disagree-16
    :parameters (?x-sensor-3-3-ok - sensor-3 ?x-sensor-3-3-faulty - sensor-3)
    :precondition (and
      (self-sensor-3-3-ok ?x-sensor-3-3-ok)
      (self-sensor-3-3-faulty ?x-sensor-3-3-faulty)
      (k-sensor-3 ?x-sensor-3-3-ok)
      (not (k-not-sensor-3 ?x-sensor-3-3-faulty)))
    :effect (and
      (not (k-sensor-3 ?x-sensor-3-3-ok))
      (uncertain-sensor-3))
  )
  (:action sense-3-agree-17
    :parameters (?x-sensor-3-3-faulty - sensor-3 ?x-sensor-3-3-ok - sensor-3)
    :precondition (and
      (self-sensor-3-3-faulty ?x-sensor-3-3-faulty)
      (self-sensor-3-3-ok ?x-sensor-3-3-ok)
      (k-sensor-3 ?x-sensor-3-3-faulty)
      (not (k-not-sensor-3 ?x-sensor-3-3-ok)))
    :effect (and
      (not (k-sensor-3 ?x-sensor-3-3-faulty))
      (uncertain-sensor-3))
  )
  (:action commit-sensor-1-1-ok-0
    :parameters (?x-sensor-1-1-ok - sensor-1)
    :precondition (and
      (self-sensor-1-1-ok ?x-sensor-1-1-ok)
      (k-sensor-1 ?x-sensor-1-1-ok)
      (not (committed-sensor-1)))
    :effect (and
      (committed-sensor-1))
  )
  (:action commit-sensor-1-1-faulty-1
    :parameters (?x-sensor-1-1-faulty - sensor-1)
    :precondition (and
      (self-sensor-1-1-faulty ?x-sensor-1-1-faulty)
      (k-sensor-1 ?x-sensor-1-1-faulty)
      (not (committed-sensor-1)))
    :effect (and
      (committed-sensor-1))
  )
  (:action commit-sensor-2-2-ok-2
    :parameters (?x-sensor-2-2-ok - sensor-2)
    :precondition (and
      (self-sensor-2-2-ok ?x-sensor-2-2-ok)
      (k-sensor-2 ?x-sensor-2-2-ok)
      (not (committed-sensor-2)))
    :effect (and
      (committed-sensor-2))
  )
  (:action commit-sensor-2-2-faulty-3
    :parameters (?x-sensor-2-2-faulty - sensor-2)
    :precondition (and
      (self-sensor-2-2-faulty ?x-sensor-2-2-faulty)
      (k-sensor-2 ?x-sensor-2-2-faulty)
      (not (committed-sensor-2)))
    :effect (and
      (committed-sensor-2))
  )
  (:action commit-sensor-3-3-ok-4
    :parameters (?x-sensor-3-3-ok - sensor-3)
    :precondition (and
      (self-sensor-3-3-ok ?x-sensor-3-3-ok)
      (k-sensor-3 ?x-sensor-3-3-ok)
      (not (committed-sensor-3)))
    :effect (and
      (committed-sensor-3))
  )
  (:action commit-sensor-3-3-faulty-5
    :parameters (?x-sensor-3-3-faulty - sensor-3)
    :precondition (and
      (self-sensor-3-3-faulty ?x-sensor-3-3-faulty)
      (k-sensor-3 ?x-sensor-3-3-faulty)
      (not (committed-sensor-3)))
    :effect (and
      (committed-sensor-3))
  )
  (:action finish
    :parameters ()
    :precondition (and
      (committed-sensor-1)
      (committed-sensor-2)
      (committed-sensor-3))
    :effect (and
      (done))
  )
)
