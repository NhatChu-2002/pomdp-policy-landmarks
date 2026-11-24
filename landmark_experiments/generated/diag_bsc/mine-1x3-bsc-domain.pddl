(define (domain mine-1x3-bsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types mine-cell - object)
  (:predicates
    (self-mine-cell-c00 ?x - mine-cell)
    (self-mine-cell-c01 ?x - mine-cell)
    (self-mine-cell-c02 ?x - mine-cell)
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
  (:action sense-mine-c02-2
    :parameters (?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (uncertain-mine-cell))
    :effect (and
      (not (uncertain-mine-cell))
      (k-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c01-3
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-4
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c00-5
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c02-6
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c00-7
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-8
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
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
  (:action commit-mine-cell-c02-2
    :parameters (?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c02)
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
