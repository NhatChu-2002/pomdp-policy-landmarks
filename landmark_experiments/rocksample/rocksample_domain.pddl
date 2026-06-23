(define (domain rocksample-policy-fsc)
  (:requirements :strips :adl :negative-preconditions :typing)

  ;; ===================================================================
  ;; DOMAIN: RockSample (3 rocks) — FSC belief-landmark encoding
  ;;
  ;; A rover must assess the quality (good/bad) of three rocks by
  ;; sensing each sequentially. The FSC commits to a quality belief
  ;; for each rock before reporting an assessment.
  ;;
  ;; Follows the sensor_v3 split-belief pattern:
  ;;   sense-good sets k(r good)   AND k-not(r bad)
  ;;   sense-bad  sets k(r bad)    AND k-not(r good)
  ;;
  ;; Six commitment gates (2 per rock):
  ;;   r1-committed     : requires k(r1 ?q)     -> disj{k(r1 good), k(r1 bad)}
  ;;   r1-neg-committed : requires k-not(r1 ?q) -> disj{k-not(r1 good), k-not(r1 bad)}
  ;;   r2-committed, r2-neg-committed  (analogous)
  ;;   r3-committed, r3-neg-committed  (analogous)
  ;;
  ;; Expected landmark output: 6 disjunctive landmarks (2 per rock),
  ;; each width 2 — one over k, one over k-not — with all gates
  ;; required before assessment can fire.
  ;; ===================================================================

  (:types node tape rock quality)

  (:predicates
    (at ?n - node)
    (tape-at ?t - tape)
    (next ?t ?tp - tape)
    (consumed ?t - tape)

    (k0) (k1) (k2) (k3) (k4) (k5) (k6) (k7) (k8) (k9) (k10)

    ;; FSC transition table
    (trans-good ?n - node ?r - rock ?m - node)
    (trans-bad  ?n - node ?r - rock ?m - node)
    (commit-node ?n - node)
    (reset-arc ?n - node ?m - node)

    ;; Rock identity flags (for per-rock commitment gates)
    (first-rock  ?r - rock)
    (second-rock ?r - rock)
    (third-rock  ?r - rock)

    ;; Quality identity flags
    (good-quality ?q - quality)
    (bad-quality  ?q - quality)

    ;; === SPLIT BELIEF PREDICATES ===
    ;; sense-good: k(r good) AND k-not(r bad)
    ;; sense-bad:  k(r bad)  AND k-not(r good)
    (k     ?r - rock ?q - quality)
    (k-not ?r - rock ?q - quality)

    ;; Per-rock commitment gates (6 total)
    (r1-committed)
    (r1-neg-committed)
    (r2-committed)
    (r2-neg-committed)
    (r3-committed)
    (r3-neg-committed)

    (resetting)

    (rock-assessed ?r - rock)
    (all-rocks-assessed)
    (assessment-confirmed)
    (done)
  )

  ;; ---------------------------------------------------------------
  ;; SENSING ACTIONS — set k and k-not as complementary pairs
  ;; ---------------------------------------------------------------

  ;; good observation: rover believes rock is good quality
  (:action sense-good
    :parameters (?n ?m - node ?r - rock ?q ?q2 - quality ?t ?tp - tape)
    :precondition (and
      (not (done)) (not (resetting))
      (at ?n) (tape-at ?t) (next ?t ?tp) (not (consumed ?t))
      (trans-good ?n ?r ?m)
      (good-quality ?q)
      (bad-quality ?q2)
      (not (= ?q ?q2))
    )
    :effect (and
      (consumed ?t) (not (tape-at ?t)) (tape-at ?tp)
      (not (at ?n)) (at ?m)
      (k ?r ?q)
      (not (k ?r ?q2))
      (k-not ?r ?q2)
      (not (k-not ?r ?q))
    )
  )

  ;; bad observation: rover believes rock is bad quality
  (:action sense-bad
    :parameters (?n ?m - node ?r - rock ?q ?q2 - quality ?t ?tp - tape)
    :precondition (and
      (not (done)) (not (resetting))
      (at ?n) (tape-at ?t) (next ?t ?tp) (not (consumed ?t))
      (trans-bad ?n ?r ?m)
      (bad-quality ?q)
      (good-quality ?q2)
      (not (= ?q ?q2))
    )
    :effect (and
      (consumed ?t) (not (tape-at ?t)) (tape-at ?tp)
      (not (at ?n)) (at ?m)
      (k ?r ?q)
      (not (k ?r ?q2))
      (k-not ?r ?q2)
      (not (k-not ?r ?q))
    )
  )

  ;; ---------------------------------------------------------------
  ;; COMMITMENT GATES — 6 total, 2 per rock
  ;; k gates    -> disj{k(r1 good), k(r1 bad)}
  ;;              disj{k(r2 good), k(r2 bad)}
  ;;              disj{k(r3 good), k(r3 bad)}
  ;; k-not gates -> disj{k-not(r1 good), k-not(r1 bad)}
  ;;               disj{k-not(r2 good), k-not(r2 bad)}
  ;;               disj{k-not(r3 good), k-not(r3 bad)}
  ;; ---------------------------------------------------------------

  (:action commit-r1-k
    :parameters (?r - rock ?q - quality)
    :precondition (and
      (k ?r ?q) (first-rock ?r)
      (not (r1-committed)) (not (resetting))
    )
    :effect (r1-committed)
  )

  (:action commit-r1-knot
    :parameters (?r - rock ?q - quality)
    :precondition (and
      (k-not ?r ?q) (first-rock ?r)
      (not (r1-neg-committed)) (not (resetting))
    )
    :effect (r1-neg-committed)
  )

  (:action commit-r2-k
    :parameters (?r - rock ?q - quality)
    :precondition (and
      (k ?r ?q) (second-rock ?r)
      (not (r2-committed)) (not (resetting))
    )
    :effect (r2-committed)
  )

  (:action commit-r2-knot
    :parameters (?r - rock ?q - quality)
    :precondition (and
      (k-not ?r ?q) (second-rock ?r)
      (not (r2-neg-committed)) (not (resetting))
    )
    :effect (r2-neg-committed)
  )

  (:action commit-r3-k
    :parameters (?r - rock ?q - quality)
    :precondition (and
      (k ?r ?q) (third-rock ?r)
      (not (r3-committed)) (not (resetting))
    )
    :effect (r3-committed)
  )

  (:action commit-r3-knot
    :parameters (?r - rock ?q - quality)
    :precondition (and
      (k-not ?r ?q) (third-rock ?r)
      (not (r3-neg-committed)) (not (resetting))
    )
    :effect (r3-neg-committed)
  )

  ;; ---------------------------------------------------------------
  ;; ASSESSMENT — all six gates must hold
  ;; ---------------------------------------------------------------

  (:action assess-rock
    :parameters (?n - node ?r - rock)
    :precondition (and
      (not (done)) (at ?n) (commit-node ?n)
      (r1-committed) (r1-neg-committed)
      (r2-committed) (r2-neg-committed)
      (r3-committed) (r3-neg-committed)
      (not (resetting))
      (not (rock-assessed ?r))
    )
    :effect (rock-assessed ?r)
  )

  (:action set-all-assessed
    :parameters (?n - node ?ra ?rb ?rc - rock)
    :precondition (and
      (at ?n) (commit-node ?n) (not (resetting))
      (not (= ?ra ?rb)) (not (= ?ra ?rc)) (not (= ?rb ?rc))
      (rock-assessed ?ra) (rock-assessed ?rb) (rock-assessed ?rc)
      (not (all-rocks-assessed))
    )
    :effect (all-rocks-assessed)
  )

  (:action confirm-assessment
    :parameters (?n - node)
    :precondition (and
      (at ?n) (commit-node ?n) (not (resetting))
      (all-rocks-assessed) (not (assessment-confirmed))
      (r1-committed) (r1-neg-committed)
      (r2-committed) (r2-neg-committed)
      (r3-committed) (r3-neg-committed)
    )
    :effect (assessment-confirmed)
  )

  ;; ---------------------------------------------------------------
  ;; RESET SEQUENCE
  ;; ---------------------------------------------------------------

  (:action begin-reset
    :parameters (?n ?m - node)
    :precondition (and
      (at ?n) (commit-node ?n)
      (r1-committed) (r1-neg-committed)
      (r2-committed) (r2-neg-committed)
      (r3-committed) (r3-neg-committed)
      (reset-arc ?n ?m)
      (not (done)) (not (resetting))
    )
    :effect (and
      (not (at ?n)) (at ?m)
      (resetting)
      (when (k0)  (and (not (k0))  (k1)))
      (when (k1)  (and (not (k1))  (k2)))
      (when (k2)  (and (not (k2))  (k3)))
      (when (k3)  (and (not (k3))  (k4)))
      (when (k4)  (and (not (k4))  (k5)))
      (when (k5)  (and (not (k5))  (k6)))
      (when (k6)  (and (not (k6))  (k7)))
      (when (k7)  (and (not (k7))  (k8)))
      (when (k8)  (and (not (k8))  (k9)))
      (when (k9)  (and (not (k9))  (k10)))
    )
  )

  (:action clear-k
    :parameters (?r - rock ?q - quality)
    :precondition (and (resetting) (k ?r ?q))
    :effect (not (k ?r ?q))
  )

  (:action clear-k-not
    :parameters (?r - rock ?q - quality)
    :precondition (and (resetting) (k-not ?r ?q))
    :effect (not (k-not ?r ?q))
  )

  (:action clear-r1-gate
    :precondition (and (resetting) (r1-committed))
    :effect (not (r1-committed))
  )

  (:action clear-r1-neg-gate
    :precondition (and (resetting) (r1-neg-committed))
    :effect (not (r1-neg-committed))
  )

  (:action clear-r2-gate
    :precondition (and (resetting) (r2-committed))
    :effect (not (r2-committed))
  )

  (:action clear-r2-neg-gate
    :precondition (and (resetting) (r2-neg-committed))
    :effect (not (r2-neg-committed))
  )

  (:action clear-r3-gate
    :precondition (and (resetting) (r3-committed))
    :effect (not (r3-committed))
  )

  (:action clear-r3-neg-gate
    :precondition (and (resetting) (r3-neg-committed))
    :effect (not (r3-neg-committed))
  )

  (:action end-reset
    :precondition (and
      (resetting)
      (not (r1-committed)) (not (r1-neg-committed))
      (not (r2-committed)) (not (r2-neg-committed))
      (not (r3-committed)) (not (r3-neg-committed))
    )
    :effect (not (resetting))
  )

  ;; ---------------------------------------------------------------
  ;; FINISH
  ;; ---------------------------------------------------------------

  (:action finish
    :precondition (k10)
    :effect (done)
  )
)
