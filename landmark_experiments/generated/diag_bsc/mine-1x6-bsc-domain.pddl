(define (domain mine-1x6-bsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types mine-cell - object)
  (:predicates
    (self-mine-cell-c00 ?x - mine-cell)
    (self-mine-cell-c01 ?x - mine-cell)
    (self-mine-cell-c02 ?x - mine-cell)
    (self-mine-cell-c03 ?x - mine-cell)
    (self-mine-cell-c04 ?x - mine-cell)
    (self-mine-cell-c05 ?x - mine-cell)
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
  (:action sense-mine-c03-3
    :parameters (?x-mine-cell-c03 - mine-cell)
    :precondition (and
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (uncertain-mine-cell))
    :effect (and
      (not (uncertain-mine-cell))
      (k-mine-cell ?x-mine-cell-c03))
  )
  (:action sense-mine-c04-4
    :parameters (?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (uncertain-mine-cell))
    :effect (and
      (not (uncertain-mine-cell))
      (k-mine-cell ?x-mine-cell-c04))
  )
  (:action sense-mine-c05-5
    :parameters (?x-mine-cell-c05 - mine-cell)
    :precondition (and
      (self-mine-cell-c05 ?x-mine-cell-c05)
      (uncertain-mine-cell))
    :effect (and
      (not (uncertain-mine-cell))
      (k-mine-cell ?x-mine-cell-c05))
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
  (:action sense-safe-c03-8
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c03 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c03))
  )
  (:action sense-safe-c04-9
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c04))
  )
  (:action sense-safe-c05-10
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c05 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c05 ?x-mine-cell-c05)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c05))
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
  (:action sense-safe-c03-13
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c03 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c03))
  )
  (:action sense-safe-c04-14
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c04))
  )
  (:action sense-safe-c05-15
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c05 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c05 ?x-mine-cell-c05)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c05))
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
  (:action sense-safe-c03-18
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c03 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c03))
  )
  (:action sense-safe-c04-19
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c04))
  )
  (:action sense-safe-c05-20
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c05 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c05 ?x-mine-cell-c05)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c05))
  )
  (:action sense-safe-c00-21
    :parameters (?x-mine-cell-c03 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c03))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-22
    :parameters (?x-mine-cell-c03 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c03))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-23
    :parameters (?x-mine-cell-c03 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c03))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c04-24
    :parameters (?x-mine-cell-c03 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (k-mine-cell ?x-mine-cell-c03))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c04))
  )
  (:action sense-safe-c05-25
    :parameters (?x-mine-cell-c03 - mine-cell ?x-mine-cell-c05 - mine-cell)
    :precondition (and
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c05 ?x-mine-cell-c05)
      (k-mine-cell ?x-mine-cell-c03))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c05))
  )
  (:action sense-safe-c00-26
    :parameters (?x-mine-cell-c04 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c04))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-27
    :parameters (?x-mine-cell-c04 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c04))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-28
    :parameters (?x-mine-cell-c04 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c04))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c03-29
    :parameters (?x-mine-cell-c04 - mine-cell ?x-mine-cell-c03 - mine-cell)
    :precondition (and
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (k-mine-cell ?x-mine-cell-c04))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c03))
  )
  (:action sense-safe-c05-30
    :parameters (?x-mine-cell-c04 - mine-cell ?x-mine-cell-c05 - mine-cell)
    :precondition (and
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (self-mine-cell-c05 ?x-mine-cell-c05)
      (k-mine-cell ?x-mine-cell-c04))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c05))
  )
  (:action sense-safe-c00-31
    :parameters (?x-mine-cell-c05 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c05 ?x-mine-cell-c05)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c05))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-32
    :parameters (?x-mine-cell-c05 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c05 ?x-mine-cell-c05)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c05))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-33
    :parameters (?x-mine-cell-c05 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c05 ?x-mine-cell-c05)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c05))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c03-34
    :parameters (?x-mine-cell-c05 - mine-cell ?x-mine-cell-c03 - mine-cell)
    :precondition (and
      (self-mine-cell-c05 ?x-mine-cell-c05)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (k-mine-cell ?x-mine-cell-c05))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c03))
  )
  (:action sense-safe-c04-35
    :parameters (?x-mine-cell-c05 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c05 ?x-mine-cell-c05)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (k-mine-cell ?x-mine-cell-c05))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c04))
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
  (:action commit-mine-cell-c03-3
    :parameters (?x-mine-cell-c03 - mine-cell)
    :precondition (and
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (k-mine-cell ?x-mine-cell-c03)
      (not (committed-mine-cell)))
    :effect (and
      (committed-mine-cell))
  )
  (:action commit-mine-cell-c04-4
    :parameters (?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (k-mine-cell ?x-mine-cell-c04)
      (not (committed-mine-cell)))
    :effect (and
      (committed-mine-cell))
  )
  (:action commit-mine-cell-c05-5
    :parameters (?x-mine-cell-c05 - mine-cell)
    :precondition (and
      (self-mine-cell-c05 ?x-mine-cell-c05)
      (k-mine-cell ?x-mine-cell-c05)
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
