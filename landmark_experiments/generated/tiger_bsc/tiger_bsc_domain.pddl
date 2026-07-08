(define (domain tiger-bsc)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types direction - object)
  (:predicates
    (self-direction-left ?x - direction)
    (self-direction-right ?x - direction)
    (k-direction ?x - direction)
    (k-not-direction ?x - direction)
    (committed-direction)
    (neg-committed-direction)
    (confirmed-direction)
    (done)
  )
  (:action sense-left-0
    :parameters (?x-direction-left - direction ?x-direction-right - direction)
    :precondition (and
      (self-direction-left ?x-direction-left)
      (self-direction-right ?x-direction-right)
      (not (k-direction ?x-direction-left))
      (not (k-direction ?x-direction-right)))
    :effect (and
      (k-direction ?x-direction-left))
  )
  (:action sense-right-1
    :parameters (?x-direction-left - direction ?x-direction-right - direction)
    :precondition (and
      (self-direction-left ?x-direction-left)
      (self-direction-right ?x-direction-right)
      (not (k-direction ?x-direction-left))
      (not (k-direction ?x-direction-right)))
    :effect (and
      (k-direction ?x-direction-right))
  )
  (:action sense-left-2
    :parameters (?x-direction-left - direction ?x-direction-right - direction)
    :precondition (and
      (self-direction-left ?x-direction-left)
      (self-direction-right ?x-direction-right)
      (k-direction ?x-direction-left)
      (not (k-not-direction ?x-direction-right)))
    :effect (and
      (k-not-direction ?x-direction-right))
  )
  (:action sense-right-3
    :parameters (?x-direction-left - direction ?x-direction-right - direction)
    :precondition (and
      (self-direction-left ?x-direction-left)
      (self-direction-right ?x-direction-right)
      (k-direction ?x-direction-left)
      (not (k-not-direction ?x-direction-right)))
    :effect (and
      (not (k-direction ?x-direction-left)))
  )
  (:action sense-right-4
    :parameters (?x-direction-right - direction ?x-direction-left - direction)
    :precondition (and
      (self-direction-right ?x-direction-right)
      (self-direction-left ?x-direction-left)
      (k-direction ?x-direction-right)
      (not (k-not-direction ?x-direction-left)))
    :effect (and
      (k-not-direction ?x-direction-left))
  )
  (:action sense-left-5
    :parameters (?x-direction-right - direction ?x-direction-left - direction)
    :precondition (and
      (self-direction-right ?x-direction-right)
      (self-direction-left ?x-direction-left)
      (k-direction ?x-direction-right)
      (not (k-not-direction ?x-direction-left)))
    :effect (and
      (not (k-direction ?x-direction-right)))
  )
  (:action commit-direction
    :parameters (?x - direction)
    :precondition (and
      (k-direction ?x)
      (not (committed-direction)))
    :effect (and
      (committed-direction))
  )
  (:action neg-commit-direction
    :parameters (?x - direction)
    :precondition (and
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
