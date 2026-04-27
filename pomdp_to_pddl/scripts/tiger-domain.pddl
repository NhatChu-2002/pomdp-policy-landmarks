(define (domain tiger)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types node - object direction - object)
  (:predicates
    (at ?n - node)
    (commit-node ?n - node)
    (k ?x - direction)
    (k-not ?x - direction)
    (committed-direction)
    (neg-committed-direction)
    (confirmed-direction)
    (trans-growl-left ?from - node ?to - node)
    (trans-growl-right ?from - node ?to - node)
    (writes-k-direction ?from - node ?to - node ?x - direction)
    (writes-knot-direction ?from - node ?to - node ?x - direction)
    (done)
  )
  (:action sense-growl-left-move
    :parameters (?from - node ?to - node ?x-direction - direction)
    :precondition (and
      (at ?from)
      (trans-growl-left ?from ?to)
      (forall (?x-direction - direction) (and (not (writes-k-direction ?from ?to ?x-direction)) (not (writes-knot-direction ?from ?to ?x-direction)))))
    :effect (and
      (not (at ?from))
      (at ?to))
  )  (:action sense-growl-left-write-k-direction
    :parameters (?from - node ?to - node ?x - direction)
    :precondition (and
      (at ?from)
      (trans-growl-left ?from ?to)
      (writes-k-direction ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k ?x))
  )
  (:action sense-growl-left-write-knot-direction
    :parameters (?from - node ?to - node ?x - direction)
    :precondition (and
      (at ?from)
      (trans-growl-left ?from ?to)
      (writes-knot-direction ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not ?x))
  )
  (:action sense-growl-right-move
    :parameters (?from - node ?to - node ?x-direction - direction)
    :precondition (and
      (at ?from)
      (trans-growl-right ?from ?to)
      (forall (?x-direction - direction) (and (not (writes-k-direction ?from ?to ?x-direction)) (not (writes-knot-direction ?from ?to ?x-direction)))))
    :effect (and
      (not (at ?from))
      (at ?to))
  )  (:action sense-growl-right-write-k-direction
    :parameters (?from - node ?to - node ?x - direction)
    :precondition (and
      (at ?from)
      (trans-growl-right ?from ?to)
      (writes-k-direction ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k ?x))
  )
  (:action sense-growl-right-write-knot-direction
    :parameters (?from - node ?to - node ?x - direction)
    :precondition (and
      (at ?from)
      (trans-growl-right ?from ?to)
      (writes-knot-direction ?from ?to ?x))
    :effect (and
      (not (at ?from))
      (at ?to)
      (k-not ?x))
  )
  (:action commit-direction
    :parameters (?x - direction ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k ?x)
      (not (committed-direction)))
    :effect (and
      (committed-direction))
  )
  (:action neg-commit-direction
    :parameters (?x - direction ?n - node)
    :precondition (and
      (at ?n)
      (commit-node ?n)
      (k-not ?x)
      (not (neg-committed-direction)))
    :effect (and
      (neg-committed-direction))
  )
  (:action confirm-direction
    :parameters (?x - direction)
    :precondition (and
      (committed-direction)
      (neg-committed-direction)
      (k ?x)
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
