(define (domain tiger-policy-fsc-nd)
  (:requirements :strips :adl :negative-preconditions :typing)

  (:types node tape tag direction)

  (:predicates
    (at ?n - node)

    (k0) (k1) (k2) (k3) (k4) (k5) (k6)

    (tape-at ?t - tape)
    (next ?t ?tp - tape)
    (consumed ?t - tape)

    (k ?d - direction)

    (k-not ?d - direction)

    (tiger-left ?g - tag)
    (tiger-right ?g - tag)

    (confirmed ?g - tag)

    (tiger-confirmed)
    (done)

    (belief-committed)

    (negbelief-committed)
  )

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
      (not (k right)) (k left)
      (not (k-not left)) (k-not right)
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
      (not (k left)) (k right)
      (not (k-not right)) (k-not left)
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
      (not (k right)) (k left)
      (not (k-not left)) (k-not right)
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
      (not (k left)) (k right)
      (not (k-not right)) (k-not left)
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
      (not (k right)) (k left)
      (not (k-not left)) (k-not right)
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
      (not (k left)) (k right)
      (not (k-not right)) (k-not left)
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
      (not (k left)) (k right)
      (not (k-not right)) (k-not left)
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
      (not (k right)) (k left)
      (not (k-not left)) (k-not right)
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
      (not (k left)) (k right)
      (not (k-not right)) (k-not left)
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
      (not (k right)) (k left)
      (not (k-not left)) (k-not right)
    )
  )

  ;; ===================================================================
  ;; BELIEF COMMITMENT — generates disj {k(left), k(right)}
  ;; ===================================================================

  (:action commit-belief-left
    :precondition (and (k left) (not (belief-committed)))
    :effect (belief-committed)
  )

  (:action commit-belief-right
    :precondition (and (k right) (not (belief-committed)))
    :effect (belief-committed)
  )

  ;; ===================================================================
  ;; NEG-BELIEF COMMITMENT — generates disj {k-not(left), k-not(right)}
  ;; ===================================================================

  (:action commit-negbelief-left
    :precondition (and (k-not left) (not (negbelief-committed)))
    :effect (negbelief-committed)
  )

  (:action commit-negbelief-right
    :precondition (and (k-not right) (not (negbelief-committed)))
    :effect (negbelief-committed)
  )

  ;; ===================================================================
  ;; DOOR OPENING — requires both commitments
  ;; ===================================================================

  (:action pi_open_right_from_bl3
    :precondition (and
      (at bl3)
      (k left)
      (k-not right)
      (belief-committed)
      (negbelief-committed)
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

      (not (k left)) (not (k right))
      (not (k-not left)) (not (k-not right))
      (not (belief-committed))
      (not (negbelief-committed))
    )
  )

  (:action pi_open_left_from_br3
    :precondition (and
      (at br3)
      (k right)
      (k-not left)
      (belief-committed)
      (negbelief-committed)
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

      (not (k left)) (not (k right))
      (not (k-not left)) (not (k-not right))
      (not (belief-committed))
      (not (negbelief-committed))
    )
  )


  (:action check-tiger-via-belief
    :parameters (?g - tag)
    :precondition (and
      (not (done))
      (belief-committed)
      (negbelief-committed)
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
      (negbelief-committed)
    )
    :effect (tiger-confirmed)
  )


  (:action finish
    :precondition (k6)
    :effect (done)
  )
)
