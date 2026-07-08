(define (domain mine-3x2-bsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types mine-cell - object)
  (:predicates
    (self-mine-cell-c00 ?x - mine-cell)
    (self-mine-cell-c01 ?x - mine-cell)
    (self-mine-cell-c10 ?x - mine-cell)
    (self-mine-cell-c11 ?x - mine-cell)
    (self-mine-cell-c20 ?x - mine-cell)
    (self-mine-cell-c21 ?x - mine-cell)
    (k-mine-cell ?x - mine-cell)
    (k-not-mine-cell ?x - mine-cell)
    (committed-mine-cell)
    (neg-committed-mine-cell)
    (confirmed-mine-cell)
    (done)
  )
  (:action sense-mine-c00-0
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-mine-c01-1
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-mine-c10-2
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-mine-c11-3
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-mine-c20-4
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-mine-c21-5
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c21))
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
  (:action sense-safe-c10-7
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-8
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c20-9
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-safe-c21-10
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
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
  (:action sense-safe-c10-12
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-13
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c20-14
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-safe-c21-15
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
  )
  (:action sense-safe-c00-16
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-17
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c11-18
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c20-19
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-safe-c21-20
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
  )
  (:action sense-safe-c00-21
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-22
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c10-23
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c20-24
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-safe-c21-25
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
  )
  (:action sense-safe-c00-26
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-27
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c10-28
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-29
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c21-30
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
  )
  (:action sense-safe-c00-31
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-32
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c10-33
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-34
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c20-35
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
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
