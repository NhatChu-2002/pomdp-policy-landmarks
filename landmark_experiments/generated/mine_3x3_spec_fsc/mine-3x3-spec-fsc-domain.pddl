(define (domain mine-3x3-spec-fsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types node - object mine-cell - object)
  (:predicates
    (at ?n - node)
    (commit-node ?n - node)
    (no-write ?from - node ?to - node)
    (k-mine-cell ?x - mine-cell)
    (k-not-mine-cell ?x - mine-cell)
    (committed-mine-cell)
    (neg-committed-mine-cell)
    (confirmed-mine-cell)
    (trans-mine-c00 ?from - node ?to - node)
    (trans-mine-c01 ?from - node ?to - node)
    (trans-mine-c02 ?from - node ?to - node)
    (trans-mine-c10 ?from - node ?to - node)
    (trans-mine-c11 ?from - node ?to - node)
    (trans-mine-c12 ?from - node ?to - node)
    (trans-mine-c20 ?from - node ?to - node)
    (trans-mine-c21 ?from - node ?to - node)
    (trans-mine-c22 ?from - node ?to - node)
    (trans-safe-c00 ?from - node ?to - node)
    (trans-safe-c01 ?from - node ?to - node)
    (trans-safe-c02 ?from - node ?to - node)
    (trans-safe-c10 ?from - node ?to - node)
    (trans-safe-c11 ?from - node ?to - node)
    (trans-safe-c12 ?from - node ?to - node)
    (trans-safe-c20 ?from - node ?to - node)
    (trans-safe-c21 ?from - node ?to - node)
    (trans-safe-c22 ?from - node ?to - node)
    (writes-k-mine-cell ?from - node ?to - node ?x - mine-cell)
    (writes-knot-mine-cell ?from - node ?to - node ?x - mine-cell)
    (done)
  )
  (:action sense-mine-c00-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-mine-c00 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-mine-c00-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c00 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-mine-c00-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c00 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-mine-c01-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-mine-c01 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-mine-c01-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c01 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-mine-c01-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c01 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-mine-c02-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-mine-c02 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-mine-c02-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c02 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-mine-c02-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c02 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-mine-c10-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-mine-c10 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-mine-c10-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c10 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-mine-c10-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c10 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-mine-c11-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-mine-c11 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-mine-c11-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c11 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-mine-c11-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c11 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-mine-c12-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-mine-c12 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-mine-c12-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c12 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-mine-c12-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c12 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-mine-c20-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-mine-c20 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-mine-c20-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c20 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-mine-c20-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c20 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-mine-c21-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-mine-c21 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-mine-c21-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c21 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-mine-c21-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c21 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-mine-c22-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-mine-c22 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-mine-c22-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c22 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-mine-c22-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-mine-c22 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-safe-c00-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-safe-c00 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-safe-c00-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c00 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-safe-c00-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c00 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-safe-c01-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-safe-c01 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-safe-c01-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c01 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-safe-c01-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c01 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-safe-c02-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-safe-c02 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-safe-c02-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c02 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-safe-c02-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c02 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-safe-c10-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-safe-c10 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-safe-c10-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c10 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-safe-c10-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c10 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-safe-c11-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-safe-c11 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-safe-c11-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c11 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-safe-c11-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c11 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-safe-c12-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-safe-c12 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-safe-c12-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c12 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-safe-c12-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c12 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-safe-c20-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-safe-c20 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-safe-c20-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c20 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-safe-c20-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c20 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-safe-c21-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-safe-c21 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-safe-c21-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c21 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-safe-c21-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c21 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action sense-safe-c22-move
    :parameters (?from - node ?to - node)
    :precondition (and
      (at ?from)
      (trans-safe-c22 ?from ?to)
      (no-write ?from ?to))
    :effect (and
      (not (at ?from))
      (at ?to))
  )
  (:action sense-safe-c22-write-k-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c22 ?from ?to)
      (writes-k-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-mine-cell ?x))
  )
  (:action sense-safe-c22-write-knot-mine-cell
    :parameters (?from - node ?to - node ?x - mine-cell)
    :precondition (and
      (at ?from)
      (trans-safe-c22 ?from ?to)
      (writes-knot-mine-cell ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not-mine-cell ?x))
  )
  (:action commit-mine-cell
    :parameters (?x - mine-cell ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-mine-cell ?x)
      (not (committed-mine-cell)))
    :effect (and
      (committed-mine-cell))
  )
  (:action neg-commit-mine-cell
    :parameters (?x - mine-cell ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
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
