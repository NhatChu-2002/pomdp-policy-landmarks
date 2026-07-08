(define (domain mine-2x3-bsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types mine-cell - object)
  (:predicates
    (self-mine-cell-c00 ?x - mine-cell)
    (self-mine-cell-c01 ?x - mine-cell)
    (self-mine-cell-c02 ?x - mine-cell)
    (self-mine-cell-c10 ?x - mine-cell)
    (self-mine-cell-c11 ?x - mine-cell)
    (self-mine-cell-c12 ?x - mine-cell)
    (k-mine-cell ?x - mine-cell)
    (k-not-mine-cell ?x - mine-cell)
    (committed-mine-cell)
    (neg-committed-mine-cell)
    (confirmed-mine-cell)
    (done)
  )
  (:action sense-mine-c00-0
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-mine-c01-1
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-mine-c02-2
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-mine-c10-3
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-mine-c11-4
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-mine-c12-5
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c01-6
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-7
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c10-8
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-9
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c12-10
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c00-11
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c02-12
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c10-13
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-14
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c12-15
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c00-16
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-17
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c10-18
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-19
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c12-20
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c00-21
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-22
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-23
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c11-24
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c12-25
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c00-26
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-27
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-28
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c10-29
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c12-30
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c00-31
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-32
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-33
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c10-34
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-35
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action commit-mine-cell
    :parameters (?x - mine-cell)
    :precondition (and
      (k-mine-cell ?x)
      (not (committed-mine-cell)))
    :effect (and
      (committed-mine-cell))
  )
  (:action neg-commit-mine-cell
    :parameters (?x - mine-cell)
    :precondition (and
      (k-not-mine-cell ?x)
      (not (neg-committed-mine-cell)))
    :effect (and
      (neg-committed-mine-cell))
  )
  (:action confirm-mine-cell
    :parameters (?x - mine-cell)
    :precondition (and
      (committed-mine-cell)
      (neg-committed-mine-cell)
      (k-mine-cell ?x)
      (not (confirmed-mine-cell)))
    :effect (and
      (confirmed-mine-cell))
  )
  (:action finish
    :parameters ()
    :precondition (and
      (confirmed-mine-cell))
    :effect (and
      (done))
  )
)
