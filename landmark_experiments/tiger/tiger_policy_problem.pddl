(define (problem tiger_policy_run_nd)
  (:domain tiger_policy_fsc_nd)

  (:objects
    ;; FSC nodes derived from policy trace
    b0 bl3 bl2 bl1 br1 br2 br3 - node

    ;; Tape
    t0 t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 t11 t12 t13 t14 t15 t16 t17 t18 t19 t20 t21 t22 t23 t24 t25 t26 t27 t28 - tape

    ;; Tags
    tagL tagR - tag

    ;; Directions
    left right - direction
  )

  (:init
    (at b0)
    (k0)
    (tape-at t0)
    (next t0 t1)
    (next t1 t2)
    (next t2 t3)
    (next t3 t4)
    (next t4 t5)
    (next t5 t6)
    (next t6 t7)
    (next t7 t8)
    (next t8 t9)
    (next t9 t10)
    (next t10 t11)
    (next t11 t12)
    (next t12 t13)
    (next t13 t14)
    (next t14 t15)
    (next t15 t16)
    (next t16 t17)
    (next t17 t18)
    (next t18 t19)
    (next t19 t20)
    (next t20 t21)
    (next t21 t22)
    (next t22 t23)
    (next t23 t24)
    (next t24 t25)
    (next t25 t26)
    (next t26 t27)
    (next t27 t28)
    (tiger-left  tagL)
    (tiger-right tagR)
  )

  (:goal (and (done) (tiger-confirmed)))
)