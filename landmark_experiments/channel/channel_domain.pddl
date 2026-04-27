(define (domain channel-policy-fsc)
  (:requirements :strips :adl :negative-preconditions :typing)

  (:types node tape channel)

  (:predicates
    (at ?n - node)
    (tape-at ?t - tape)
    (next ?t ?tp - tape)
    (consumed ?t - tape)

    (k0) (k1) (k2) (k3) (k4) (k5) (k6) (k7) (k8)

    (trans-signal ?n - node ?c - channel ?m - node)
    (trans-noise  ?n - node ?c - channel ?m - node)
    (commit-node ?n - node)
    (reset-arc ?n - node ?m - node)

    (k     ?c - channel)
    (k-not ?c - channel)

    (belief-committed)
    (negbelief-committed)

    (resetting)

    (channel-confirmed ?c - channel)
    (all-confirmed)
    (identification-done)
    (done)
  )

  ;; ---------------------------------------------------------------
  ;; PROBE ACTIONS
  ;; ---------------------------------------------------------------

  (:action probe-signal
    :parameters (?n ?m - node ?c ?ca ?cb - channel ?t ?tp - tape)
    :precondition (and
      (not (done)) (not (resetting))
      (at ?n) (tape-at ?t) (next ?t ?tp) (not (consumed ?t))
      (trans-signal ?n ?c ?m)
      (not (= ?c ?ca)) (not (= ?c ?cb)) (not (= ?ca ?cb))
    )
    :effect (and
      (consumed ?t) (not (tape-at ?t)) (tape-at ?tp)
      (not (at ?n)) (at ?m)
      (k ?c) (not (k ?ca)) (not (k ?cb))
      (not (k-not ?c)) (k-not ?ca) (k-not ?cb)
    )
  )

  (:action probe-noise
    :parameters (?n ?m - node ?c ?ca ?cb - channel ?t ?tp - tape)
    :precondition (and
      (not (done)) (not (resetting))
      (at ?n) (tape-at ?t) (next ?t ?tp) (not (consumed ?t))
      (trans-noise ?n ?c ?m)
      (not (= ?c ?ca)) (not (= ?c ?cb)) (not (= ?ca ?cb))
    )
    :effect (and
      (consumed ?t) (not (tape-at ?t)) (tape-at ?tp)
      (not (at ?n)) (at ?m)
      (k ?ca) (not (k ?c)) (not (k ?cb))
      (not (k-not ?ca)) (k-not ?c) (k-not ?cb)
    )
  )

  ;; ---------------------------------------------------------------
  ;; COMMITMENT GATES
  ;; Produce: disj{k(c1),k(c2),k(c3)} and disj{k-not(c1),k-not(c2),k-not(c3)}
  ;; ---------------------------------------------------------------

  (:action commit-belief
    :parameters (?c - channel)
    :precondition (and (k ?c) (not (belief-committed)) (not (resetting)))
    :effect (belief-committed)
  )

  (:action commit-negbelief
    :parameters (?c - channel)
    :precondition (and (k-not ?c) (not (negbelief-committed)) (not (resetting)))
    :effect (negbelief-committed)
  )

  ;; ---------------------------------------------------------------
  ;; CONFIRMATION
  ;; ---------------------------------------------------------------

  (:action check-channel
    :parameters (?n - node ?c - channel)
    :precondition (and
      (not (done)) (at ?n) (commit-node ?n)
      (belief-committed) (negbelief-committed) (not (resetting))
      (not (channel-confirmed ?c))
    )
    :effect (channel-confirmed ?c)
  )

  (:action set-all-confirmed
    :parameters (?n - node ?ca ?cb ?cc - channel)
    :precondition (and
      (at ?n) (commit-node ?n) (not (resetting))
      (not (= ?ca ?cb)) (not (= ?ca ?cc)) (not (= ?cb ?cc))
      (channel-confirmed ?ca) (channel-confirmed ?cb) (channel-confirmed ?cc)
      (not (all-confirmed))
    )
    :effect (all-confirmed)
  )

  (:action confirm-identification
    :parameters (?n - node)
    :precondition (and
      (at ?n) (commit-node ?n) (not (resetting))
      (all-confirmed) (not (identification-done))
      (belief-committed) (negbelief-committed)
    )
    :effect (identification-done)
  )

  ;; ---------------------------------------------------------------
  ;; RESET SEQUENCE
  ;; Step 1: begin-reset  — enter resetting mode, move node, tick counter
  ;; Step 2: clear-k      — clear k(?c) for a specific channel
  ;; Step 3: clear-k-not  — clear k-not(?c) for a specific channel
  ;; Step 4: end-reset    — exit resetting mode, clear gates
  ;; ---------------------------------------------------------------

  (:action begin-reset
    :parameters (?n ?m - node)
    :precondition (and
      (at ?n) (commit-node ?n)
      (belief-committed) (negbelief-committed)
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
    :parameters (?c - channel)
    :precondition (and (resetting) (k ?c))
    :effect (not (k ?c))
  )

  (:action clear-k-not
    :parameters (?c - channel)
    :precondition (and (resetting) (k-not ?c))
    :effect (not (k-not ?c))
  )

  (:action end-reset
    :precondition (and
      (resetting)
      (not (belief-committed))
      (not (negbelief-committed))
    )
    :effect (not (resetting))
  )

  ;; Clear gates during reset
  (:action clear-belief-gate
    :precondition (and (resetting) (belief-committed))
    :effect (not (belief-committed))
  )

  (:action clear-negbelief-gate
    :precondition (and (resetting) (negbelief-committed))
    :effect (not (negbelief-committed))
  )

  ;; ---------------------------------------------------------------
  ;; FINISH
  ;; ---------------------------------------------------------------
  (:action finish
    :precondition (k8)
    :effect (done)
  )
)
