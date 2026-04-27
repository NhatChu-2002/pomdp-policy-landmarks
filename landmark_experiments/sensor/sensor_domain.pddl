(define (domain faulty-sensor-policy-fsc)
  (:requirements :strips :adl :negative-preconditions :typing)

  ;; ===================================================================
  ;; DOMAIN: Faulty Robot Sensor (2 sensors, 2 possible faults)
  ;;
  ;; Hidden state: two INDEPENDENT binary variables.
  ;;   sensor sA is faulty (yes/no)
  ;;   sensor sB is faulty (yes/no)
  ;; Four possible world states: (ok,ok),(faulty,ok),(ok,faulty),(faulty,faulty)
  ;;
  ;; Observations per sensor:
  ;;   "agree"    — reading matches expected (evidence sensor is ok)
  ;;   "disagree" — reading contradicts expected (evidence sensor is faulty)
  ;;
  ;; Belief predicates (k-pattern, one pair PER hidden variable):
  ;;   k-ok(?s)     — believe sensor ?s is functioning correctly
  ;;   k-faulty(?s) — believe sensor ?s is faulty
  ;;
  ;; Key hypothesis test: two independent hidden variables should produce
  ;; TWO separate disjunctive landmarks, one per sensor:
  ;;   disj{k-ok(sA), k-faulty(sA)}
  ;;   disj{k-ok(sB), k-faulty(sB)}
  ;;
  ;; Commitment gates are split per sensor (sA-committed, sB-committed)
  ;; rather than shared — this is what forces the extractor to see two
  ;; independent disjunctions rather than one joint 4-way disjunction.
  ;; ===================================================================

  (:types node tape sensor)

  (:predicates
    (at ?n - node)
    (tape-at ?t - tape)
    (next ?t ?tp - tape)
    (consumed ?t - tape)

    (k0) (k1) (k2) (k3) (k4) (k5) (k6) (k7) (k8)

    ;; FSC topology
    (trans-agree    ?n - node ?s - sensor ?m - node)
    (trans-disagree ?n - node ?s - sensor ?m - node)
    (commit-node ?n - node)
    (reset-arc ?n - node ?m - node)

    ;; Belief predicates — k-pattern per sensor
    (k-ok     ?s - sensor)
    (k-faulty ?s - sensor)

    ;; Per-sensor commitment gates (split deliberately to produce 2 disjunctions)
    (sA-committed)
    (sB-committed)

    (resetting)

    (sensor-diagnosed ?s - sensor)
    (all-diagnosed)
    (diagnosis-confirmed)
    (done)
    (first-sensor  ?s - sensor)
    (second-sensor ?s - sensor)
  )

  ;; ---------------------------------------------------------------
  ;; READ ACTIONS — parametric over sensor
  ;; ---------------------------------------------------------------
  (:action read-agree
    :parameters (?n ?m - node ?s - sensor ?t ?tp - tape)
    :precondition (and
      (not (done)) (not (resetting))
      (at ?n) (tape-at ?t) (next ?t ?tp) (not (consumed ?t))
      (trans-agree ?n ?s ?m)
    )
    :effect (and
      (consumed ?t) (not (tape-at ?t)) (tape-at ?tp)
      (not (at ?n)) (at ?m)
      (k-ok ?s)
      (not (k-faulty ?s))
    )
  )

  (:action read-disagree
    :parameters (?n ?m - node ?s - sensor ?t ?tp - tape)
    :precondition (and
      (not (done)) (not (resetting))
      (at ?n) (tape-at ?t) (next ?t ?tp) (not (consumed ?t))
      (trans-disagree ?n ?s ?m)
    )
    :effect (and
      (consumed ?t) (not (tape-at ?t)) (tape-at ?tp)
      (not (at ?n)) (at ?m)
      (k-faulty ?s)
      (not (k-ok ?s))
    )
  )

  ;; ---------------------------------------------------------------
  ;; COMMITMENT GATES — separate per sensor, no ground constants
  ;; sA-committed fires on k-ok(sA) OR k-faulty(sA)
  ;; sB-committed fires on k-ok(sB) OR k-faulty(sB)
  ;; The sensor identity is encoded via the trans-* arcs in the problem:
  ;; sA arcs only appear for sensor sA, so only sA groundings fire here.
  ;;
  ;; We use a "sensor-is-A" / "sensor-is-B" flag set in problem init
  ;; to make the gate actions sensor-specific without ground constants.
  ;; ---------------------------------------------------------------
  ;; Gate flag predicates (set in problem init to tag each sensor)
  ;; is-sensorA(?s) — true only for sA
  ;; is-sensorB(?s) — true only for sB

    ;; Actually: simplest correct approach — make gate actions take a
    ;; sensor param and require the appropriate topology predicate as
    ;; a proxy for identity. We use "first-sensor(?s)" and "second-sensor(?s)"
    ;; set in init to distinguish sA from sB without ground constants.

  (:action commit-first-ok
    :parameters (?s - sensor)
    :precondition (and (k-ok ?s) (first-sensor ?s) (not (sA-committed)) (not (resetting)))
    :effect (sA-committed)
  )

  (:action commit-first-faulty
    :parameters (?s - sensor)
    :precondition (and (k-faulty ?s) (first-sensor ?s) (not (sA-committed)) (not (resetting)))
    :effect (sA-committed)
  )

  (:action commit-second-ok
    :parameters (?s - sensor)
    :precondition (and (k-ok ?s) (second-sensor ?s) (not (sB-committed)) (not (resetting)))
    :effect (sB-committed)
  )

  (:action commit-second-faulty
    :parameters (?s - sensor)
    :precondition (and (k-faulty ?s) (second-sensor ?s) (not (sB-committed)) (not (resetting)))
    :effect (sB-committed)
  )

  ;; ---------------------------------------------------------------
  ;; DIAGNOSIS — both gates must be open
  ;; ---------------------------------------------------------------
  (:action diagnose-sensor
    :parameters (?n - node ?s - sensor)
    :precondition (and
      (not (done)) (at ?n) (commit-node ?n)
      (sA-committed) (sB-committed) (not (resetting))
      (not (sensor-diagnosed ?s))
    )
    :effect (sensor-diagnosed ?s)
  )

  (:action set-all-diagnosed
    :parameters (?n - node ?sa ?sb - sensor)
    :precondition (and
      (at ?n) (commit-node ?n) (not (resetting))
      (not (= ?sa ?sb))
      (sensor-diagnosed ?sa) (sensor-diagnosed ?sb)
      (not (all-diagnosed))
    )
    :effect (all-diagnosed)
  )

  (:action confirm-diagnosis
    :parameters (?n - node)
    :precondition (and
      (at ?n) (commit-node ?n) (not (resetting))
      (all-diagnosed) (not (diagnosis-confirmed))
      (sA-committed) (sB-committed)
    )
    :effect (diagnosis-confirmed)
  )

  ;; ---------------------------------------------------------------
  ;; RESET SEQUENCE
  ;; ---------------------------------------------------------------
  (:action begin-reset
    :parameters (?n ?m - node)
    :precondition (and
      (at ?n) (commit-node ?n)
      (sA-committed) (sB-committed)
      (reset-arc ?n ?m)
      (not (done)) (not (resetting))
    )
    :effect (and
      (not (at ?n)) (at ?m)
      (resetting)
      (when (k0) (and (not (k0)) (k1)))
      (when (k1) (and (not (k1)) (k2)))
      (when (k2) (and (not (k2)) (k3)))
      (when (k3) (and (not (k3)) (k4)))
      (when (k4) (and (not (k4)) (k5)))
      (when (k5) (and (not (k5)) (k6)))
      (when (k6) (and (not (k6)) (k7)))
      (when (k7) (and (not (k7)) (k8)))
    )
  )

  (:action clear-k-ok
    :parameters (?s - sensor)
    :precondition (and (resetting) (k-ok ?s))
    :effect (not (k-ok ?s))
  )

  (:action clear-k-faulty
    :parameters (?s - sensor)
    :precondition (and (resetting) (k-faulty ?s))
    :effect (not (k-faulty ?s))
  )

  (:action clear-sA-gate
    :precondition (and (resetting) (sA-committed))
    :effect (not (sA-committed))
  )

  (:action clear-sB-gate
    :precondition (and (resetting) (sB-committed))
    :effect (not (sB-committed))
  )

  (:action end-reset
    :precondition (and (resetting) (not (sA-committed)) (not (sB-committed)))
    :effect (not (resetting))
  )

  ;; ---------------------------------------------------------------
  ;; FINISH
  ;; ---------------------------------------------------------------
  (:action finish
    :precondition (k8)
    :effect (done)
  )
)
