(define (domain sensor-3-spec-fsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types node - object sensor-1 - object sensor-2 - object sensor-3 - object)
  (:predicates
    (at ?n - node)
    (commit-node ?n - node)
    (no-write ?from - node ?to - node)
    (k-sensor-1 ?x - sensor-1)
    (k-not-sensor-1 ?x - sensor-1)
    (committed-sensor-1)
    (neg-committed-sensor-1)
    (confirmed-sensor-1)
    (k-sensor-2 ?x - sensor-2)
    (k-not-sensor-2 ?x - sensor-2)
    (committed-sensor-2)
    (neg-committed-sensor-2)
    (confirmed-sensor-2)
    (k-sensor-3 ?x - sensor-3)
    (k-not-sensor-3 ?x - sensor-3)
    (committed-sensor-3)
    (neg-committed-sensor-3)
    (confirmed-sensor-3)
    (trans-1-agree ?from - node ?to - node)
    (trans-1-disagree ?from - node ?to - node)
    (trans-2-agree ?from - node ?to - node)
    (trans-2-disagree ?from - node ?to - node)
    (trans-3-agree ?from - node ?to - node)
    (trans-3-disagree ?from - node ?to - node)
    (writes-k-sensor-1 ?from - node ?to - node ?x - sensor-1)
    (writes-knot-sensor-1 ?from - node ?to - node ?x - sensor-1)
    (writes-k-sensor-2 ?from - node ?to - node ?x - sensor-2)
    (writes-knot-sensor-2 ?from - node ?to - node ?x - sensor-2)
    (writes-k-sensor-3 ?from - node ?to - node ?x - sensor-3)
    (writes-knot-sensor-3 ?from - node ?to - node ?x - sensor-3)
    (done)
  )
  (:action sense-1-agree-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-1-agree ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-1-agree-write-k-sensor-1
    :parameters (?from - node ?to - node ?x - sensor-1)
    :precondition (and
      (at ?from)
      (trans-1-agree ?from ?to)
      (writes-k-sensor-1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-1 ?x))
  )
  (:action sense-1-agree-write-knot-sensor-1
    :parameters (?from - node ?to - node ?x - sensor-1)
    :precondition (and
      (at ?from)
      (trans-1-agree ?from ?to)
      (writes-knot-sensor-1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-1 ?x))
  )
  (:action sense-1-agree-write-k-sensor-2
    :parameters (?from - node ?to - node ?x - sensor-2)
    :precondition (and
      (at ?from)
      (trans-1-agree ?from ?to)
      (writes-k-sensor-2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-2 ?x))
  )
  (:action sense-1-agree-write-knot-sensor-2
    :parameters (?from - node ?to - node ?x - sensor-2)
    :precondition (and
      (at ?from)
      (trans-1-agree ?from ?to)
      (writes-knot-sensor-2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-2 ?x))
  )
  (:action sense-1-agree-write-k-sensor-3
    :parameters (?from - node ?to - node ?x - sensor-3)
    :precondition (and
      (at ?from)
      (trans-1-agree ?from ?to)
      (writes-k-sensor-3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-3 ?x))
  )
  (:action sense-1-agree-write-knot-sensor-3
    :parameters (?from - node ?to - node ?x - sensor-3)
    :precondition (and
      (at ?from)
      (trans-1-agree ?from ?to)
      (writes-knot-sensor-3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-3 ?x))
  )
  (:action sense-1-disagree-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-1-disagree ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-1-disagree-write-k-sensor-1
    :parameters (?from - node ?to - node ?x - sensor-1)
    :precondition (and
      (at ?from)
      (trans-1-disagree ?from ?to)
      (writes-k-sensor-1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-1 ?x))
  )
  (:action sense-1-disagree-write-knot-sensor-1
    :parameters (?from - node ?to - node ?x - sensor-1)
    :precondition (and
      (at ?from)
      (trans-1-disagree ?from ?to)
      (writes-knot-sensor-1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-1 ?x))
  )
  (:action sense-1-disagree-write-k-sensor-2
    :parameters (?from - node ?to - node ?x - sensor-2)
    :precondition (and
      (at ?from)
      (trans-1-disagree ?from ?to)
      (writes-k-sensor-2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-2 ?x))
  )
  (:action sense-1-disagree-write-knot-sensor-2
    :parameters (?from - node ?to - node ?x - sensor-2)
    :precondition (and
      (at ?from)
      (trans-1-disagree ?from ?to)
      (writes-knot-sensor-2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-2 ?x))
  )
  (:action sense-1-disagree-write-k-sensor-3
    :parameters (?from - node ?to - node ?x - sensor-3)
    :precondition (and
      (at ?from)
      (trans-1-disagree ?from ?to)
      (writes-k-sensor-3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-3 ?x))
  )
  (:action sense-1-disagree-write-knot-sensor-3
    :parameters (?from - node ?to - node ?x - sensor-3)
    :precondition (and
      (at ?from)
      (trans-1-disagree ?from ?to)
      (writes-knot-sensor-3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-3 ?x))
  )
  (:action sense-2-agree-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-2-agree ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-2-agree-write-k-sensor-1
    :parameters (?from - node ?to - node ?x - sensor-1)
    :precondition (and
      (at ?from)
      (trans-2-agree ?from ?to)
      (writes-k-sensor-1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-1 ?x))
  )
  (:action sense-2-agree-write-knot-sensor-1
    :parameters (?from - node ?to - node ?x - sensor-1)
    :precondition (and
      (at ?from)
      (trans-2-agree ?from ?to)
      (writes-knot-sensor-1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-1 ?x))
  )
  (:action sense-2-agree-write-k-sensor-2
    :parameters (?from - node ?to - node ?x - sensor-2)
    :precondition (and
      (at ?from)
      (trans-2-agree ?from ?to)
      (writes-k-sensor-2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-2 ?x))
  )
  (:action sense-2-agree-write-knot-sensor-2
    :parameters (?from - node ?to - node ?x - sensor-2)
    :precondition (and
      (at ?from)
      (trans-2-agree ?from ?to)
      (writes-knot-sensor-2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-2 ?x))
  )
  (:action sense-2-agree-write-k-sensor-3
    :parameters (?from - node ?to - node ?x - sensor-3)
    :precondition (and
      (at ?from)
      (trans-2-agree ?from ?to)
      (writes-k-sensor-3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-3 ?x))
  )
  (:action sense-2-agree-write-knot-sensor-3
    :parameters (?from - node ?to - node ?x - sensor-3)
    :precondition (and
      (at ?from)
      (trans-2-agree ?from ?to)
      (writes-knot-sensor-3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-3 ?x))
  )
  (:action sense-2-disagree-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-2-disagree ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-2-disagree-write-k-sensor-1
    :parameters (?from - node ?to - node ?x - sensor-1)
    :precondition (and
      (at ?from)
      (trans-2-disagree ?from ?to)
      (writes-k-sensor-1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-1 ?x))
  )
  (:action sense-2-disagree-write-knot-sensor-1
    :parameters (?from - node ?to - node ?x - sensor-1)
    :precondition (and
      (at ?from)
      (trans-2-disagree ?from ?to)
      (writes-knot-sensor-1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-1 ?x))
  )
  (:action sense-2-disagree-write-k-sensor-2
    :parameters (?from - node ?to - node ?x - sensor-2)
    :precondition (and
      (at ?from)
      (trans-2-disagree ?from ?to)
      (writes-k-sensor-2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-2 ?x))
  )
  (:action sense-2-disagree-write-knot-sensor-2
    :parameters (?from - node ?to - node ?x - sensor-2)
    :precondition (and
      (at ?from)
      (trans-2-disagree ?from ?to)
      (writes-knot-sensor-2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-2 ?x))
  )
  (:action sense-2-disagree-write-k-sensor-3
    :parameters (?from - node ?to - node ?x - sensor-3)
    :precondition (and
      (at ?from)
      (trans-2-disagree ?from ?to)
      (writes-k-sensor-3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-3 ?x))
  )
  (:action sense-2-disagree-write-knot-sensor-3
    :parameters (?from - node ?to - node ?x - sensor-3)
    :precondition (and
      (at ?from)
      (trans-2-disagree ?from ?to)
      (writes-knot-sensor-3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-3 ?x))
  )
  (:action sense-3-agree-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-3-agree ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-3-agree-write-k-sensor-1
    :parameters (?from - node ?to - node ?x - sensor-1)
    :precondition (and
      (at ?from)
      (trans-3-agree ?from ?to)
      (writes-k-sensor-1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-1 ?x))
  )
  (:action sense-3-agree-write-knot-sensor-1
    :parameters (?from - node ?to - node ?x - sensor-1)
    :precondition (and
      (at ?from)
      (trans-3-agree ?from ?to)
      (writes-knot-sensor-1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-1 ?x))
  )
  (:action sense-3-agree-write-k-sensor-2
    :parameters (?from - node ?to - node ?x - sensor-2)
    :precondition (and
      (at ?from)
      (trans-3-agree ?from ?to)
      (writes-k-sensor-2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-2 ?x))
  )
  (:action sense-3-agree-write-knot-sensor-2
    :parameters (?from - node ?to - node ?x - sensor-2)
    :precondition (and
      (at ?from)
      (trans-3-agree ?from ?to)
      (writes-knot-sensor-2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-2 ?x))
  )
  (:action sense-3-agree-write-k-sensor-3
    :parameters (?from - node ?to - node ?x - sensor-3)
    :precondition (and
      (at ?from)
      (trans-3-agree ?from ?to)
      (writes-k-sensor-3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-3 ?x))
  )
  (:action sense-3-agree-write-knot-sensor-3
    :parameters (?from - node ?to - node ?x - sensor-3)
    :precondition (and
      (at ?from)
      (trans-3-agree ?from ?to)
      (writes-knot-sensor-3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-3 ?x))
  )
  (:action sense-3-disagree-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-3-disagree ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-3-disagree-write-k-sensor-1
    :parameters (?from - node ?to - node ?x - sensor-1)
    :precondition (and
      (at ?from)
      (trans-3-disagree ?from ?to)
      (writes-k-sensor-1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-1 ?x))
  )
  (:action sense-3-disagree-write-knot-sensor-1
    :parameters (?from - node ?to - node ?x - sensor-1)
    :precondition (and
      (at ?from)
      (trans-3-disagree ?from ?to)
      (writes-knot-sensor-1 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-1 ?x))
  )
  (:action sense-3-disagree-write-k-sensor-2
    :parameters (?from - node ?to - node ?x - sensor-2)
    :precondition (and
      (at ?from)
      (trans-3-disagree ?from ?to)
      (writes-k-sensor-2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-2 ?x))
  )
  (:action sense-3-disagree-write-knot-sensor-2
    :parameters (?from - node ?to - node ?x - sensor-2)
    :precondition (and
      (at ?from)
      (trans-3-disagree ?from ?to)
      (writes-knot-sensor-2 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-2 ?x))
  )
  (:action sense-3-disagree-write-k-sensor-3
    :parameters (?from - node ?to - node ?x - sensor-3)
    :precondition (and
      (at ?from)
      (trans-3-disagree ?from ?to)
      (writes-k-sensor-3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-3 ?x))
  )
  (:action sense-3-disagree-write-knot-sensor-3
    :parameters (?from - node ?to - node ?x - sensor-3)
    :precondition (and
      (at ?from)
      (trans-3-disagree ?from ?to)
      (writes-knot-sensor-3 ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-3 ?x))
  )
  (:action commit-sensor-1
    :parameters (?x - sensor-1 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-sensor-1 ?x)
      (not (committed-sensor-1)))
    :effect (and
      (committed-sensor-1))
  )
  (:action commit-sensor-2
    :parameters (?x - sensor-2 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-sensor-2 ?x)
      (not (committed-sensor-2)))
    :effect (and
      (committed-sensor-2))
  )
  (:action commit-sensor-3
    :parameters (?x - sensor-3 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-sensor-3 ?x)
      (not (committed-sensor-3)))
    :effect (and
      (committed-sensor-3))
  )
  (:action neg-commit-sensor-1
    :parameters (?x - sensor-1 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-not-sensor-1 ?x)
      (not (neg-committed-sensor-1)))
    :effect (and
      (neg-committed-sensor-1))
  )
  (:action neg-commit-sensor-2
    :parameters (?x - sensor-2 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-not-sensor-2 ?x)
      (not (neg-committed-sensor-2)))
    :effect (and
      (neg-committed-sensor-2))
  )
  (:action neg-commit-sensor-3
    :parameters (?x - sensor-3 ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-not-sensor-3 ?x)
      (not (neg-committed-sensor-3)))
    :effect (and
      (neg-committed-sensor-3))
  )
  (:action confirm-sensor-1
    :parameters (?x - sensor-1)
    :precondition (and
      (committed-sensor-1)
      (neg-committed-sensor-1)
      (k-sensor-1 ?x)
      (not (confirmed-sensor-1)))
    :effect (and
      (confirmed-sensor-1))
  )
  (:action confirm-sensor-2
    :parameters (?x - sensor-2)
    :precondition (and
      (committed-sensor-2)
      (neg-committed-sensor-2)
      (k-sensor-2 ?x)
      (not (confirmed-sensor-2)))
    :effect (and
      (confirmed-sensor-2))
  )
  (:action confirm-sensor-3
    :parameters (?x - sensor-3)
    :precondition (and
      (committed-sensor-3)
      (neg-committed-sensor-3)
      (k-sensor-3 ?x)
      (not (confirmed-sensor-3)))
    :effect (and
      (confirmed-sensor-3))
  )
  (:action finish
    :parameters ()
    :precondition (and
      (confirmed-sensor-1)
      (confirmed-sensor-2)
      (confirmed-sensor-3))
    :effect (and
      (done))
  )
)
