(define (domain tiger-induced)
  (:requirements :strips :typing :negative-preconditions :equality)
  (:types direction - object)
  (:predicates
    (self-direction-left ?x - direction)
    (self-direction-right ?x - direction)
    (k-direction ?x - direction)
    (k-not-direction ?x - direction)
    (committed-direction)
    (uncertain-direction)
    (done)
  )
  (:action sense-right-0
    :parameters (?x-direction-right - direction)
    :precondition (and
      (self-direction-right ?x-direction-right)
      (uncertain-direction))
    :effect (and
      (not (uncertain-direction))
      (k-direction ?x-direction-right))
  )
  (:action sense-right-1
    :parameters (?x-direction-right - direction ?x-direction-left - direction)
    :precondition (and
      (self-direction-right ?x-direction-right)
      (self-direction-left ?x-direction-left)
      (k-direction ?x-direction-right)
      (not (k-not-direction ?x-direction-left)))
    :effect (and
      (k-not-direction ?x-direction-left))
  )
  (:action sense-left-2
    :parameters (?x-direction-right - direction ?x-direction-left - direction)
    :precondition (and
      (self-direction-right ?x-direction-right)
      (self-direction-left ?x-direction-left)
      (k-direction ?x-direction-right)
      (not (k-not-direction ?x-direction-left)))
    :effect (and
      (not (k-direction ?x-direction-right))
      (uncertain-direction))
  )
  (:action sense-left-3
    :parameters (?x-direction-left - direction)
    :precondition (and
      (self-direction-left ?x-direction-left)
      (uncertain-direction))
    :effect (and
      (not (uncertain-direction))
      (k-direction ?x-direction-left))
  )
  (:action sense-left-4
    :parameters (?x-direction-left - direction ?x-direction-right - direction)
    :precondition (and
      (self-direction-left ?x-direction-left)
      (self-direction-right ?x-direction-right)
      (k-direction ?x-direction-left)
      (not (k-not-direction ?x-direction-right)))
    :effect (and
      (k-not-direction ?x-direction-right))
  )
  (:action sense-right-5
    :parameters (?x-direction-right - direction ?x-direction-left - direction)
    :precondition (and
      (self-direction-right ?x-direction-right)
      (self-direction-left ?x-direction-left)
      (k-not-direction ?x-direction-right)
      (k-direction ?x-direction-left))
    :effect (and
      (not (k-not-direction ?x-direction-right)))
  )
  (:action sense-right-6
    :parameters (?x-direction-left - direction ?x-direction-right - direction)
    :precondition (and
      (self-direction-left ?x-direction-left)
      (self-direction-right ?x-direction-right)
      (k-direction ?x-direction-left)
      (not (k-not-direction ?x-direction-right)))
    :effect (and
      (not (k-direction ?x-direction-left))
      (uncertain-direction))
  )
  (:action commit-direction-right-0
    :parameters (?x-direction-left - direction ?x-direction-right - direction)
    :precondition (and
      (self-direction-left ?x-direction-left)
      (self-direction-right ?x-direction-right)
      (k-not-direction ?x-direction-left)
      (k-direction ?x-direction-right)
      (not (committed-direction)))
    :effect (and
      (committed-direction))
  )
  (:action commit-direction-left-1
    :parameters (?x-direction-right - direction ?x-direction-left - direction)
    :precondition (and
      (self-direction-right ?x-direction-right)
      (self-direction-left ?x-direction-left)
      (k-not-direction ?x-direction-right)
      (k-direction ?x-direction-left)
      (not (committed-direction)))
    :effect (and
      (committed-direction))
  )
  (:action finish
    :parameters ()
    :precondition (and
      (committed-direction))
    :effect (and
      (done))
  )
)
