(define (domain mine-3x3-bsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types mine-cell - object)
  (:predicates
    (self-mine-cell-c00 ?x - mine-cell)
    (self-mine-cell-c01 ?x - mine-cell)
    (self-mine-cell-c02 ?x - mine-cell)
    (self-mine-cell-c10 ?x - mine-cell)
    (self-mine-cell-c11 ?x - mine-cell)
    (self-mine-cell-c12 ?x - mine-cell)
    (self-mine-cell-c20 ?x - mine-cell)
    (self-mine-cell-c21 ?x - mine-cell)
    (self-mine-cell-c22 ?x - mine-cell)
    (k-mine-cell ?x - mine-cell)
    (k-not-mine-cell ?x - mine-cell)
    (committed-mine-cell)
    (neg-committed-mine-cell)
    (confirmed-mine-cell)
    (done)
  )
  (:action sense-mine-c00-0
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21))
      (not (k-mine-cell ?x-mine-cell-c22)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-mine-c01-1
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21))
      (not (k-mine-cell ?x-mine-cell-c22)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-mine-c02-2
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21))
      (not (k-mine-cell ?x-mine-cell-c22)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-mine-c10-3
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21))
      (not (k-mine-cell ?x-mine-cell-c22)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-mine-c11-4
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21))
      (not (k-mine-cell ?x-mine-cell-c22)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-mine-c12-5
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21))
      (not (k-mine-cell ?x-mine-cell-c22)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-mine-c20-6
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21))
      (not (k-mine-cell ?x-mine-cell-c22)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-mine-c21-7
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21))
      (not (k-mine-cell ?x-mine-cell-c22)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c21))
  )
  (:action sense-mine-c22-8
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell ?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (not (k-mine-cell ?x-mine-cell-c00))
      (not (k-mine-cell ?x-mine-cell-c01))
      (not (k-mine-cell ?x-mine-cell-c02))
      (not (k-mine-cell ?x-mine-cell-c10))
      (not (k-mine-cell ?x-mine-cell-c11))
      (not (k-mine-cell ?x-mine-cell-c12))
      (not (k-mine-cell ?x-mine-cell-c20))
      (not (k-mine-cell ?x-mine-cell-c21))
      (not (k-mine-cell ?x-mine-cell-c22)))
    :effect (and
      (k-mine-cell ?x-mine-cell-c22))
  )
  (:action sense-safe-c01-9
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-10
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c10-11
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-12
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c12-13
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c20-14
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-safe-c21-15
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
  )
  (:action sense-safe-c22-16
    :parameters (?x-mine-cell-c00 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (k-mine-cell ?x-mine-cell-c00))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c22))
  )
  (:action sense-safe-c00-17
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c02-18
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c10-19
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-20
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c12-21
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c20-22
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-safe-c21-23
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
  )
  (:action sense-safe-c22-24
    :parameters (?x-mine-cell-c01 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (k-mine-cell ?x-mine-cell-c01))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c22))
  )
  (:action sense-safe-c00-25
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-26
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c10-27
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-28
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c12-29
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c20-30
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-safe-c21-31
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
  )
  (:action sense-safe-c22-32
    :parameters (?x-mine-cell-c02 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (k-mine-cell ?x-mine-cell-c02))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c22))
  )
  (:action sense-safe-c00-33
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-34
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-35
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c11-36
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c12-37
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c20-38
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-safe-c21-39
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
  )
  (:action sense-safe-c22-40
    :parameters (?x-mine-cell-c10 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (k-mine-cell ?x-mine-cell-c10))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c22))
  )
  (:action sense-safe-c00-41
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-42
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-43
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c10-44
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c12-45
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c20-46
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-safe-c21-47
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
  )
  (:action sense-safe-c22-48
    :parameters (?x-mine-cell-c11 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (k-mine-cell ?x-mine-cell-c11))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c22))
  )
  (:action sense-safe-c00-49
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-50
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-51
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c10-52
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-53
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c20-54
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-safe-c21-55
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
  )
  (:action sense-safe-c22-56
    :parameters (?x-mine-cell-c12 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (k-mine-cell ?x-mine-cell-c12))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c22))
  )
  (:action sense-safe-c00-57
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-58
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-59
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c10-60
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-61
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c12-62
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c21-63
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
  )
  (:action sense-safe-c22-64
    :parameters (?x-mine-cell-c20 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (k-mine-cell ?x-mine-cell-c20))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c22))
  )
  (:action sense-safe-c00-65
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-66
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-67
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c10-68
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-69
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c12-70
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c20-71
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-safe-c22-72
    :parameters (?x-mine-cell-c21 - mine-cell ?x-mine-cell-c22 - mine-cell)
    :precondition (and
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (k-mine-cell ?x-mine-cell-c21))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c22))
  )
  (:action sense-safe-c00-73
    :parameters (?x-mine-cell-c22 - mine-cell ?x-mine-cell-c00 - mine-cell)
    :precondition (and
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (self-mine-cell-c00 ?x-mine-cell-c00)
      (k-mine-cell ?x-mine-cell-c22))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c00))
  )
  (:action sense-safe-c01-74
    :parameters (?x-mine-cell-c22 - mine-cell ?x-mine-cell-c01 - mine-cell)
    :precondition (and
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (self-mine-cell-c01 ?x-mine-cell-c01)
      (k-mine-cell ?x-mine-cell-c22))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c01))
  )
  (:action sense-safe-c02-75
    :parameters (?x-mine-cell-c22 - mine-cell ?x-mine-cell-c02 - mine-cell)
    :precondition (and
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (self-mine-cell-c02 ?x-mine-cell-c02)
      (k-mine-cell ?x-mine-cell-c22))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c02))
  )
  (:action sense-safe-c10-76
    :parameters (?x-mine-cell-c22 - mine-cell ?x-mine-cell-c10 - mine-cell)
    :precondition (and
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (self-mine-cell-c10 ?x-mine-cell-c10)
      (k-mine-cell ?x-mine-cell-c22))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c10))
  )
  (:action sense-safe-c11-77
    :parameters (?x-mine-cell-c22 - mine-cell ?x-mine-cell-c11 - mine-cell)
    :precondition (and
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (self-mine-cell-c11 ?x-mine-cell-c11)
      (k-mine-cell ?x-mine-cell-c22))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c11))
  )
  (:action sense-safe-c12-78
    :parameters (?x-mine-cell-c22 - mine-cell ?x-mine-cell-c12 - mine-cell)
    :precondition (and
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (self-mine-cell-c12 ?x-mine-cell-c12)
      (k-mine-cell ?x-mine-cell-c22))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c12))
  )
  (:action sense-safe-c20-79
    :parameters (?x-mine-cell-c22 - mine-cell ?x-mine-cell-c20 - mine-cell)
    :precondition (and
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (self-mine-cell-c20 ?x-mine-cell-c20)
      (k-mine-cell ?x-mine-cell-c22))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c20))
  )
  (:action sense-safe-c21-80
    :parameters (?x-mine-cell-c22 - mine-cell ?x-mine-cell-c21 - mine-cell)
    :precondition (and
      (self-mine-cell-c22 ?x-mine-cell-c22)
      (self-mine-cell-c21 ?x-mine-cell-c21)
      (k-mine-cell ?x-mine-cell-c22))
    :effect (and
      (k-not-mine-cell ?x-mine-cell-c21))
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
