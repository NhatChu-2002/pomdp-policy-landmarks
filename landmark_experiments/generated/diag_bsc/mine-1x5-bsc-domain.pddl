(define (domain mine-1x5-bsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types mine-cell - object)
  (:predicates
    (self-mine-cell-c00 ?x - mine-cell)
    (self-mine-cell-c01 ?x - mine-cell)
    (self-mine-cell-c02 ?x - mine-cell)
    (self-mine-cell-c03 ?x - mine-cell)
    (self-mine-cell-c04 ?x - mine-cell)
    (k-mine-cell ?x - mine-cell)
    (k-not-mine-cell ?x - mine-cell)
    (committed-mine-cell)
    (neg-committed-mine-cell)
    (confirmed-mine-cell)
    (done)
  )
  (:action sense-mine-c00-0
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c03 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c03))
      (not (k-mine-cell ?x-mine-cell-c04)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-mine-c01-1
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c03 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c03))
      (not (k-mine-cell ?x-mine-cell-c04)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-mine-c02-2
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c03 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c03))
      (not (k-mine-cell ?x-mine-cell-c04)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-mine-c03-3
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c03 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c03))
      (not (k-mine-cell ?x-mine-cell-c04)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c03))
  )
  (:action sense-mine-c04-4
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c03 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c03))
      (not (k-mine-cell ?x-mine-cell-c04)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c04))
  )
  (:action sense-safe-c01-5
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-6
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c03-7
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c03 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c03))
  )
  (:action sense-safe-c04-8
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c04))
  )
  (:action sense-safe-c00-9
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c02-10
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c03-11
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c03 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c03))
  )
  (:action sense-safe-c04-12
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c04))
  )
  (:action sense-safe-c00-13
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-14
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c03-15
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c03 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c03))
  )
  (:action sense-safe-c04-16
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c04))
  )
  (:action sense-safe-c00-17
    :parameters (?x-mine-cell-c03 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c03))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-18
    :parameters (?x-mine-cell-c03 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c03))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-19
    :parameters (?x-mine-cell-c03 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c03))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c04-20
    :parameters (?x-mine-cell-c03 - mine-cell ?x-mine-cell-c04 - mine-cell)
    :precondition (and
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (k-mine-cell ?x-mine-cell-c03))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c04))
  )
  (:action sense-safe-c00-21
    :parameters (?x-mine-cell-c04 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c04))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-22
    :parameters (?x-mine-cell-c04 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c04))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-23
    :parameters (?x-mine-cell-c04 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c04))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c03-24
    :parameters (?x-mine-cell-c04 - mine-cell ?x-mine-cell-c03 - mine-cell)
    :precondition (and
      (self-mine-cell-c04 ?x-mine-cell-c04)
      (self-mine-cell-c03 ?x-mine-cell-c03)
      (k-mine-cell ?x-mine-cell-c04))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c03))
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
