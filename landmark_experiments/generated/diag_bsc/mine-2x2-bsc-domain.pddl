(define (domain mine-2x2-bsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types mine-cell - object)
  (:predicates
    (self-mine-cell-c00 ?x - mine-cell)
    (self-mine-cell-c01 ?x - mine-cell)
    (self-mine-cell-c10 ?x - mine-cell)
    (self-mine-cell-c11 ?x - mine-cell)
    (k-mine-cell ?x - mine-cell)
    (k-not-mine-cell ?x - mine-cell)
    (committed-mine-cell)
    (uncertain-mine-cell)
    (done)
  )
  (:action sense-mine-c00-0
    :parameters (?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (uncertain-mine-cell))
    :effect (and
      (not (uncertain-mine-cell))
      (k-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-mine-c01-1
    :parameters (?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (uncertain-mine-cell))
    :effect (and
      (not (uncertain-mine-cell))
      (k-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-mine-c10-2
    :parameters (?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (uncertain-mine-cell))
    :effect (and
      (not (uncertain-mine-cell))
      (k-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-mine-c11-3
    :parameters (?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (uncertain-mine-cell))
    :effect (and
      (not (uncertain-mine-cell))
      (k-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c01-4
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c10-5
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-6
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c00-7
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c10-8
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-9
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c00-10
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-11
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c11-12
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c00-13
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-14
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c10-15
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action commit-mine-cell-c00-0
    :parameters (?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c00)
      (not (committed-mine-cell)))
    :effect (and
      (committed-mine-cell))
  )
  (:action commit-mine-cell-c01-1
    :parameters (?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c01)
      (not (committed-mine-cell)))
    :effect (and
      (committed-mine-cell))
  )
  (:action commit-mine-cell-c10-2
    :parameters (?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c10)
      (not (committed-mine-cell)))
    :effect (and
      (committed-mine-cell))
  )
  (:action commit-mine-cell-c11-3
    :parameters (?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c11)
      (not (committed-mine-cell)))
    :effect (and
      (committed-mine-cell))
  )
  (:action finish
    :parameters ()
    :precondition (and
      (committed-mine-cell))
    :effect (and
      (done))
  )
)
