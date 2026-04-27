(define (domain tiger-policy-fsc-nd)
  (:requirements :strips :adl :negative-preconditions :typing)

  (:types node tape tag direction)

  (:predicates
    (at ?n - node)

    (k0) (k1) (k2) (k3) (k4) (k5) (k6)

    (tape-at ?t - tape)
    (next ?t ?tp - tape)
    (consumed ?t - tape)

    ;; Belief direction as a parameterized predicate.
    ;; FD will translate belief-is(dir-left) and belief-is(dir-right)
    ;; into values of ONE multi-valued SAS+ variable, just like
    ;; at(b0), at(bl1), etc. are values of var36.
    (belief-is ?d - direction)

    (k-not-left)
    (k-not-right)

    (tiger-left ?g - tag)
    (tiger-right ?g - tag)

    (confirmed ?g - tag)

    (tiger-confirmed)
    (done)

    (belief-committed)
  )

  ;; ===================================================================
  ;; LISTEN actions — set belief-is as mutex (exactly one direction)
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
      (not (belief-is dir-right)) (belief-is dir-left)
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
      (not (belief-is dir-left)) (belief-is dir-right)
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
      (not (belief-is dir-right)) (belief-is dir-left)
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
      (not (belief-is dir-left)) (belief-is dir-right)
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
      (not (belief-is dir-right)) (belief-is dir-left)
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
      (not (belief-is dir-left)) (belief-is dir-right)
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
      (not (belief-is dir-left)) (belief-is dir-right)
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
      (not (belief-is dir-right)) (belief-is dir-left)
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
      (not (belief-is dir-left)) (belief-is dir-right)
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
      (not (belief-is dir-right)) (belief-is dir-left)
      (not (k-not-left)) (k-not-right)
    )
  )

  ;; ===================================================================
  ;; BELIEF COMMITMENT
  ;;
  ;; commit-belief-left:  precondition belief-is(dir-left)  [same SAS+ var, value X]
  ;; commit-belief-right: precondition belief-is(dir-right) [same SAS+ var, value Y]
  ;;
  ;; Since both are values of the same variable, lm_rhw will generate
  ;; {belief-is(dir-left), belief-is(dir-right)} as a disjunctive landmark,
  ;; just like it generates {at(bl1), at(br1)}.
  ;; ===================================================================

  (:action commit-belief-left
    :precondition (and (belief-is dir-left) (not (belief-committed)))
    :effect (belief-committed)
  )

  (:action commit-belief-right
    :precondition (and (belief-is dir-right) (not (belief-committed)))
    :effect (belief-committed)
  )

  ;; ===================================================================
  ;; DOOR OPENING
  ;; ===================================================================

  (:action pi_open_right_from_bl3
    :precondition (and
      (at bl3)
      (belief-is dir-left)
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

      (not (belief-is dir-left)) (not (belief-is dir-right))
      (not (k-not-left)) (not (k-not-right))
      (not (belief-committed))
    )
  )

  (:action pi_open_left_from_br3
    :precondition (and
      (at br3)
      (belief-is dir-right)
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

      (not (belief-is dir-left)) (not (belief-is dir-right))
      (not (k-not-left)) (not (k-not-right))
      (not (belief-committed))
    )
  )

  ;; ===================================================================
  ;; TAG CONFIRMATION
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
