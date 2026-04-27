(define (problem minesweeper-policy-run)
  (:domain minesweeper-policy-fsc)

  (:objects
    ;; FSC nodes:
    ;;   nroot    : initial probe node
    ;;   nzero    : after obs "zero" (one candidate remains -> go to commit)
    ;;   none-ab  : after obs "one", candidates are {c00,c01}
    ;;   none-ac  : after obs "one", candidates are {c00,c10}
    ;;   none-bd  : after obs "one", candidates are {c01,c11}
    ;;   none-cd  : after obs "one", candidates are {c10,c11}
    ;;   nhit     : after hitting mine (reset immediately)
    ;;   ncommit  : commitment node
    nroot nzero none-ab none-ac none-bd none-cd nhit ncommit - node

    t0 t1 t2 t3 t4 t5 t6 t7 t8 t9
    t10 t11 t12 t13 t14 t15 t16 t17 t18 t19
    t20 t21 t22 t23 t24 t25 t26 t27 t28 t29 t30 - tape

    c00 c01 c10 c11 - cell
  )

  (:init
    (at nroot)
    (k0)
    (tape-at t0)

    (next t0  t1)  (next t1  t2)  (next t2  t3)  (next t3  t4)
    (next t4  t5)  (next t5  t6)  (next t6  t7)  (next t7  t8)
    (next t8  t9)  (next t9  t10) (next t10 t11) (next t11 t12)
    (next t12 t13) (next t13 t14) (next t14 t15) (next t15 t16)
    (next t16 t17) (next t17 t18) (next t18 t19) (next t19 t20)
    (next t20 t21) (next t21 t22) (next t22 t23) (next t23 t24)
    (next t24 t25) (next t25 t26) (next t26 t27) (next t27 t28)
    (next t28 t29) (next t29 t30)

    ;; Adjacency (2x2 fully connected)
    (adj c00 c01) (adj c00 c10) (adj c00 c11)
    (adj c01 c00) (adj c01 c10) (adj c01 c11)
    (adj c10 c00) (adj c10 c01) (adj c10 c11)
    (adj c11 c00) (adj c11 c01) (adj c11 c10)

    ;; ---- FSC TOPOLOGY ----
    ;; From nroot, probe any cell:
    ;;   obs "zero" at c00 -> only c11 survives -> nzero (k(c11) set by action)
    ;;   obs "zero" at c01 -> only c10 survives -> nzero
    ;;   obs "zero" at c10 -> only c01 survives -> nzero
    ;;   obs "zero" at c11 -> only c00 survives -> nzero
    (trans-zero nroot c00 nzero)
    (trans-zero nroot c01 nzero)
    (trans-zero nroot c10 nzero)
    (trans-zero nroot c11 nzero)

    ;;   obs "one" at c00 -> candidates {c01,c10} or {c01,c11} or {c10,c11}
    ;;   We encode two representative branches:
    (trans-one nroot c00 none-ab)   ;; candidates {c00,c01} remain
    (trans-one nroot c01 none-ac)   ;; candidates {c00,c10} remain
    (trans-one nroot c10 none-bd)   ;; candidates {c01,c11} remain
    (trans-one nroot c11 none-cd)   ;; candidates {c10,c11} remain

    ;;   obs "hit" at any cell -> nhit (reset)
    (trans-hit nroot c00 nhit)
    (trans-hit nroot c01 nhit)
    (trans-hit nroot c10 nhit)
    (trans-hit nroot c11 nhit)

    ;; From none-* nodes: second probe narrows to 1 candidate -> ncommit
    ;;   or hit -> nhit
    (trans-zero none-ab c00 ncommit)
    (trans-zero none-ab c01 ncommit)
    (trans-hit  none-ab c00 nhit)
    (trans-hit  none-ab c01 nhit)

    (trans-zero none-ac c00 ncommit)
    (trans-zero none-ac c10 ncommit)
    (trans-hit  none-ac c00 nhit)
    (trans-hit  none-ac c10 nhit)

    (trans-zero none-bd c01 ncommit)
    (trans-zero none-bd c11 ncommit)
    (trans-hit  none-bd c01 nhit)
    (trans-hit  none-bd c11 nhit)

    (trans-zero none-cd c10 ncommit)
    (trans-zero none-cd c11 ncommit)
    (trans-hit  none-cd c10 nhit)
    (trans-hit  none-cd c11 nhit)

    ;; nhit is a commit node (reset from here)
    (commit-node nhit)
    (reset-arc nhit nroot)

    ;; ncommit is the main commit node
    (commit-node ncommit)
    (reset-arc ncommit nroot)

    ;; nzero also goes straight to commit (obs "zero" resolves everything)
    (commit-node nzero)
    (reset-arc nzero nroot)
  )

  (:goal (and
    (done)
    (mine-located)
  ))
)
