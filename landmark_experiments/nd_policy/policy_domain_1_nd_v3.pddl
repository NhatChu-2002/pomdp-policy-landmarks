(define (domain tiger-policy-fsc-nd)
  (:requirements :strips :adl :negative-preconditions :typing)

  (:types node tape tag)

  (:predicates
    (at ?n - node)

    (k0) (k1) (k2) (k3) (k4) (k5) (k6)

    (tape-at ?t - tape)
    (next ?t ?tp - tape)
    (consumed ?t - tape)

    (k-left)
    (k-right)

    (k-not-left)
    (k-not-right)

    (tiger-left ?g - tag)
    (tiger-right ?g - tag)

    (confirmed ?g - tag)

    (tiger-confirmed)
    (done)

    ;; Auxiliary: achieved when the agent has formed ANY belief
    ;; (either left or right). This is the disjunctive landmark target.
    (belief-formed)
  )

  ;; ===================================================================
  ;; LISTEN actions (nondeterministic: two outcomes per node)
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


  (:action form-belief-left
    :precondition (and (k-left) (not (belief-formed)))
    :effect (belief-formed)
  )

  (:action form-belief-right
    :precondition (and (k-right) (not (belief-formed)))
    :effect (belief-formed)
  )

  ;; ===================================================================
  ;; DOOR OPENING
  ;; ===================================================================

  (:action pi_open_right_from_bl3
    :precondition (and
      (at bl3)
      (k-left)
      (k-not-right)
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
      (not (belief-formed))
    )
  )

  (:action pi_open_left_from_br3
    :precondition (and
      (at br3)
      (k-right)
      (k-not-left)
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
      (not (belief-formed))
    )
  )

  ;; ===================================================================
  ;; TAG CONFIRMATION — unified via belief-formed
  ;;
  ;; Instead of separate check-tiger-left / check-tiger-right with
  ;; different belief preconditions (which makes k-left and k-right
  ;; each individually necessary), we use belief-formed as the gate.
  ;; This way, confirming a tag only needs "some belief was formed",
  ;; preserving the disjunctive nature.
  ;; ===================================================================

  (:action check-tiger-via-belief
    :parameters (?g - tag)
    :precondition (and
      (not (done))
      (belief-formed)
      (not (confirmed ?g))
    )
    :effect (confirmed ?g)
  )

  (:action confirm-all-tags
    :precondition (and
      (confirmed tagL)
      (confirmed tagR)
      (not (tiger-confirmed))
      (belief-formed)
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
