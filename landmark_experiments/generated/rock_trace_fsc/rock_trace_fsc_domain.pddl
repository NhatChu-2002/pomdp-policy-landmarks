(define (domain rock-trace-fsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types node - object quality-r1 - object quality-r2 - object quality-r3 - object quality-r4 - object)
  (:predicates
    (at ?n - node)
    (commit-node ?n - node)
    (no-write ?from - node ?to - node)
    (k-quality-r1 ?x - quality-r1)
    (k-not-quality-r1 ?x - quality-r1)
    (committed-quality-r1)
    (neg-committed-quality-r1)
    (confirmed-quality-r1)
    (k-quality-r2 ?x - quality-r2)
    (k-not-quality-r2 ?x - quality-r2)
    (committed-quality-r2)
    (neg-committed-quality-r2)
    (confirmed-quality-r2)
    (k-quality-r3 ?x - quality-r3)
    (k-not-quality-r3 ?x - quality-r3)
    (committed-quality-r3)
    (neg-committed-quality-r3)
    (confirmed-quality-r3)
    (k-quality-r4 ?x - quality-r4)
    (k-not-quality-r4 ?x - quality-r4)
    (committed-quality-r4)
    (neg-committed-quality-r4)
    (confirmed-quality-r4)
    (trans-good ?from - node ?to - node)
    (trans-bad ?from - node ?to - node)
    (writes-k-quality-r1 ?from - node ?to - node ?x - quality-r1)
    (writes-knot-quality-r1 ?from - node ?to - node ?x - quality-r1)
    (writes-k-quality-r2 ?from - node ?to - node ?x - quality-r2)
    (writes-knot-quality-r2 ?from - node ?to - node ?x - quality-r2)
    (writes-k-quality-r3 ?from - node ?to - node ?x - quality-r3)
    (writes-knot-quality-r3 ?from - node ?to - node ?x - quality-r3)
    (writes-k-quality-r4 ?from - node ?to - node ?x - quality-r4)
    (writes-knot-quality-r4 ?from - node ?to - node ?x - quality-r4)
    (done)
  )
  (:action sense-good-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-good ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-good-write-k-quality-r1
    :parameters (?from - node ?to - node ?x - quality-r1)
    :precondition (and
      (at ?from)
      (trans-good ?from ?to)
      (writes-k-quality-r1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-quality-r1 ?x))
  )
  (:action sense-good-write-knot-quality-r1
    :parameters (?from - node ?to - node ?x - quality-r1)
    :precondition (and
      (at ?from)
      (trans-good ?from ?to)
      (writes-knot-quality-r1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-quality-r1 ?x))
  )
  (:action sense-good-write-k-quality-r2
    :parameters (?from - node ?to - node ?x - quality-r2)
    :precondition (and
      (at ?from)
      (trans-good ?from ?to)
      (writes-k-quality-r2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-quality-r2 ?x))
  )
  (:action sense-good-write-knot-quality-r2
    :parameters (?from - node ?to - node ?x - quality-r2)
    :precondition (and
      (at ?from)
      (trans-good ?from ?to)
      (writes-knot-quality-r2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-quality-r2 ?x))
  )
  (:action sense-good-write-k-quality-r3
    :parameters (?from - node ?to - node ?x - quality-r3)
    :precondition (and
      (at ?from)
      (trans-good ?from ?to)
      (writes-k-quality-r3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-quality-r3 ?x))
  )
  (:action sense-good-write-knot-quality-r3
    :parameters (?from - node ?to - node ?x - quality-r3)
    :precondition (and
      (at ?from)
      (trans-good ?from ?to)
      (writes-knot-quality-r3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-quality-r3 ?x))
  )
  (:action sense-good-write-k-quality-r4
    :parameters (?from - node ?to - node ?x - quality-r4)
    :precondition (and
      (at ?from)
      (trans-good ?from ?to)
      (writes-k-quality-r4 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-quality-r4 ?x))
  )
  (:action sense-good-write-knot-quality-r4
    :parameters (?from - node ?to - node ?x - quality-r4)
    :precondition (and
      (at ?from)
      (trans-good ?from ?to)
      (writes-knot-quality-r4 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-quality-r4 ?x))
  )
  (:action sense-bad-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-bad ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-bad-write-k-quality-r1
    :parameters (?from - node ?to - node ?x - quality-r1)
    :precondition (and
      (at ?from)
      (trans-bad ?from ?to)
      (writes-k-quality-r1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-quality-r1 ?x))
  )
  (:action sense-bad-write-knot-quality-r1
    :parameters (?from - node ?to - node ?x - quality-r1)
    :precondition (and
      (at ?from)
      (trans-bad ?from ?to)
      (writes-knot-quality-r1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-quality-r1 ?x))
  )
  (:action sense-bad-write-k-quality-r2
    :parameters (?from - node ?to - node ?x - quality-r2)
    :precondition (and
      (at ?from)
      (trans-bad ?from ?to)
      (writes-k-quality-r2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-quality-r2 ?x))
  )
  (:action sense-bad-write-knot-quality-r2
    :parameters (?from - node ?to - node ?x - quality-r2)
    :precondition (and
      (at ?from)
      (trans-bad ?from ?to)
      (writes-knot-quality-r2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-quality-r2 ?x))
  )
  (:action sense-bad-write-k-quality-r3
    :parameters (?from - node ?to - node ?x - quality-r3)
    :precondition (and
      (at ?from)
      (trans-bad ?from ?to)
      (writes-k-quality-r3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-quality-r3 ?x))
  )
  (:action sense-bad-write-knot-quality-r3
    :parameters (?from - node ?to - node ?x - quality-r3)
    :precondition (and
      (at ?from)
      (trans-bad ?from ?to)
      (writes-knot-quality-r3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-quality-r3 ?x))
  )
  (:action sense-bad-write-k-quality-r4
    :parameters (?from - node ?to - node ?x - quality-r4)
    :precondition (and
      (at ?from)
      (trans-bad ?from ?to)
      (writes-k-quality-r4 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-quality-r4 ?x))
  )
  (:action sense-bad-write-knot-quality-r4
    :parameters (?from - node ?to - node ?x - quality-r4)
    :precondition (and
      (at ?from)
      (trans-bad ?from ?to)
      (writes-knot-quality-r4 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-quality-r4 ?x))
  )
  (:action commit-quality-r1
    :parameters (?x - quality-r1 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-quality-r1 ?x)
      (not (committed-quality-r1)))
    :effect (and
      (committed-quality-r1))
  )
  (:action commit-quality-r2
    :parameters (?x - quality-r2 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-quality-r2 ?x)
      (not (committed-quality-r2)))
    :effect (and
      (committed-quality-r2))
  )
  (:action commit-quality-r3
    :parameters (?x - quality-r3 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-quality-r3 ?x)
      (not (committed-quality-r3)))
    :effect (and
      (committed-quality-r3))
  )
  (:action commit-quality-r4
    :parameters (?x - quality-r4 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-quality-r4 ?x)
      (not (committed-quality-r4)))
    :effect (and
      (committed-quality-r4))
  )
  (:action neg-commit-quality-r1
    :parameters (?x - quality-r1 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-not-quality-r1 ?x)
      (not (neg-committed-quality-r1)))
    :effect (and
      (neg-committed-quality-r1))
  )
  (:action neg-commit-quality-r2
    :parameters (?x - quality-r2 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-not-quality-r2 ?x)
      (not (neg-committed-quality-r2)))
    :effect (and
      (neg-committed-quality-r2))
  )
  (:action neg-commit-quality-r3
    :parameters (?x - quality-r3 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-not-quality-r3 ?x)
      (not (neg-committed-quality-r3)))
    :effect (and
      (neg-committed-quality-r3))
  )
  (:action neg-commit-quality-r4
    :parameters (?x - quality-r4 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-not-quality-r4 ?x)
      (not (neg-committed-quality-r4)))
    :effect (and
      (neg-committed-quality-r4))
  )
  (:action confirm-quality-r1
    :parameters (?x - quality-r1)
    :precondition (and
      (committed-quality-r1)
      (neg-committed-quality-r1)
      (k-quality-r1 ?x)
      (not (confirmed-quality-r1)))
    :effect (and
      (confirmed-quality-r1))
  )
  (:action confirm-quality-r2
    :parameters (?x - quality-r2)
    :precondition (and
      (committed-quality-r2)
      (neg-committed-quality-r2)
      (k-quality-r2 ?x)
      (not (confirmed-quality-r2)))
    :effect (and
      (confirmed-quality-r2))
  )
  (:action confirm-quality-r3
    :parameters (?x - quality-r3)
    :precondition (and
      (committed-quality-r3)
      (neg-committed-quality-r3)
      (k-quality-r3 ?x)
      (not (confirmed-quality-r3)))
    :effect (and
      (confirmed-quality-r3))
  )
  (:action confirm-quality-r4
    :parameters (?x - quality-r4)
    :precondition (and
      (committed-quality-r4)
      (neg-committed-quality-r4)
      (k-quality-r4 ?x)
      (not (confirmed-quality-r4)))
    :effect (and
      (confirmed-quality-r4))
  )
  (:action finish
    :parameters ()
    :precondition (and
      (confirmed-quality-r1)
      (confirmed-quality-r2)
      (confirmed-quality-r3)
      (confirmed-quality-r4))
    :effect (and
      (done))
  )
)
