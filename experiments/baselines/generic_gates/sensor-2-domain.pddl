(define (domain sensor-bsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types sensor-a - object sensor-b - object)
  (:predicates
    (self-sensor-a-a-ok ?x - sensor-a)
    (self-sensor-a-a-faulty ?x - sensor-a)
    (self-sensor-b-b-ok ?x - sensor-b)
    (self-sensor-b-b-faulty ?x - sensor-b)
    (k-sensor-a ?x - sensor-a)
    (k-not-sensor-a ?x - sensor-a)
    (committed-sensor-a)
    (neg-committed-sensor-a)
    (confirmed-sensor-a)
    (uncertain-sensor-a)
    (k-sensor-b ?x - sensor-b)
    (k-not-sensor-b ?x - sensor-b)
    (committed-sensor-b)
    (neg-committed-sensor-b)
    (confirmed-sensor-b)
    (uncertain-sensor-b)
    (done)
  )
  (:action sense-a-agree-0
    :parameters (?x-sensor-a-a-ok - sensor-a)
    :precondition (and
      (self-sensor-a-a-ok ?x-sensor-a-a-ok)
      (uncertain-sensor-a))
    :effect (and
      (not (uncertain-sensor-a))
      (k-sensor-a ?x-sensor-a-a-ok))
  )
  (:action sense-a-disagree-1
    :parameters (?x-sensor-a-a-faulty - sensor-a)
    :precondition (and
      (self-sensor-a-a-faulty ?x-sensor-a-a-faulty)
      (uncertain-sensor-a))
    :effect (and
      (not (uncertain-sensor-a))
      (k-sensor-a ?x-sensor-a-a-faulty))
  )
  (:action sense-a-agree-2
    :parameters (?x-sensor-a-a-ok - sensor-a ?x-sensor-a-a-faulty - sensor-a)
    :precondition (and
      (self-sensor-a-a-ok ?x-sensor-a-a-ok)
      (self-sensor-a-a-faulty ?x-sensor-a-a-faulty)
      (k-sensor-a ?x-sensor-a-a-ok)
      (not (k-not-sensor-a ?x-sensor-a-a-faulty)))
    :effect (and
      (k-not-sensor-a ?x-sensor-a-a-faulty))
  )
  (:action sense-a-disagree-3
    :parameters (?x-sensor-a-a-faulty - sensor-a ?x-sensor-a-a-ok - sensor-a)
    :precondition (and
      (self-sensor-a-a-faulty ?x-sensor-a-a-faulty)
      (self-sensor-a-a-ok ?x-sensor-a-a-ok)
      (k-sensor-a ?x-sensor-a-a-faulty)
      (not (k-not-sensor-a ?x-sensor-a-a-ok)))
    :effect (and
      (k-not-sensor-a ?x-sensor-a-a-ok))
  )
  (:action sense-a-disagree-4
    :parameters (?x-sensor-a-a-ok - sensor-a ?x-sensor-a-a-faulty - sensor-a)
    :precondition (and
      (self-sensor-a-a-ok ?x-sensor-a-a-ok)
      (self-sensor-a-a-faulty ?x-sensor-a-a-faulty)
      (k-sensor-a ?x-sensor-a-a-ok)
      (not (k-not-sensor-a ?x-sensor-a-a-faulty)))
    :effect (and
      (not (k-sensor-a ?x-sensor-a-a-ok))
      (uncertain-sensor-a))
  )
  (:action sense-a-agree-5
    :parameters (?x-sensor-a-a-faulty - sensor-a ?x-sensor-a-a-ok - sensor-a)
    :precondition (and
      (self-sensor-a-a-faulty ?x-sensor-a-a-faulty)
      (self-sensor-a-a-ok ?x-sensor-a-a-ok)
      (k-sensor-a ?x-sensor-a-a-faulty)
      (not (k-not-sensor-a ?x-sensor-a-a-ok)))
    :effect (and
      (not (k-sensor-a ?x-sensor-a-a-faulty))
      (uncertain-sensor-a))
  )
  (:action sense-b-agree-6
    :parameters (?x-sensor-b-b-ok - sensor-b)
    :precondition (and
      (self-sensor-b-b-ok ?x-sensor-b-b-ok)
      (uncertain-sensor-b))
    :effect (and
      (not (uncertain-sensor-b))
      (k-sensor-b ?x-sensor-b-b-ok))
  )
  (:action sense-b-disagree-7
    :parameters (?x-sensor-b-b-faulty - sensor-b)
    :precondition (and
      (self-sensor-b-b-faulty ?x-sensor-b-b-faulty)
      (uncertain-sensor-b))
    :effect (and
      (not (uncertain-sensor-b))
      (k-sensor-b ?x-sensor-b-b-faulty))
  )
  (:action sense-b-agree-8
    :parameters (?x-sensor-b-b-ok - sensor-b ?x-sensor-b-b-faulty - sensor-b)
    :precondition (and
      (self-sensor-b-b-ok ?x-sensor-b-b-ok)
      (self-sensor-b-b-faulty ?x-sensor-b-b-faulty)
      (k-sensor-b ?x-sensor-b-b-ok)
      (not (k-not-sensor-b ?x-sensor-b-b-faulty)))
    :effect (and
      (k-not-sensor-b ?x-sensor-b-b-faulty))
  )
  (:action sense-b-disagree-9
    :parameters (?x-sensor-b-b-faulty - sensor-b ?x-sensor-b-b-ok - sensor-b)
    :precondition (and
      (self-sensor-b-b-faulty ?x-sensor-b-b-faulty)
      (self-sensor-b-b-ok ?x-sensor-b-b-ok)
      (k-sensor-b ?x-sensor-b-b-faulty)
      (not (k-not-sensor-b ?x-sensor-b-b-ok)))
    :effect (and
      (k-not-sensor-b ?x-sensor-b-b-ok))
  )
  (:action sense-b-disagree-10
    :parameters (?x-sensor-b-b-ok - sensor-b ?x-sensor-b-b-faulty - sensor-b)
    :precondition (and
      (self-sensor-b-b-ok ?x-sensor-b-b-ok)
      (self-sensor-b-b-faulty ?x-sensor-b-b-faulty)
      (k-sensor-b ?x-sensor-b-b-ok)
      (not (k-not-sensor-b ?x-sensor-b-b-faulty)))
    :effect (and
      (not (k-sensor-b ?x-sensor-b-b-ok))
      (uncertain-sensor-b))
  )
  (:action sense-b-agree-11
    :parameters (?x-sensor-b-b-faulty - sensor-b ?x-sensor-b-b-ok - sensor-b)
    :precondition (and
      (self-sensor-b-b-faulty ?x-sensor-b-b-faulty)
      (self-sensor-b-b-ok ?x-sensor-b-b-ok)
      (k-sensor-b ?x-sensor-b-b-faulty)
      (not (k-not-sensor-b ?x-sensor-b-b-ok)))
    :effect (and
      (not (k-sensor-b ?x-sensor-b-b-faulty))
      (uncertain-sensor-b))
  )
  (:action commit-sensor-a
    :parameters (?x - sensor-a)
    :precondition (and
      (k-sensor-a ?x)
      (not (committed-sensor-a)))
    :effect (and
      (committed-sensor-a))
  )
  (:action neg-commit-sensor-a
    :parameters (?x - sensor-a)
    :precondition (and
      (k-not-sensor-a ?x)
      (not (neg-committed-sensor-a)))
    :effect (and
      (neg-committed-sensor-a))
  )
  (:action confirm-sensor-a
    :parameters (?x - sensor-a)
    :precondition (and
      (committed-sensor-a)
      (neg-committed-sensor-a)
      (k-sensor-a ?x)
      (not (confirmed-sensor-a)))
    :effect (and
      (confirmed-sensor-a))
  )
  (:action commit-sensor-b
    :parameters (?x - sensor-b)
    :precondition (and
      (k-sensor-b ?x)
      (not (committed-sensor-b)))
    :effect (and
      (committed-sensor-b))
  )
  (:action neg-commit-sensor-b
    :parameters (?x - sensor-b)
    :precondition (and
      (k-not-sensor-b ?x)
      (not (neg-committed-sensor-b)))
    :effect (and
      (neg-committed-sensor-b))
  )
  (:action confirm-sensor-b
    :parameters (?x - sensor-b)
    :precondition (and
      (committed-sensor-b)
      (neg-committed-sensor-b)
      (k-sensor-b ?x)
      (not (confirmed-sensor-b)))
    :effect (and
      (confirmed-sensor-b))
  )
  (:action finish
    :parameters ()
    :precondition (and
      (confirmed-sensor-a)
      (confirmed-sensor-b))
    :effect (and
      (done))
  )
)
