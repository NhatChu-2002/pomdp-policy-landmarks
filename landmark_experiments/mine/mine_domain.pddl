(define (domain minesweeper-policy-fsc)
  (:requirements :strips :adl :negative-preconditions :typing)

  ;; ===================================================================
  ;; DOMAIN: Minesweeper (2x2 grid)
  ;;
  ;; Hidden state: exactly one of four cells contains a mine.
  ;; The agent probes cells and receives a count observation:
  ;;   "zero"  — no mines adjacent to probed cell  (rules out multiple cells)
  ;;   "one"   — one mine adjacent                 (partial information)
  ;;   "hit"   — probed cell itself is the mine    (terminal, reset)
  ;;
  ;; Belief predicates (k-pattern):
  ;;   k(?cell)     — believe mine is at this cell
  ;;   k-not(?cell) — believe mine is NOT at this cell
  ;;
  ;; Key design: asymmetric observations. Probing the center cell with
  ;; obs "zero" rules out ALL four cells simultaneously — impossible, so
  ;; only corner probes are modelled. Probing cell X with obs "zero"
  ;; rules out X and all its neighbors, potentially eliminating 2-3
  ;; cells at once. This produces asymmetric disjunctions depending on
  ;; which cell was probed first.
  ;;
  ;; Grid layout:
  ;;   c00 c01
  ;;   c10 c11
  ;; Adjacency: c00 adj {c01,c10,c11}, c01 adj {c00,c10,c11}, etc.
  ;; (fully connected 2x2 — every cell is adjacent to every other)
  ;;
  ;; Commitment gate:
  ;;   mine-committed  — requires k(?cell) for some cell
  ;;   neg-mine-committed     — requires k-not(?cell) for some cell
  ;; Both required before mine-located can fire.
  ;; ===================================================================

  (:types node tape cell)

  (:predicates
    (at ?n - node)
    (tape-at ?t - tape)
    (next ?t ?tp - tape)
    (consumed ?t - tape)

    (k0) (k1) (k2) (k3) (k4) (k5) (k6) (k7) (k8)

    ;; FSC topology
    (trans-zero ?n - node ?c - cell ?m - node)
    (trans-one  ?n - node ?c - cell ?m - node)
    (trans-hit  ?n - node ?c - cell ?m - node)
    (commit-node ?n - node)
    (reset-arc ?n - node ?m - node)

    ;; Adjacency (used to determine how many cells obs "zero" rules out)
    (adj ?ca ?cb - cell)

    (k     ?c - cell)    ;; believe mine is at cell c
    (k-not ?c - cell)    ;; believe mine is NOT at cell c

    ;; Commitment gates
    (mine-committed)
    (neg-mine-committed)

    (resetting)

    ;; Goal tracking
    (cell-cleared ?c - cell)
    (all-cells-cleared)
    (mine-located)
    (done)
  )

  ;; ---------------------------------------------------------------
  ;; PROBE: obs = "zero" — probed cell AND all its neighbors are safe
  ;; Sets k-not for the probed cell and all adjacent cells.
  ;; Sets k for the one remaining cell (the only candidate left).
  ;; This is the ASYMMETRIC case: one observation eliminates 3+ cells.
  ;; Parameters: ?cp = probed cell, ?cr = remaining candidate
  ;; (only valid when probing ?cp with "zero" leaves exactly ?cr)
  ;; ---------------------------------------------------------------
  (:action probe-zero
    :parameters (?n ?m - node ?cp ?cr - cell ?t ?tp - tape)
    :precondition (and
      (not (done)) (not (resetting))
      (at ?n) (tape-at ?t) (next ?t ?tp) (not (consumed ?t))
      (trans-zero ?n ?cp ?m)
      (not (= ?cp ?cr))
    )
    :effect (and
      (consumed ?t) (not (tape-at ?t)) (tape-at ?tp)
      (not (at ?n)) (at ?m)
      ;; "zero" near ?cp means ?cp is safe AND neighbors are safe.
      ;; In a 2x2 fully-connected grid, probing any cell with "zero"
      ;; rules out that cell and its 3 neighbors = all cells.
      ;; So this obs is only valid if we model it as:
      ;; k-not(?cp) set, k(?cr) set (the one cell not ruled out by ?cp's probe)
      ;; The trans-zero arc in the problem encodes which ?cr survives.
      (k ?cr)
      (not (k-not ?cr))
      (k-not ?cp)
    )
  )

  ;; PROBE: obs = "one" — one adjacent cell has a mine, narrows to 2 candidates
  ;; Parameters: ?cp = probed cell, ?ca ?cb = the two remaining candidates
  (:action probe-one
    :parameters (?n ?m - node ?cp ?ca ?cb - cell ?t ?tp - tape)
    :precondition (and
      (not (done)) (not (resetting))
      (at ?n) (tape-at ?t) (next ?t ?tp) (not (consumed ?t))
      (trans-one ?n ?cp ?m)
      (not (= ?cp ?ca)) (not (= ?cp ?cb)) (not (= ?ca ?cb))
    )
    :effect (and
      (consumed ?t) (not (tape-at ?t)) (tape-at ?tp)
      (not (at ?n)) (at ?m)
      ;; "one" near ?cp: ?cp itself is safe, mine is in {?ca, ?cb}
      (k ?ca)
      (not (k ?cb))
      (not (k-not ?ca)) (k-not ?cp) (k-not ?cb)
    )
  )

  ;; PROBE: obs = "hit" — probed the mine directly, must reset
  (:action probe-hit
    :parameters (?n ?m - node ?cp - cell ?t ?tp - tape)
    :precondition (and
      (not (done)) (not (resetting))
      (at ?n) (tape-at ?t) (next ?t ?tp) (not (consumed ?t))
      (trans-hit ?n ?cp ?m)
    )
    :effect (and
      (consumed ?t) (not (tape-at ?t)) (tape-at ?tp)
      (not (at ?n)) (at ?m)
      ;; Hit: we know where mine was, but must restart (penalty)
      ;; Clear all belief — handled by reset sequence
      (resetting)
    )
  )

  ;; ---------------------------------------------------------------
  ;; COMMITMENT GATES
  ;; mine-committed  : disj{k(c00), k(c01), k(c10), k(c11)}
  ;; neg-mine-committed     : disj{k-not(c00), k-not(c01), ...}
  ;; ---------------------------------------------------------------
  (:action commit-mine
    :parameters (?c - cell)
    :precondition (and (k ?c) (not (mine-committed)) (not (resetting)))
    :effect (mine-committed)
  )

  (:action commit-neg-mine
    :parameters (?c - cell)
    :precondition (and (k-not ?c) (not (neg-mine-committed)) (not (resetting)))
    :effect (neg-mine-committed)
  )

  ;; ---------------------------------------------------------------
  ;; CELL CLEARANCE + MINE LOCATION
  ;; ---------------------------------------------------------------
  (:action clear-cell
    :parameters (?n - node ?c - cell)
    :precondition (and
      (not (done)) (at ?n) (commit-node ?n)
      (mine-committed) (neg-mine-committed) (not (resetting))
      (not (cell-cleared ?c))
    )
    :effect (cell-cleared ?c)
  )

  (:action set-all-cleared
    :parameters (?n - node ?ca ?cb ?cc ?cd - cell)
    :precondition (and
      (at ?n) (commit-node ?n) (not (resetting))
      (not (= ?ca ?cb)) (not (= ?ca ?cc)) (not (= ?ca ?cd))
      (not (= ?cb ?cc)) (not (= ?cb ?cd)) (not (= ?cc ?cd))
      (cell-cleared ?ca) (cell-cleared ?cb)
      (cell-cleared ?cc) (cell-cleared ?cd)
      (not (all-cells-cleared))
    )
    :effect (all-cells-cleared)
  )

  (:action locate-mine
    :parameters (?n - node)
    :precondition (and
      (at ?n) (commit-node ?n) (not (resetting))
      (all-cells-cleared) (not (mine-located))
      (mine-committed) (neg-mine-committed)
    )
    :effect (mine-located)
  )

  ;; ---------------------------------------------------------------
  ;; RESET SEQUENCE
  ;; ---------------------------------------------------------------
  (:action begin-reset
    :parameters (?n ?m - node)
    :precondition (and
      (at ?n) (commit-node ?n)
      (mine-committed) (neg-mine-committed)
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
    :parameters (?c - cell)
    :precondition (and (resetting) (k ?c))
    :effect (not (k ?c))
  )

  (:action clear-k-not
    :parameters (?c - cell)
    :precondition (and (resetting) (k-not ?c))
    :effect (not (k-not ?c))
  )

  (:action clear-mine-gate
    :precondition (and (resetting) (mine-committed))
    :effect (not (mine-committed))
  )

  (:action clear-neg-mine-gate
    :precondition (and (resetting) (neg-mine-committed))
    :effect (not (neg-mine-committed))
  )

  (:action end-reset
    :precondition (and
      (resetting)
      (not (mine-committed))
      (not (neg-mine-committed))
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
