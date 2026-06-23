(define (problem rocksample-policy-run)
  (:domain rocksample-policy-fsc)

  ;; ===================================================================
  ;; PROBLEM: RockSample (3 rocks) — sequential quality assessment
  ;;
  ;; FSC topology (8 nodes):
  ;;   nroot -(sense r1 good)-> nr1g
  ;;   nroot -(sense r1 bad) -> nr1b
  ;;   nr1g  -(sense r2 good)-> nr1g-r2g
  ;;   nr1g  -(sense r2 bad) -> nr1g-r2b
  ;;   nr1b  -(sense r2 good)-> nr1b-r2g
  ;;   nr1b  -(sense r2 bad) -> nr1b-r2b
  ;;   nr1g-r2g -(sense r3)-> ncommit
  ;;   nr1g-r2b -(sense r3)-> ncommit
  ;;   nr1b-r2g -(sense r3)-> ncommit
  ;;   nr1b-r2b -(sense r3)-> ncommit
  ;;
  ;; |Q| = 8, |S| = 8 (good/bad for each of 3 rocks = 2^3)
  ;; ===================================================================

  (:objects
    ;; FSC nodes
    nroot
    nr1g nr1b
    nr1g-r2g nr1g-r2b
    nr1b-r2g nr1b-r2b
    ncommit - node

    ;; Observation tape (30 steps, enough for multi-cycle execution)
    t0  t1  t2  t3  t4  t5  t6  t7  t8  t9
    t10 t11 t12 t13 t14 t15 t16 t17 t18 t19
    t20 t21 t22 t23 t24 t25 t26 t27 t28 t29 t30 - tape

    ;; Rocks and quality values
    r1 r2 r3 - rock
    good bad - quality
  )

  (:init
    (at nroot)
    (k0)
    (tape-at t0)

    ;; Tape chain
    (next t0  t1)  (next t1  t2)  (next t2  t3)  (next t3  t4)
    (next t4  t5)  (next t5  t6)  (next t6  t7)  (next t7  t8)
    (next t8  t9)  (next t9  t10) (next t10 t11) (next t11 t12)
    (next t12 t13) (next t13 t14) (next t14 t15) (next t15 t16)
    (next t16 t17) (next t17 t18) (next t18 t19) (next t19 t20)
    (next t20 t21) (next t21 t22) (next t22 t23) (next t23 t24)
    (next t24 t25) (next t25 t26) (next t26 t27) (next t27 t28)
    (next t28 t29) (next t29 t30)

    ;; Quality identity flags
    (good-quality good)
    (bad-quality  bad)

    ;; Rock identity flags
    (first-rock  r1)
    (second-rock r2)
    (third-rock  r3)

    ;; -------------------------------------------------------
    ;; FSC TRANSITION TABLE
    ;; Step 1: sense rock r1
    ;; -------------------------------------------------------
    (trans-good nroot r1 nr1g)
    (trans-bad  nroot r1 nr1b)

    ;; Step 2: sense rock r2 (from either r1 branch)
    (trans-good nr1g  r2 nr1g-r2g)
    (trans-bad  nr1g  r2 nr1g-r2b)
    (trans-good nr1b  r2 nr1b-r2g)
    (trans-bad  nr1b  r2 nr1b-r2b)

    ;; Step 3: sense rock r3 (all branches converge to ncommit)
    (trans-good nr1g-r2g r3 ncommit)
    (trans-bad  nr1g-r2g r3 ncommit)
    (trans-good nr1g-r2b r3 ncommit)
    (trans-bad  nr1g-r2b r3 ncommit)
    (trans-good nr1b-r2g r3 ncommit)
    (trans-bad  nr1b-r2g r3 ncommit)
    (trans-good nr1b-r2b r3 ncommit)
    (trans-bad  nr1b-r2b r3 ncommit)

    ;; Commit node and reset arc (back to root for multi-cycle)
    (commit-node ncommit)
    (reset-arc   ncommit nroot)
  )

  (:goal (and
    (done)
    (assessment-confirmed)
  ))
)
