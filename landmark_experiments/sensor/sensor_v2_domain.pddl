(define (domain faulty-sensor-policy-fsc-v2)
  (:requirements :strips :adl :negative-preconditions :typing)

  ;; ===================================================================
  ;; DOMAIN: Faulty Robot Sensor v2
  ;;
  ;; Key change from v1: k-ok(?s) / k-faulty(?s) are merged into a
  ;; single parametric predicate k(?s ?st) where ?st in {ok, faulty}.
  ;; This matches the Tiger/Channel k(?c) pattern exactly, so FD's
  ;; landmark factories will emit:
  ;;   disj { k(sA ok), k(sA faulty) }   <- hidden variable 1
  ;;   disj { k(sB ok), k(sB faulty) }   <- hidden variable 2
  ;;
  ;; No ground constants in action bodies. Status identity encoded via:
  ;;   (ok-status ?st)     — true only for the "ok" object
  ;;   (faulty-status ?st) — true only for the "faulty" object
  ;; Sensor identity encoded via:
  ;;   (first-sensor ?s)   — true only for sA
  ;;   (second-sensor ?s)  — true only for sB
  ;; All set in problem :init.
  ;; ===================================================================

  (:types node tape sensor status)

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

    ;; Identity flags (set in problem init, no ground constants in actions)
    (first-sensor   ?s - sensor)
    (second-sensor  ?s - sensor)
    (ok-status      ?st - status)
    (faulty-status  ?st - status)

    ;; === UNIFIED BELIEF PREDICATE ===
    ;; k(?s ?st) : believe sensor ?s has status ?st (ok or faulty)
    ;; This is the parametric k() pattern that produces disjunctive landmarks.
    ;; FD sees two groundings per sensor: k(sA ok), k(sA faulty)
    ;; and emits: disj{k(sA ok), k(sA faulty)} and disj{k(sB ok), k(sB faulty)}
    (k ?s - sensor ?st - status)

    ;; Per-sensor commitment gates (one disjunction each)
    (sA-committed)
    (sB-committed)

    (resetting)

    ;; Goal tracking
    (sensor-diagnosed ?s - sensor)
    (all-diagnosed)
    (diagnosis-confirmed)
    (done)
  )

  ;; ---------------------------------------------------------------
  ;; READ ACTIONS
  ;; read-agree    : obs matches expected -> k(sA ok)
  ;; read-disagree : obs contradicts      -> k(sA faulty)
  ;; Both use ok-status/faulty-status flags to set the right k grounding
  ;; without referencing "ok" or "faulty" as ground constants.
  ;; ---------------------------------------------------------------

  (:action read-agree
    :parameters (?n ?m - node ?s - sensor ?st ?st2 - status ?t ?tp - tape)
    :precondition (and
      (not (done)) (not (resetting))
      (at ?n) (tape-at ?t) (next ?t ?tp) (not (consumed ?t))
      (trans-agree ?n ?s ?m)
      (ok-status ?st)
      (faulty-status ?st2)
      (not (= ?st ?st2))
    )
    :effect (and
      (consumed ?t) (not (tape-at ?t)) (tape-at ?tp)
      (not (at ?n)) (at ?m)
      (k ?s ?st)
      (not (k ?s ?st2))
    )
  )

  (:action read-disagree
    :parameters (?n ?m - node ?s - sensor ?st ?st2 - status ?t ?tp - tape)
    :precondition (and
      (not (done)) (not (resetting))
      (at ?n) (tape-at ?t) (next ?t ?tp) (not (consumed ?t))
      (trans-disagree ?n ?s ?m)
      (faulty-status ?st)
      (ok-status ?st2)
      (not (= ?st ?st2))
    )
    :effect (and
      (consumed ?t) (not (tape-at ?t)) (tape-at ?tp)
      (not (at ?n)) (at ?m)
      (k ?s ?st)
      (not (k ?s ?st2))
    )
  )

  ;; ---------------------------------------------------------------
  ;; COMMITMENT GATES
  ;; Each gate fires on k(?s ?st) for ANY status ?st.
  ;; first-sensor/second-sensor flags distinguish sA from sB.
  ;; This is what forces FD to see the disjunction:
  ;;   sA-committed requires k(sA ok) OR k(sA faulty)
  ;;   -> disj { k(sA ok), k(sA faulty) }
  ;; ---------------------------------------------------------------

  (:action commit-sA
    :parameters (?s - sensor ?st - status)
    :precondition (and
      (k ?s ?st)
      (first-sensor ?s)
      (not (sA-committed))
      (not (resetting))
    )
    :effect (sA-committed)
  )

  (:action commit-sB
    :parameters (?s - sensor ?st - status)
    :precondition (and
      (k ?s ?st)
      (second-sensor ?s)
      (not (sB-committed))
      (not (resetting))
    )
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

  (:action clear-k
    :parameters (?s - sensor ?st - status)
    :precondition (and (resetting) (k ?s ?st))
    :effect (not (k ?s ?st))
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
    :precondition (and
      (resetting)
      (not (sA-committed))
      (not (sB-committed))
    )
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
