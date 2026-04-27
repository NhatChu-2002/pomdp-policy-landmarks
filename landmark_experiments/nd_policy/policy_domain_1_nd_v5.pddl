(define (domain tiger-policy-fsc-nd)
  (:requirements :strips :adl :negative-preconditions :typing)

  (:types node tape tag)

  (:predicates
    (at ?n - node)

    (k0) (k1) (k2) (k3) (k4) (k5) (k6)

    (tape-at ?t - tape)
    (next ?t ?tp - tape)
    (consumed ?t - tape)

    ;; Intermediate belief lean (set during listen, does NOT directly
    ;; gate door-opening or tag confirmation)
    (lean-left)
    (lean-right)

    ;; Committed belief (set ONLY at terminal nodes bl3/br3)
    ;; These are the facts we want as a disjunctive landmark
    (k-left)
    (k-right)

    (k-not-left)
    (k-not-right)

    (tiger-left ?g - tag)
    (tiger-right ?g - tag)

    (confirmed ?g - tag)

    (tiger-confirmed)
    (done)

    ;; Auxiliary for the disjunctive landmark chain
    (belief-committed)
  )

  ;; ===================================================================
  ;; LISTEN actions — set lean-left / lean-right (NOT k-left / k-right)
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
      (not (lean-right)) (lean-left)
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
      (not (lean-left)) (lean-right)
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
      (not (lean-right)) (lean-left)
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
      (not (lean-left)) (lean-right)
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
      (not (lean-right)) (lean-left)
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
      (not (lean-left)) (lean-right)
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
      (not (lean-left)) (lean-right)
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
      (not (lean-right)) (lean-left)
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
      (not (lean-left)) (lean-right)
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
      (not (lean-right)) (lean-left)
    )
  )

  ;; ===================================================================
  ;; BELIEF CRYSTALLIZATION — only at terminal nodes
  ;;
  ;; k-left is achievable ONLY at bl3 (requires at(bl3) + lean-left)
  ;; k-right is achievable ONLY at br3 (requires at(br3) + lean-right)
  ;;
  ;; In the RPG:
  ;;   at(bl3) first appears at layer 3 (b0->bl1->bl2->bl3)
  ;;   at(br3) first appears at layer 3 (b0->br1->br2->br3)
  ;;   k-left first appears at layer 4 (needs at(bl3))
  ;;   k-right first appears at layer 4 (needs at(br3))
  ;;
  ;; So when lm_rhw backward-chains from belief-committed:
  ;;   commit-belief-left needs k-left (only achiever: crystallize-left at bl3)
  ;;   commit-belief-right needs k-right (only achiever: crystallize-right at br3)
  ;;   => {k-left, k-right} is a disjunctive landmark
  ;; ===================================================================

  (:action crystallize-belief-left
    :precondition (and
      (at bl3)
      (lean-left)
      (not (k-left))
    )
    :effect (and
      (k-left)
      (k-not-right)
    )
  )

  (:action crystallize-belief-right
    :precondition (and
      (at br3)
      (lean-right)
      (not (k-right))
    )
    :effect (and
      (k-right)
      (k-not-left)
    )
  )

  ;; ===================================================================
  ;; BELIEF COMMITMENT — produces the disjunctive landmark target
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
  ;; DOOR OPENING — requires crystallized belief
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
      (not (lean-left)) (not (lean-right))
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
      (not (lean-left)) (not (lean-right))
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
