(define (domain faulty-sensor-policy-fsc-v3)
  (:requirements :strips :adl :negative-preconditions :typing)

  ;; ===================================================================
  ;; DOMAIN: Faulty Robot Sensor v3
  ;;
  ;; Adds k-not(?s ?st) as the complementary belief predicate to k(?s ?st),
  ;; following the Tiger/Channel split-belief pattern exactly.
  ;;
  ;; read-agree    sets k(s ok)     AND k-not(s faulty)
  ;; read-disagree sets k(s faulty) AND k-not(s ok)
  ;;
  ;; Two commitment gates per sensor:
  ;;   sA-committed     : requires k(sA ?st)     -> disj{k(sA ok),    k(sA faulty)}
  ;;   sA-neg-committed : requires k-not(sA ?st) -> disj{k-not(sA ok),k-not(sA faulty)}
  ;;   sB-committed     : requires k(sB ?st)     -> disj{k(sB ok),    k(sB faulty)}
  ;;   sB-neg-committed : requires k-not(sB ?st) -> disj{k-not(sB ok),k-not(sB faulty)}
  ;;
  ;; Expected landmark output: 4 disjunctive landmarks (2 per sensor),
  ;; each width 2 — one over k, one over k-not — with both gates required
  ;; before diagnosis can fire.
  ;; ===================================================================

  (:types node tape sensor status)

  (:predicates
    (at ?n - node)
    (tape-at ?t - tape)
    (next ?t ?tp - tape)
    (consumed ?t - tape)

    (k0) (k1) (k2) (k3) (k4) (k5) (k6) (k7) (k8)

    (trans-agree    ?n - node ?s - sensor ?m - node)
    (trans-disagree ?n - node ?s - sensor ?m - node)
    (commit-node ?n - node)
    (reset-arc ?n - node ?m - node)

    (first-sensor   ?s - sensor)
    (second-sensor  ?s - sensor)
    (ok-status      ?st - status)
    (faulty-status  ?st - status)

    ;; === SPLIT BELIEF PREDICATES ===
    ;; Probe actions set these as complementary pairs (one true -> other false)
    (k     ?s - sensor ?st - status)
    (k-not ?s - sensor ?st - status)

    ;; Per-sensor commitment gates — split into k and k-not gates
    ;; to produce 4 disjunctive landmarks total (2 per sensor)
    (sA-committed)
    (sA-neg-committed)
    (sB-committed)
    (sB-neg-committed)

    (resetting)

    (sensor-diagnosed ?s - sensor)
    (all-diagnosed)
    (diagnosis-confirmed)
    (done)
  )

  ;; ---------------------------------------------------------------
  ;; READ ACTIONS — set k and k-not as complementary pairs
  ;; ---------------------------------------------------------------

  ;; agree: sensor matches expected -> k(s ok), k-not(s faulty)
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
      ;; Positive belief: sensor is ok
      (k ?s ?st)
      (not (k ?s ?st2))
      ;; Negative belief: sensor is not faulty
      (k-not ?s ?st2)
      (not (k-not ?s ?st))
    )
  )

  ;; disagree: sensor contradicts expected -> k(s faulty), k-not(s ok)
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
      ;; Positive belief: sensor is faulty
      (k ?s ?st)
      (not (k ?s ?st2))
      ;; Negative belief: sensor is not ok
      (k-not ?s ?st2)
      (not (k-not ?s ?st))
    )
  )

  ;; ---------------------------------------------------------------
  ;; COMMITMENT GATES — 4 total, 2 per sensor
  ;; k gates    -> disj{k(sA ok),     k(sA faulty)}
  ;;              disj{k(sB ok),     k(sB faulty)}
  ;; k-not gates -> disj{k-not(sA ok), k-not(sA faulty)}
  ;;               disj{k-not(sB ok), k-not(sB faulty)}
  ;; ---------------------------------------------------------------

  (:action commit-sA-k
    :parameters (?s - sensor ?st - status)
    :precondition (and
      (k ?s ?st) (first-sensor ?s)
      (not (sA-committed)) (not (resetting))
    )
    :effect (sA-committed)
  )

  (:action commit-sA-knot
    :parameters (?s - sensor ?st - status)
    :precondition (and
      (k-not ?s ?st) (first-sensor ?s)
      (not (sA-neg-committed)) (not (resetting))
    )
    :effect (sA-neg-committed)
  )

  (:action commit-sB-k
    :parameters (?s - sensor ?st - status)
    :precondition (and
      (k ?s ?st) (second-sensor ?s)
      (not (sB-committed)) (not (resetting))
    )
    :effect (sB-committed)
  )

  (:action commit-sB-knot
    :parameters (?s - sensor ?st - status)
    :precondition (and
      (k-not ?s ?st) (second-sensor ?s)
      (not (sB-neg-committed)) (not (resetting))
    )
    :effect (sB-neg-committed)
  )

  ;; ---------------------------------------------------------------
  ;; DIAGNOSIS — all four gates must be open
  ;; ---------------------------------------------------------------

  (:action diagnose-sensor
    :parameters (?n - node ?s - sensor)
    :precondition (and
      (not (done)) (at ?n) (commit-node ?n)
      (sA-committed) (sA-neg-committed)
      (sB-committed) (sB-neg-committed)
      (not (resetting))
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
      (sA-committed) (sA-neg-committed)
      (sB-committed) (sB-neg-committed)
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
      (sA-committed) (sA-neg-committed)
      (sB-committed) (sB-neg-committed)
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

  (:action clear-k-not
    :parameters (?s - sensor ?st - status)
    :precondition (and (resetting) (k-not ?s ?st))
    :effect (not (k-not ?s ?st))
  )

  (:action clear-sA-gate
    :precondition (and (resetting) (sA-committed))
    :effect (not (sA-committed))
  )

  (:action clear-sA-neg-gate
    :precondition (and (resetting) (sA-neg-committed))
    :effect (not (sA-neg-committed))
  )

  (:action clear-sB-gate
    :precondition (and (resetting) (sB-committed))
    :effect (not (sB-committed))
  )

  (:action clear-sB-neg-gate
    :precondition (and (resetting) (sB-neg-committed))
    :effect (not (sB-neg-committed))
  )

  (:action end-reset
    :precondition (and
      (resetting)
      (not (sA-committed)) (not (sA-neg-committed))
      (not (sB-committed)) (not (sB-neg-committed))
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
