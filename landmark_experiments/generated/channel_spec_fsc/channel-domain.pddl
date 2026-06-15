(define (domain channel)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types node - object channel - object)
  (:predicates
    (at ?n - node)
    (commit-node ?n - node)
    (no-write ?from - node ?to - node)
    (k-channel ?x - channel)
    (k-not-channel ?x - channel)
    (committed-channel)
    (neg-committed-channel)
    (confirmed-channel)
    (trans-signal-c1 ?from - node ?to - node)
    (trans-signal-c2 ?from - node ?to - node)
    (trans-signal-c3 ?from - node ?to - node)
    (trans-noise-c1 ?from - node ?to - node)
    (trans-noise-c2 ?from - node ?to - node)
    (trans-noise-c3 ?from - node ?to - node)
    (writes-k-channel ?from - node ?to - node ?x - channel)
    (writes-knot-channel ?from - node ?to - node ?x - channel)
    (done)
  )
  (:action sense-signal-c1-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-signal-c1 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-signal-c1-write-k-channel
    :parameters (?from - node ?to - node ?x - channel)
    :precondition (and
      (at ?from)
      (trans-signal-c1 ?from ?to)
      (writes-k-channel ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-channel ?x))
  )
  (:action sense-signal-c1-write-knot-channel
    :parameters (?from - node ?to - node ?x - channel)
    :precondition (and
      (at ?from)
      (trans-signal-c1 ?from ?to)
      (writes-knot-channel ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-channel ?x))
  )
  (:action sense-signal-c2-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-signal-c2 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-signal-c2-write-k-channel
    :parameters (?from - node ?to - node ?x - channel)
    :precondition (and
      (at ?from)
      (trans-signal-c2 ?from ?to)
      (writes-k-channel ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-channel ?x))
  )
  (:action sense-signal-c2-write-knot-channel
    :parameters (?from - node ?to - node ?x - channel)
    :precondition (and
      (at ?from)
      (trans-signal-c2 ?from ?to)
      (writes-knot-channel ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-channel ?x))
  )
  (:action sense-signal-c3-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-signal-c3 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-signal-c3-write-k-channel
    :parameters (?from - node ?to - node ?x - channel)
    :precondition (and
      (at ?from)
      (trans-signal-c3 ?from ?to)
      (writes-k-channel ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-channel ?x))
  )
  (:action sense-signal-c3-write-knot-channel
    :parameters (?from - node ?to - node ?x - channel)
    :precondition (and
      (at ?from)
      (trans-signal-c3 ?from ?to)
      (writes-knot-channel ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-channel ?x))
  )
  (:action sense-noise-c1-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-noise-c1 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-noise-c1-write-k-channel
    :parameters (?from - node ?to - node ?x - channel)
    :precondition (and
      (at ?from)
      (trans-noise-c1 ?from ?to)
      (writes-k-channel ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-channel ?x))
  )
  (:action sense-noise-c1-write-knot-channel
    :parameters (?from - node ?to - node ?x - channel)
    :precondition (and
      (at ?from)
      (trans-noise-c1 ?from ?to)
      (writes-knot-channel ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-channel ?x))
  )
  (:action sense-noise-c2-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-noise-c2 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-noise-c2-write-k-channel
    :parameters (?from - node ?to - node ?x - channel)
    :precondition (and
      (at ?from)
      (trans-noise-c2 ?from ?to)
      (writes-k-channel ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-channel ?x))
  )
  (:action sense-noise-c2-write-knot-channel
    :parameters (?from - node ?to - node ?x - channel)
    :precondition (and
      (at ?from)
      (trans-noise-c2 ?from ?to)
      (writes-knot-channel ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-channel ?x))
  )
  (:action sense-noise-c3-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-noise-c3 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-noise-c3-write-k-channel
    :parameters (?from - node ?to - node ?x - channel)
    :precondition (and
      (at ?from)
      (trans-noise-c3 ?from ?to)
      (writes-k-channel ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-channel ?x))
  )
  (:action sense-noise-c3-write-knot-channel
    :parameters (?from - node ?to - node ?x - channel)
    :precondition (and
      (at ?from)
      (trans-noise-c3 ?from ?to)
      (writes-knot-channel ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-channel ?x))
  )
  (:action commit-channel
    :parameters (?x - channel ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-channel ?x)
      (not (committed-channel)))
    :effect (and
      (committed-channel))
  )
  (:action neg-commit-channel
    :parameters (?x - channel ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-not-channel ?x)
      (not (neg-committed-channel)))
    :effect (and
      (neg-committed-channel))
  )
  (:action confirm-channel
    :parameters (?x - channel)
    :precondition (and
      (committed-channel)
      (neg-committed-channel)
      (k-channel ?x)
      (not (confirmed-channel)))
    :effect (and
      (confirmed-channel))
  )
  (:action finish
    :parameters ()
    :precondition (and
      (confirmed-channel))
    :effect (and
      (done))
  )
)
