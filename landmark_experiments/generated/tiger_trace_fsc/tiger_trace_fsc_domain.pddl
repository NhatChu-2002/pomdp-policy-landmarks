(define (domain tiger-trace-fsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types node - object direction - object)
  (:predicates
    (at ?n - node)
    (commit-node ?n - node)
    (no-write ?from - node ?to - node)
    (k-direction ?x - direction)
    (k-not-direction ?x - direction)
    (committed-direction)
    (neg-committed-direction)
    (confirmed-direction)
    (trans-left ?from - node ?to - node)
    (trans-right ?from - node ?to - node)
    (writes-k-direction ?from - node ?to - node ?x - direction)
    (writes-knot-direction ?from - node ?to - node ?x - direction)
    (done)
  )
  (:action sense-left-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-left ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-left-write-k-direction
    :parameters (?from - node ?to - node ?x - direction)
    :precondition (and
      (at ?from)
      (trans-left ?from ?to)
      (writes-k-direction ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-direction ?x))
  )
  (:action sense-left-write-knot-direction
    :parameters (?from - node ?to - node ?x - direction)
    :precondition (and
      (at ?from)
      (trans-left ?from ?to)
      (writes-knot-direction ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-direction ?x))
  )
  (:action sense-right-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-right ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-right-write-k-direction
    :parameters (?from - node ?to - node ?x - direction)
    :precondition (and
      (at ?from)
      (trans-right ?from ?to)
      (writes-k-direction ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-direction ?x))
  )
  (:action sense-right-write-knot-direction
    :parameters (?from - node ?to - node ?x - direction)
    :precondition (and
      (at ?from)
      (trans-right ?from ?to)
      (writes-knot-direction ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-direction ?x))
  )
  (:action commit-direction
    :parameters (?x - direction ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-direction ?x)
      (not (committed-direction)))
    :effect (and
      (committed-direction))
  )
  (:action neg-commit-direction
    :parameters (?x - direction ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-not-direction ?x)
      (not (neg-committed-direction)))
    :effect (and
      (neg-committed-direction))
  )
  (:action confirm-direction
    :parameters (?x - direction)
    :precondition (and
      (committed-direction)
      (neg-committed-direction)
      (k-direction ?x)
      (not (confirmed-direction)))
    :effect (and
      (confirmed-direction))
  )
  (:action finish
    :parameters ()
    :precondition (and
      (confirmed-direction))
    :effect (and
      (done))
  )
)
