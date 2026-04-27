(define (domain tiger-policy-fsc-nd)
  (:requirements :strips :adl :negative-preconditions :typing)

  (:types node tape tag)

  (:predicates
    (at ?n - node)

    (k0) (k1) (k2) (k3) (k4) (k5) (k6)

    (tape-at ?t - tape)
    (next ?t ?tp - tape)
    (consumed ?t - tape)

    ;; k-left and k-right MUST be mutually exclusive so FD merges
    ;; them into one SAS+ variable. Every action that sets one
    ;; must delete the other.
    (k-left)
    (k-right)

    (k-not-left)
    (k-not-right)

    (tiger-left ?g - tag)
    (tiger-right ?g - tag)

    (confirmed ?g - tag)

    (tiger-confirmed)
    (done)

    ;; belief-committed is achieved ONLY via commit-belief-left (needs k-left)
    ;; or commit-belief-right (needs k-right). Since k-left and k-right
    ;; will be values of the same SAS+ variable, this creates a
    ;; same-variable disjunctive landmark.
    (belief-committed)
  )

  ;; ===================================================================
  ;; LISTEN actions — set k-left/k-right as mutex pair
  ;; ===================================================================

  ;; --- b0 ---
  (:action pi_listen_b0_left
    :parameters (?t ?tp - tape)
    :precondition (and
      (not (done))
      (at b0)
      (tape-at ?t)
      (next ?t ?tp)
      (not (consumed ?t))
    )
    :effect (and
      (consumed ?t)
      (not (tape-at ?t)) (tape-at ?tp)
      (not (at b0)) (at bl1)
      (not (k-right)) (k-left)
      (not (k-not-left)) (k-not-right)
    )
  )

  (:action pi_listen_b0_right
    :parameters (?t ?tp - tape)
    :precondition (and
      (not (done))
      (at b0)
      (tape-at ?t)
      (next ?t ?tp)
      (not (consumed ?t))
    )
    :effect (and
      (consumed ?t)
      (not (tape-at ?t)) (tape-at ?tp)
      (not (at b0)) (at br1)
      (not (k-left)) (k-right)
      (not (k-not-right)) (k-not-left)
    )
  )

  ;; --- bl1 ---
  (:action pi_listen_bl1_left
    :parameters (?t ?tp - tape)
    :precondition (and
      (not (done))
      (at bl1)
      (tape-at ?t)
      (next ?t ?tp)
      (not (consumed ?t))
    )
    :effect (and
      (consumed ?t)
      (not (tape-at ?t)) (tape-at ?tp)
      (not (at bl1)) (at bl2)
      (not (k-right)) (k-left)
      (not (k-not-left)) (k-not-right)
    )
  )

  (:action pi_listen_bl1_right
    :parameters (?t ?tp - tape)
    :precondition (and
      (not (done))
      (at bl1)
      (tape-at ?t)
      (next ?t ?tp)
      (not (consumed ?t))
    )
    :effect (and
      (consumed ?t)
      (not (tape-at ?t)) (tape-at ?tp)
      (not (at bl1)) (at b0)
      (not (k-left)) (k-right)
      (not (k-not-right)) (k-not-left)
    )
  )

  ;; --- bl2 ---
  (:action pi_listen_bl2_left
    :parameters (?t ?tp - tape)
    :precondition (and
      (not (done))
      (at bl2)
      (tape-at ?t)
      (next ?t ?tp)
      (not (consumed ?t))
    )
    :effect (and
      (consumed ?t)
      (not (tape-at ?t)) (tape-at ?tp)
      (not (at bl2)) (at bl3)
      (not (k-right)) (k-left)
      (not (k-not-left)) (k-not-right)
    )
  )

  (:action pi_listen_bl2_right
    :parameters (?t ?tp - tape)
    :precondition (and
      (not (done))
      (at bl2)
      (tape-at ?t)
      (next ?t ?tp)
      (not (consumed ?t))
    )
    :effect (and
      (consumed ?t)
      (not (tape-at ?t)) (tape-at ?tp)
      (not (at bl2)) (at bl1)
      (not (k-left)) (k-right)
      (not (k-not-right)) (k-not-left)
    )
  )

  ;; --- br1 ---
  (:action pi_listen_br1_right
    :parameters (?t ?tp - tape)
    :precondition (and
      (not (done))
      (at br1)
      (tape-at ?t)
      (next ?t ?tp)
      (not (consumed ?t))
    )
    :effect (and
      (consumed ?t)
      (not (tape-at ?t)) (tape-at ?tp)
      (not (at br1)) (at br2)
      (not (k-left)) (k-right)
      (not (k-not-right)) (k-not-left)
    )
  )

  (:action pi_listen_br1_left
    :parameters (?t ?tp - tape)
    :precondition (and
      (not (done))
      (at br1)
      (tape-at ?t)
      (next ?t ?tp)
      (not (consumed ?t))
    )
    :effect (and
      (consumed ?t)
      (not (tape-at ?t)) (tape-at ?tp)
      (not (at br1)) (at b0)
      (not (k-right)) (k-left)
      (not (k-not-left)) (k-not-right)
    )
  )

  ;; --- br2 ---
  (:action pi_listen_br2_right
    :parameters (?t ?tp - tape)
    :precondition (and
      (not (done))
      (at br2)
      (tape-at ?t)
      (next ?t ?tp)
      (not (consumed ?t))
    )
    :effect (and
      (consumed ?t)
      (not (tape-at ?t)) (tape-at ?tp)
      (not (at br2)) (at br3)
      (not (k-left)) (k-right)
      (not (k-not-right)) (k-not-left)
    )
  )

  (:action pi_listen_br2_left
    :parameters (?t ?tp - tape)
    :precondition (and
      (not (done))
      (at br2)
      (tape-at ?t)
      (next ?t ?tp)
      (not (consumed ?t))
    )
    :effect (and
      (consumed ?t)
      (not (tape-at ?t)) (tape-at ?tp)
      (not (at br2)) (at br1)
      (not (k-right)) (k-left)
      (not (k-not-left)) (k-not-right)
    )
  )

  ;; ===================================================================
  ;; BELIEF COMMITMENT
  ;;
  ;; These are the ONLY achievers of belief-committed.
  ;; commit-belief-left requires k-left (SAS+ var value 0)
  ;; commit-belief-right requires k-right (SAS+ var value 1)
  ;;
  ;; Since k-left and k-right are in the SAME SAS+ variable (mutex),
  ;; lm_rhw should generate {k-left, k-right} as a disjunctive landmark
  ;; the same way it generates {at(bl1), at(br1)}.
  ;;
  ;; CRITICAL: These actions must have k-left/k-right as their ONLY
  ;; differing precondition. No at() precondition here — that would
  ;; make the algorithm prefer the at() disjunction over the k- one.
  ;; ===================================================================

  (:action commit-belief-left
    :precondition (and (k-left) (not (belief-committed)))
    :effect (belief-committed)
  )

  (:action commit-belief-right
    :precondition (and (k-right) (not (belief-committed)))
    :effect (belief-committed)
  )

  ;; ===================================================================
  ;; DOOR OPENING
  ;; ===================================================================

  (:action pi_open_right_from_bl3
    :precondition (and
      (at bl3)
      (k-left)
      (k-not-right)
      (belief-committed)
      (not (done))
    )
    :effect (and
      (not (at bl3)) (at b0)

      (when (k0) (and (not (k0)) (k1)))
      (when (k1) (and (not (k1)) (k2)))
      (when (k2) (and (not (k2)) (k3)))
      (when (k3) (and (not (k3)) (k4)))
      (when (k4) (and (not (k4)) (k5)))
      (when (k5) (and (not (k5)) (k6)))

      (not (k-left)) (not (k-right))
      (not (k-not-left)) (not (k-not-right))
      (not (belief-committed))
    )
  )

  (:action pi_open_left_from_br3
    :precondition (and
      (at br3)
      (k-right)
      (k-not-left)
      (belief-committed)
      (not (done))
    )
    :effect (and
      (not (at br3)) (at b0)

      (when (k0) (and (not (k0)) (k1)))
      (when (k1) (and (not (k1)) (k2)))
      (when (k2) (and (not (k2)) (k3)))
      (when (k3) (and (not (k3)) (k4)))
      (when (k4) (and (not (k4)) (k5)))
      (when (k5) (and (not (k5)) (k6)))

      (not (k-left)) (not (k-right))
      (not (k-not-left)) (not (k-not-right))
      (not (belief-committed))
    )
  )

  ;; ===================================================================
  ;; TAG CONFIRMATION — gated behind belief-committed
  ;; ===================================================================

  (:action check-tiger-via-belief
    :parameters (?g - tag)
    :precondition (and
      (not (done))
      (belief-committed)
      (not (confirmed ?g))
    )
    :effect (confirmed ?g)
  )

  (:action confirm-all-tags
    :precondition (and
      (confirmed tagL)
      (confirmed tagR)
      (not (tiger-confirmed))
      (belief-committed)
    )
    :effect (tiger-confirmed)
  )

  ;; ===================================================================
  ;; FINISH
  ;; ===================================================================

  (:action finish
    :precondition (k6)
    :effect (done)
  )
)
