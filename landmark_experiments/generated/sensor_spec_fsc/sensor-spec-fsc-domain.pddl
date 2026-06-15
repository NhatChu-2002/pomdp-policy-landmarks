(define (domain sensor-spec-fsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types node - object sensor-a - object sensor-b - object)
  (:predicates
    (at ?n - node)
    (commit-node ?n - node)
    (no-write ?from - node ?to - node)
    (k-sensor-a ?x - sensor-a)
    (k-not-sensor-a ?x - sensor-a)
    (committed-sensor-a)
    (neg-committed-sensor-a)
    (confirmed-sensor-a)
    (k-sensor-b ?x - sensor-b)
    (k-not-sensor-b ?x - sensor-b)
    (committed-sensor-b)
    (neg-committed-sensor-b)
    (confirmed-sensor-b)
    (trans-a-agree ?from - node ?to - node)
    (trans-a-disagree ?from - node ?to - node)
    (trans-b-agree ?from - node ?to - node)
    (trans-b-disagree ?from - node ?to - node)
    (writes-k-sensor-a ?from - node ?to - node ?x - sensor-a)
    (writes-knot-sensor-a ?from - node ?to - node ?x - sensor-a)
    (writes-k-sensor-b ?from - node ?to - node ?x - sensor-b)
    (writes-knot-sensor-b ?from - node ?to - node ?x - sensor-b)
    (done)
  )
  (:action sense-a-agree-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-a-agree ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-a-agree-write-k-sensor-a
    :parameters (?from - node ?to - node ?x - sensor-a)
    :precondition (and
      (at ?from)
      (trans-a-agree ?from ?to)
      (writes-k-sensor-a ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-a ?x))
  )
  (:action sense-a-agree-write-knot-sensor-a
    :parameters (?from - node ?to - node ?x - sensor-a)
    :precondition (and
      (at ?from)
      (trans-a-agree ?from ?to)
      (writes-knot-sensor-a ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-a ?x))
  )
  (:action sense-a-agree-write-k-sensor-b
    :parameters (?from - node ?to - node ?x - sensor-b)
    :precondition (and
      (at ?from)
      (trans-a-agree ?from ?to)
      (writes-k-sensor-b ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-b ?x))
  )
  (:action sense-a-agree-write-knot-sensor-b
    :parameters (?from - node ?to - node ?x - sensor-b)
    :precondition (and
      (at ?from)
      (trans-a-agree ?from ?to)
      (writes-knot-sensor-b ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-b ?x))
  )
  (:action sense-a-disagree-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-a-disagree ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-a-disagree-write-k-sensor-a
    :parameters (?from - node ?to - node ?x - sensor-a)
    :precondition (and
      (at ?from)
      (trans-a-disagree ?from ?to)
      (writes-k-sensor-a ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-a ?x))
  )
  (:action sense-a-disagree-write-knot-sensor-a
    :parameters (?from - node ?to - node ?x - sensor-a)
    :precondition (and
      (at ?from)
      (trans-a-disagree ?from ?to)
      (writes-knot-sensor-a ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-a ?x))
  )
  (:action sense-a-disagree-write-k-sensor-b
    :parameters (?from - node ?to - node ?x - sensor-b)
    :precondition (and
      (at ?from)
      (trans-a-disagree ?from ?to)
      (writes-k-sensor-b ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-b ?x))
  )
  (:action sense-a-disagree-write-knot-sensor-b
    :parameters (?from - node ?to - node ?x - sensor-b)
    :precondition (and
      (at ?from)
      (trans-a-disagree ?from ?to)
      (writes-knot-sensor-b ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-b ?x))
  )
  (:action sense-b-agree-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-b-agree ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-b-agree-write-k-sensor-a
    :parameters (?from - node ?to - node ?x - sensor-a)
    :precondition (and
      (at ?from)
      (trans-b-agree ?from ?to)
      (writes-k-sensor-a ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-a ?x))
  )
  (:action sense-b-agree-write-knot-sensor-a
    :parameters (?from - node ?to - node ?x - sensor-a)
    :precondition (and
      (at ?from)
      (trans-b-agree ?from ?to)
      (writes-knot-sensor-a ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-a ?x))
  )
  (:action sense-b-agree-write-k-sensor-b
    :parameters (?from - node ?to - node ?x - sensor-b)
    :precondition (and
      (at ?from)
      (trans-b-agree ?from ?to)
      (writes-k-sensor-b ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-b ?x))
  )
  (:action sense-b-agree-write-knot-sensor-b
    :parameters (?from - node ?to - node ?x - sensor-b)
    :precondition (and
      (at ?from)
      (trans-b-agree ?from ?to)
      (writes-knot-sensor-b ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-b ?x))
  )
  (:action sense-b-disagree-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-b-disagree ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-b-disagree-write-k-sensor-a
    :parameters (?from - node ?to - node ?x - sensor-a)
    :precondition (and
      (at ?from)
      (trans-b-disagree ?from ?to)
      (writes-k-sensor-a ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-a ?x))
  )
  (:action sense-b-disagree-write-knot-sensor-a
    :parameters (?from - node ?to - node ?x - sensor-a)
    :precondition (and
      (at ?from)
      (trans-b-disagree ?from ?to)
      (writes-knot-sensor-a ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-a ?x))
  )
  (:action sense-b-disagree-write-k-sensor-b
    :parameters (?from - node ?to - node ?x - sensor-b)
    :precondition (and
      (at ?from)
      (trans-b-disagree ?from ?to)
      (writes-k-sensor-b ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-sensor-b ?x))
  )
  (:action sense-b-disagree-write-knot-sensor-b
    :parameters (?from - node ?to - node ?x - sensor-b)
    :precondition (and
      (at ?from)
      (trans-b-disagree ?from ?to)
      (writes-knot-sensor-b ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-sensor-b ?x))
  )
  (:action commit-sensor-a
    :parameters (?x - sensor-a ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-sensor-a ?x)
      (not (committed-sensor-a)))
    :effect (and
      (committed-sensor-a))
  )
  (:action commit-sensor-b
    :parameters (?x - sensor-b ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-sensor-b ?x)
      (not (committed-sensor-b)))
    :effect (and
      (committed-sensor-b))
  )
  (:action neg-commit-sensor-a
    :parameters (?x - sensor-a ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-not-sensor-a ?x)
      (not (neg-committed-sensor-a)))
    :effect (and
      (neg-committed-sensor-a))
  )
  (:action neg-commit-sensor-b
    :parameters (?x - sensor-b ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-not-sensor-b ?x)
      (not (neg-committed-sensor-b)))
    :effect (and
      (neg-committed-sensor-b))
  )
  (:action confirm-sensor-a
    :parameters (?x - sensor-a)
    :precondition (and
      (committed-sensor-a)
      (neg-committed-sensor-a)
      (k-sensor-a ?x)
      (not (confirmed-sensor-a)))
    :effect (and
      (confirmed-sensor-a))
  )
  (:action confirm-sensor-b
    :parameters (?x - sensor-b)
    :precondition (and
      (committed-sensor-b)
      (neg-committed-sensor-b)
      (k-sensor-b ?x)
      (not (confirmed-sensor-b)))
    :effect (and
      (confirmed-sensor-b))
  )
  (:action finish
    :parameters ()
    :precondition (and
      (confirmed-sensor-a)
      (confirmed-sensor-b))
    :effect (and
      (done))
  )
)
