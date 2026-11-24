(define (domain rocksample-induced-bsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types rock-4 - object rock-1 - object rock-2 - object rock-3 - object)
  (:predicates
    (self-rock-4-r4-good ?x - rock-4)
    (self-rock-4-r4-bad ?x - rock-4)
    (self-rock-1-r1-good ?x - rock-1)
    (self-rock-1-r1-bad ?x - rock-1)
    (self-rock-2-r2-good ?x - rock-2)
    (self-rock-2-r2-bad ?x - rock-2)
    (self-rock-3-r3-good ?x - rock-3)
    (self-rock-3-r3-bad ?x - rock-3)
    (k-rock-4 ?x - rock-4)
    (k-not-rock-4 ?x - rock-4)
    (committed-rock-4)
    (uncertain-rock-4)
    (k-rock-1 ?x - rock-1)
    (k-not-rock-1 ?x - rock-1)
    (committed-rock-1)
    (uncertain-rock-1)
    (k-rock-2 ?x - rock-2)
    (k-not-rock-2 ?x - rock-2)
    (committed-rock-2)
    (uncertain-rock-2)
    (k-rock-3 ?x - rock-3)
    (k-not-rock-3 ?x - rock-3)
    (committed-rock-3)
    (uncertain-rock-3)
    (done)
  )
  (:action sense-sense-bad-0
    :parameters (?x-rock-4-r4-good - rock-4 ?x-rock-4-r4-bad - rock-4)
    :precondition (and
      (self-rock-4-r4-good ?x-rock-4-r4-good)
      (self-rock-4-r4-bad ?x-rock-4-r4-bad)
      (uncertain-rock-4))
    :effect (and
      (not (uncertain-rock-4))
      (k-not-rock-4 ?x-rock-4-r4-good)
      (k-rock-4 ?x-rock-4-r4-bad))
  )
  (:action sense-sense-good-1
    :parameters (?x-rock-4-r4-good - rock-4 ?x-rock-4-r4-bad - rock-4)
    :precondition (and
      (self-rock-4-r4-good ?x-rock-4-r4-good)
      (self-rock-4-r4-bad ?x-rock-4-r4-bad)
      (uncertain-rock-4))
    :effect (and
      (not (uncertain-rock-4))
      (k-rock-4 ?x-rock-4-r4-good)
      (k-not-rock-4 ?x-rock-4-r4-bad))
  )
  (:action sense-sense-bad-2
    :parameters (?x-rock-1-r1-bad - rock-1 ?x-rock-1-r1-good - rock-1)
    :precondition (and
      (self-rock-1-r1-bad ?x-rock-1-r1-bad)
      (self-rock-1-r1-good ?x-rock-1-r1-good)
      (uncertain-rock-1))
    :effect (and
      (not (uncertain-rock-1))
      (k-rock-1 ?x-rock-1-r1-bad)
      (k-not-rock-1 ?x-rock-1-r1-good))
  )
  (:action sense-sense-good-3
    :parameters (?x-rock-1-r1-good - rock-1 ?x-rock-1-r1-bad - rock-1)
    :precondition (and
      (self-rock-1-r1-good ?x-rock-1-r1-good)
      (self-rock-1-r1-bad ?x-rock-1-r1-bad)
      (uncertain-rock-1))
    :effect (and
      (not (uncertain-rock-1))
      (k-rock-1 ?x-rock-1-r1-good)
      (k-not-rock-1 ?x-rock-1-r1-bad))
  )
  (:action sense-sense-bad-4
    :parameters (?x-rock-2-r2-good - rock-2 ?x-rock-2-r2-bad - rock-2)
    :precondition (and
      (self-rock-2-r2-good ?x-rock-2-r2-good)
      (self-rock-2-r2-bad ?x-rock-2-r2-bad)
      (uncertain-rock-2))
    :effect (and
      (not (uncertain-rock-2))
      (k-not-rock-2 ?x-rock-2-r2-good)
      (k-rock-2 ?x-rock-2-r2-bad))
  )
  (:action sense-sense-good-5
    :parameters (?x-rock-2-r2-good - rock-2 ?x-rock-2-r2-bad - rock-2)
    :precondition (and
      (self-rock-2-r2-good ?x-rock-2-r2-good)
      (self-rock-2-r2-bad ?x-rock-2-r2-bad)
      (uncertain-rock-2))
    :effect (and
      (not (uncertain-rock-2))
      (k-rock-2 ?x-rock-2-r2-good)
      (k-not-rock-2 ?x-rock-2-r2-bad))
  )
  (:action sense-sense-bad-6
    :parameters (?x-rock-3-r3-good - rock-3 ?x-rock-3-r3-bad - rock-3)
    :precondition (and
      (self-rock-3-r3-good ?x-rock-3-r3-good)
      (self-rock-3-r3-bad ?x-rock-3-r3-bad)
      (uncertain-rock-3))
    :effect (and
      (not (uncertain-rock-3))
      (k-not-rock-3 ?x-rock-3-r3-good)
      (k-rock-3 ?x-rock-3-r3-bad))
  )
  (:action sense-sense-good-7
    :parameters (?x-rock-3-r3-good - rock-3 ?x-rock-3-r3-bad - rock-3)
    :precondition (and
      (self-rock-3-r3-good ?x-rock-3-r3-good)
      (self-rock-3-r3-bad ?x-rock-3-r3-bad)
      (uncertain-rock-3))
    :effect (and
      (not (uncertain-rock-3))
      (k-rock-3 ?x-rock-3-r3-good)
      (k-not-rock-3 ?x-rock-3-r3-bad))
  )
  (:action commit-rock-4-r4-good-0
    :parameters (?x-rock-4-r4-bad - rock-4 ?x-rock-4-r4-good - rock-4)
    :precondition (and
      (self-rock-4-r4-bad ?x-rock-4-r4-bad)
      (self-rock-4-r4-good ?x-rock-4-r4-good)
      (k-not-rock-4 ?x-rock-4-r4-bad)
      (k-rock-4 ?x-rock-4-r4-good)
      (not (committed-rock-4)))
    :effect (and
      (committed-rock-4))
  )
  (:action commit-rock-4-r4-bad-1
    :parameters (?x-rock-4-r4-good - rock-4 ?x-rock-4-r4-bad - rock-4)
    :precondition (and
      (self-rock-4-r4-good ?x-rock-4-r4-good)
      (self-rock-4-r4-bad ?x-rock-4-r4-bad)
      (k-not-rock-4 ?x-rock-4-r4-good)
      (k-rock-4 ?x-rock-4-r4-bad)
      (not (committed-rock-4)))
    :effect (and
      (committed-rock-4))
  )
  (:action commit-rock-1-r1-good-2
    :parameters (?x-rock-1-r1-bad - rock-1 ?x-rock-1-r1-good - rock-1)
    :precondition (and
      (self-rock-1-r1-bad ?x-rock-1-r1-bad)
      (self-rock-1-r1-good ?x-rock-1-r1-good)
      (k-not-rock-1 ?x-rock-1-r1-bad)
      (k-rock-1 ?x-rock-1-r1-good)
      (not (committed-rock-1)))
    :effect (and
      (committed-rock-1))
  )
  (:action commit-rock-1-r1-bad-3
    :parameters (?x-rock-1-r1-good - rock-1 ?x-rock-1-r1-bad - rock-1)
    :precondition (and
      (self-rock-1-r1-good ?x-rock-1-r1-good)
      (self-rock-1-r1-bad ?x-rock-1-r1-bad)
      (k-not-rock-1 ?x-rock-1-r1-good)
      (k-rock-1 ?x-rock-1-r1-bad)
      (not (committed-rock-1)))
    :effect (and
      (committed-rock-1))
  )
  (:action commit-rock-2-r2-good-4
    :parameters (?x-rock-2-r2-bad - rock-2 ?x-rock-2-r2-good - rock-2)
    :precondition (and
      (self-rock-2-r2-bad ?x-rock-2-r2-bad)
      (self-rock-2-r2-good ?x-rock-2-r2-good)
      (k-not-rock-2 ?x-rock-2-r2-bad)
      (k-rock-2 ?x-rock-2-r2-good)
      (not (committed-rock-2)))
    :effect (and
      (committed-rock-2))
  )
  (:action commit-rock-2-r2-bad-5
    :parameters (?x-rock-2-r2-good - rock-2 ?x-rock-2-r2-bad - rock-2)
    :precondition (and
      (self-rock-2-r2-good ?x-rock-2-r2-good)
      (self-rock-2-r2-bad ?x-rock-2-r2-bad)
      (k-not-rock-2 ?x-rock-2-r2-good)
      (k-rock-2 ?x-rock-2-r2-bad)
      (not (committed-rock-2)))
    :effect (and
      (committed-rock-2))
  )
  (:action commit-rock-3-r3-good-6
    :parameters (?x-rock-3-r3-bad - rock-3 ?x-rock-3-r3-good - rock-3)
    :precondition (and
      (self-rock-3-r3-bad ?x-rock-3-r3-bad)
      (self-rock-3-r3-good ?x-rock-3-r3-good)
      (k-not-rock-3 ?x-rock-3-r3-bad)
      (k-rock-3 ?x-rock-3-r3-good)
      (not (committed-rock-3)))
    :effect (and
      (committed-rock-3))
  )
  (:action commit-rock-3-r3-bad-7
    :parameters (?x-rock-3-r3-good - rock-3 ?x-rock-3-r3-bad - rock-3)
    :precondition (and
      (self-rock-3-r3-good ?x-rock-3-r3-good)
      (self-rock-3-r3-bad ?x-rock-3-r3-bad)
      (k-not-rock-3 ?x-rock-3-r3-good)
      (k-rock-3 ?x-rock-3-r3-bad)
      (not (committed-rock-3)))
    :effect (and
      (committed-rock-3))
  )
  (:action finish
    :parameters ()
    :precondition (and
      (committed-rock-4)
      (committed-rock-1)
      (committed-rock-2)
      (committed-rock-3))
    :effect (and
      (done))
  )
)
