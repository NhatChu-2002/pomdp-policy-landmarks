(define (problem channel-policy-run)
  (:domain channel-policy-fsc)

  (:objects
    nroot nc1s nc2s nc3s ncommit - node

    t0 t1 t2 t3 t4 t5 t6 t7 t8 t9
    t10 t11 t12 t13 t14 t15 t16 t17 t18 t19
    t20 t21 t22 t23 t24 t25 t26 t27 t28 t29 t30 - tape

    c1 c2 c3 - channel
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

    ;; FSC transition topology
    (trans-signal nroot c1 nc1s)
    (trans-signal nroot c2 nc2s)
    (trans-signal nroot c3 nc3s)
    (trans-noise  nroot c1 nc2s)
    (trans-noise  nroot c2 nc3s)
    (trans-noise  nroot c3 nc1s)

    (trans-signal nc1s c1 ncommit)
    (trans-noise  nc1s c1 nroot)
    (trans-signal nc1s c2 nroot)
    (trans-noise  nc1s c2 nroot)
    (trans-signal nc1s c3 nroot)
    (trans-noise  nc1s c3 nroot)

    (trans-signal nc2s c2 ncommit)
    (trans-noise  nc2s c2 nroot)
    (trans-signal nc2s c1 nroot)
    (trans-noise  nc2s c1 nroot)
    (trans-signal nc2s c3 nroot)
    (trans-noise  nc2s c3 nroot)

    (trans-signal nc3s c3 ncommit)
    (trans-noise  nc3s c3 nroot)
    (trans-signal nc3s c1 nroot)
    (trans-noise  nc3s c1 nroot)
    (trans-signal nc3s c2 nroot)
    (trans-noise  nc3s c2 nroot)

    ;; commit node and reset arc
    (commit-node ncommit)
    (reset-arc ncommit nroot)
  )

  (:goal (and
    (done)
    (identification-done)
  ))
)
