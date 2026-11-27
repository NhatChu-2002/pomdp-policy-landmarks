"""Fast checks for the pipeline. Run from the repository root:

    python -m pytest tests          (or: python tests/test_pipeline.py)
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from policy_landmarks.domains import HAND_WRITTEN  # noqa: E402
from policy_landmarks.encoder import compile_to_pddl  # noqa: E402
from policy_landmarks.ground_truth import Task  # noqa: E402
from policy_landmarks.planner import FAST_DOWNWARD, graph, run_spec, show  # noqa: E402

TOY_SAS = "\n".join([   # one variable s0 -> a -> b, goal b
    "begin_version", "3", "end_version", "begin_metric", "0", "end_metric", "1",
    "begin_variable", "var0", "-1", "3", "Atom s0()", "Atom a()", "Atom b()",
    "end_variable", "0", "begin_state", "0", "end_state", "begin_goal", "1", "0 2",
    "end_goal", "2",
    "begin_operator", "go-a", "0", "1", "0 0 0 1", "1", "end_operator",
    "begin_operator", "go-b", "0", "1", "0 0 1 2", "1", "end_operator", "0"])


def test_ground_truth_on_toy_task(tmp_path=None):
    sas = Path(tmp_path or ROOT / "experiments" / "results" / "work") / "toy.sas"
    sas.parent.mkdir(parents=True, exist_ok=True)
    sas.write_text(TOY_SAS)
    task = Task(sas)
    assert task.is_landmark({"Atom a()"}) and task.is_landmark({"Atom b()"})
    assert task.order_holds({"Atom a()"}, {"Atom b()"})
    assert not task.order_holds({"Atom b()"}, {"Atom a()"})


def test_encoder_commits_only_through_policy_rules():
    spec = HAND_WRITTEN["tiger"]()
    domain, _ = compile_to_pddl(spec)
    assert domain.count("(:action commit-") == len(spec.commit_conditions)
    assert "neg-commit" not in domain and "confirm" not in domain


def test_well_formedness_rejects_sign_flip():
    from policy_landmarks.spec import BSCTransition, BeliefRef, BeliefUpdate
    spec = HAND_WRITTEN["tiger"]()
    # leaning left + growl right jumps straight to leaning right: adds k(right) while k(left) holds
    spec.transitions.append(BSCTransition(
        "right", (BeliefRef("direction", "left", "pos", holds=True),),
        (BeliefUpdate("direction", "right", "pos"),),
        (BeliefUpdate("direction", "left", "pos"),)))
    try:
        compile_to_pddl(spec)
    except ValueError:
        return
    raise AssertionError("malformed controller was compiled")


def test_landmarks_differ_between_policies(tmp_path=None):
    if not (FAST_DOWNWARD.parent / "builds" / "release64").exists():
        import pytest
        pytest.skip("Fast Downward build not found")
    work = Path(tmp_path or ROOT / "experiments" / "results" / "work" / "tests")
    tiger, _ = graph(run_spec(work / "tiger", HAND_WRITTEN["tiger"]())["parsed"])
    channel, _ = graph(run_spec(work / "channel", HAND_WRITTEN["channel"]())["parsed"])
    assert len(tiger) == 7 and len(channel) == 6
    assert any("k-not-direction" in show(k) for k in tiger)      # Tiger rules out a door
    assert not any("k-not-channel" in show(k) for k in channel)  # Channel commits at once


if __name__ == "__main__":
    for test in (test_ground_truth_on_toy_task, test_encoder_commits_only_through_policy_rules,
                 test_well_formedness_rejects_sign_flip, test_landmarks_differ_between_policies):
        test()
        print("ok", test.__name__)


def test_first_hit_geometric_chain():
    """Root loops on itself with p=0.5 and ends otherwise: P(end)=1, E[steps]=2."""
    from policy_landmarks.extraction import first_hit
    g = {"nodes": [{"id": 0, "kind": "inner"}, {"id": 1, "kind": "commit_end"}],
         "edges": [{"from": 0, "to": 0, "p": 0.5}, {"from": 0, "to": 1, "p": 0.5}]}
    p, steps = first_hit(g, {1: 1.0})
    assert abs(p - 1) < 1e-9 and abs(steps - 2) < 1e-6
    assert first_hit(g, {0: 1.0}) == (1.0, 0.0)          # target holds at the root


def test_p_end_within_geometric_chain():
    from policy_landmarks.extraction import p_end_within
    g = {"nodes": [{"id": 0, "kind": "inner"}, {"id": 1, "kind": "commit_end"}],
         "edges": [{"from": 0, "to": 0, "p": 0.5}, {"from": 0, "to": 1, "p": 0.5}]}
    assert abs(p_end_within(g, 3) - 0.875) < 1e-12


def test_exact_engine_on_a_toy_controller():
    """unk -> pos1 | neg1 -> end: the disjunction is the only belief landmark, ordered before done."""
    from policy_landmarks.exact import StateGraph, closure
    F = frozenset
    unk, pos, neg = F({"ev-x(unk)"}), F({"ev-x(pos1)"}), F({"ev-x(neg1)"})
    ctrl = {"init": unk, "commits": {(pos, "open-a")},
            "edges": {(unk, "look", "a", pos, F()), (unk, "look", "b", neg, F()),
                      (neg, "leave", "none", F({"terminal"}), F())}}
    sg = StateGraph(ctrl)
    lms = set(sg.landmarks())
    disj, done = F({"ev-x(pos1)", "ev-x(neg1)"}), F({"done"})
    assert lms == {disj, done}
    order = sg.orderings(list(lms))
    assert order == {(disj, done): {"nat", "gn"}}
    assert not sg.is_landmark(["chose(open-a)"])          # only the pos branch commits
    assert closure({(1, 2), (2, 3)}) == {(1, 2), (2, 3), (1, 3)}


def test_empirical_landmarks_and_avoid_probability():
    """Root -> A (p=0.9) or B (p=0.1) -> end. 'A' survives only runs that miss B."""
    import random
    from policy_landmarks import sampling
    F = frozenset
    g = {"problem": "toy",
         "nodes": [{"id": 0, "kind": "inner", "action": "x"}, {"id": 1, "kind": "inner", "action": "x"},
                   {"id": 2, "kind": "inner", "action": "x"}, {"id": 3, "kind": "terminal", "action": None}],
         "edges": [{"from": 0, "to": 1, "p": 0.9, "obs": "a"}, {"from": 0, "to": 2, "p": 0.1, "obs": "b"},
                   {"from": 1, "to": 3, "p": 1.0, "obs": "n"}, {"from": 2, "to": 3, "p": 1.0, "obs": "n"}]}
    ctrl = {"node_state": {0: F({"s(r)"}), 1: F({"s(a)"}), 2: F({"s(b)"}), 3: F({"terminal"})}}
    runs = [sampling.run_facts(g, ctrl, random.Random(k)) for k in range(200)]
    assert all("done" in r for r in runs)
    emp = sampling.empirical_landmarks(runs, F({"s(r)"}))
    assert F({"s(a)", "s(b)"}) in emp and F({"done"}) in emp
    assert abs(sampling.avoid_probability(g, ctrl, F({"s(a)"})) - 0.1) < 1e-9


def test_symbolic_controller_is_sound_on_a_threshold_policy():
    """Tiger with two hand-made alpha-vector families: listen near the middle, open a
    door beyond +-1.5 log-odds units. The abstract controller built from the vectors
    alone must make 'one net growl either way' a landmark."""
    import math
    from policy_landmarks import symbolic as sy
    from policy_landmarks.exact import StateGraph
    q = 0.8
    g = {"problem": "tiger", "p_correct": q, "states": ["left", "right"]}
    alphas = {"states": ["left", "right"], "actions": ["listen", "right", "left"],
              "alphas": [[0.0, 0.0], [10.0, -100.0], [-100.0, 10.0]]}
    m = sy.Model(g, alphas)
    ctrl = sy.abstract_controller(m, sy.unit_grid(m, 2))
    sg = StateGraph(ctrl)
    assert sg.is_landmark(["ev-direction(pos1)", "ev-direction(neg1)"])
    assert ctrl["commits"]                                  # some cell opens a door


def test_cegar_cell_split_keeps_every_policy_choice_covered():
    """After fine-cell splits, every belief's policy action must still be allowed by some
    rule whose box contains that belief (the rule task stays an over-approximation)."""
    import numpy as np
    from policy_landmarks import cegar, symbolic as sy
    g = {"problem": "tiger", "p_correct": 0.8, "states": ["left", "right"]}
    alphas = {"states": ["left", "right"], "actions": ["listen", "right", "left"],
              "alphas": [[0.0, 0.0], [10.0, -100.0], [-100.0, 10.0]]}
    m = sy.Model(g, alphas)
    grid, edges = sy.Grid([[-sy.INF, -3.0, -1.0, 1.0, 3.0, sy.INF]]), (-1.0, 1.0)
    rules = cegar.initial_rules(m, grid, [None], edges)
    assert cegar.split_cell(m, grid, rules, 0, 0.0, edges)
    assert cegar.split_cell(m, grid, rules, 0, 2.0, edges)
    assert not cegar.split_cell(m, grid, rules, 0, 2.0, edges)          # already an edge
    for x in np.linspace(-6, 6, 97):
        a = m.actions[int((m.A @ m.corner(None, [x])).argmax())]
        boxes = [cegar._box(m, assign, edges)[0] for _, ra, assign in rules if ra == a]
        assert any(lo <= x <= hi for lo, hi in boxes), x


def test_cegar_split_away_removes_the_spurious_box_and_keeps_policy_choices():
    """split_away must drop the spurious step's fine box from a rule and keep every
    belief of the rule's box where the policy picks the rule's action."""
    import json
    import random
    from policy_landmarks import cegar, extraction, symbolic as sy
    base = ROOT / "experiments/policy_graphs/alphas"
    g = extraction.load(base / "rocksample-4-4-s5.json")
    m = sy.Model(g, json.loads((base / "rocksample-4-4-s5.alphas.json").read_text()))
    grid, edges = sy.bin_grid(m, 0), (-4.5, 4.5)
    rng = random.Random(1)
    cells = [cegar._cells(grid, v) for v in range(len(m.vars))]
    rules = cegar.initial_rules(m, grid, [(1, 1), (2, 3)], edges, "any")
    checked = 0
    for pos, a, assign in rules:
        box = cegar._box(m, assign, edges)
        for _ in range(20):                                  # a fine box inside the rule's box
            fine = [rng.choice([c for c in cells[v] if box[v][0] <= c[0] and c[1] <= box[v][1]])
                    for v in range(len(m.vars))]
            if a not in m.possible_actions(pos, fine):
                break
        else:
            continue
        kids = cegar.split_away(m, grid, (pos, a, assign), fine, edges)
        mid = [(lo + hi) / 2 if abs(lo) < 1e9 and abs(hi) < 1e9 else (lo + 1 if abs(lo) < 1e9 else hi - 1)
               for lo, hi in fine]                       # an interior point of the fine box
        assert not any(all(lo <= x <= hi for x, (lo, hi) in zip(mid, cegar._box(m, k[2], edges))) for k in kids)
        for _ in range(200):
            x = [rng.uniform(max(lo, -8), min(hi, 8)) for lo, hi in box]
            if m.actions[int((m.A @ m.corner(pos, x)).argmax())] == a:
                assert any(all(lo <= xi <= hi for xi, (lo, hi) in zip(x, cegar._box(m, k[2], edges)))
                           for k in kids), (pos, a, x)
        checked += 1
    assert checked >= 5


def test_cegar_region_proves_for_every_prior_and_refutes_with_a_witness_in_the_region(tmp_path=None):
    """Toy Tiger: the policy listens while |log-odds| < 2.3 and opens a door beyond it.
    Every prior in [-0.5, 0.5] starts in the cell [-1, 1), so the cell is a landmark for
    the whole region; from priors in [2.0, 2.2] one growl reaches 3.5 and the policy
    opens, so CEGAR must refute it with a witness prior inside the region that is a real
    counterexample on its exact belief graph."""
    if not (FAST_DOWNWARD.parent / "builds" / "release64").exists():
        import pytest
        pytest.skip("Fast Downward build not found")
    from policy_landmarks import cegar, symbolic as sy
    g = {"problem": "tiger", "p_correct": 0.8, "states": ["left", "right"]}
    alphas = {"states": ["left", "right"], "actions": ["listen", "right", "left"],
              "alphas": [[0.0, 0.0], [10.0, -100.0], [-100.0, 10.0]]}
    work = Path(tmp_path or ROOT / "experiments" / "results" / "work" / "tests") / "cegar-region"
    cand = {0: [(-1.0, 1.0)]}
    for region, expect in (((0.0, 0.0), True), ((-0.5, 0.5), True), ((2.0, 2.2), False)):
        m = sy.Model(g, alphas)
        grid, edges = sy.Grid([[-sy.INF, -3.0, -1.0, 1.0, 3.0, sy.INF]]), (-1.0, 1.0)
        rules = cegar.initial_rules(m, grid, [None], edges, "any")
        res = cegar.verify(m, grid, rules, cand, work, edges, region={0: region}, recheck=True)
        assert res["landmark"] is expect, (region, res)
        assert res.get("rechecked") is (True if expect else None), res     # blind search agrees
        blind = cegar.verify(m, grid, cegar.initial_rules(m, grid, [None], edges, "any"), cand, work,
                             edges, region={0: region}, search="astar(blind())")
        assert blind["landmark"] is expect, (region, blind)
        if not expect:
            assert res["certified"] and region[0] <= res["witness"][0] <= region[1]
            assert not cegar.exact_landmark(*cegar.exact_graph(m, res["witness"]), 0, cand[0])


def test_cegar_region_certifies_a_witness_that_lands_on_a_cell_edge(tmp_path=None):
    """Toy Tiger with a cell edge at exactly one growl (u): from the midpoint prior 0 the
    first replay lands exactly on that edge, whose cell the double-precision update
    decides, so the refutation must be certified."""
    if not (FAST_DOWNWARD.parent / "builds" / "release64").exists():
        import pytest
        pytest.skip("Fast Downward build not found")
    from policy_landmarks import cegar, symbolic as sy
    g = {"problem": "tiger", "p_correct": 0.8, "states": ["left", "right"]}
    alphas = {"states": ["left", "right"], "actions": ["listen", "right", "left"],
              "alphas": [[0.0, 0.0], [10.0, -100.0], [-100.0, 10.0]]}
    m = sy.Model(g, alphas)
    work = Path(tmp_path or ROOT / "experiments" / "results" / "work" / "tests") / "cegar-tie"
    grid, edges = sy.Grid([[-sy.INF, -3.0, -1.0, m.u, 3.0, sy.INF]]), (-1.0, 1.0)
    rules = cegar.initial_rules(m, grid, [None], edges, "any")
    cand = {0: [(-3.0, -1.0)]}                               # runs that growl right twice avoid it
    res = cegar.verify(m, grid, rules, cand, work, edges, region={0: (-0.5, 0.5)})
    assert res["landmark"] is False and res["certified"], res
    assert -0.5 <= res["witness"][0] <= 0.5
    assert not cegar.exact_landmark(*cegar.exact_graph(m, res["witness"]), 0, cand[0])


def test_cegar_region_includes_its_upper_end_point(tmp_path=None):
    """The region [-0.5, 1.0] is closed: the prior 1.0 starts in the cell [1, 3), and one
    growl from there reaches 2.39, where the policy opens a door without entering
    [-1, 1). A region open at its upper end would wrongly prove that cell a landmark."""
    if not (FAST_DOWNWARD.parent / "builds" / "release64").exists():
        import pytest
        pytest.skip("Fast Downward build not found")
    from policy_landmarks import cegar, symbolic as sy
    g = {"problem": "tiger", "p_correct": 0.8, "states": ["left", "right"]}
    m = sy.Model(g, {"states": ["left", "right"], "actions": ["listen", "right", "left"],
                     "alphas": [[0.0, 0.0], [10.0, -100.0], [-100.0, 10.0]]})
    work = Path(tmp_path or ROOT / "experiments" / "results" / "work" / "tests") / "cegar-closed"
    grid, edges = sy.Grid([[-sy.INF, -3.0, -1.0, 1.0, 3.0, sy.INF]]), (-1.0, 1.0)
    cand = {0: [(-1.0, 1.0)]}
    res = cegar.verify(m, grid, cegar.initial_rules(m, grid, [None], edges, "any"), cand, work, edges,
                       region={0: (-0.5, 1.0)})
    assert res["landmark"] is False and res["certified"] and res["witness"] == [1.0], res
    assert not cegar.exact_landmark(*cegar.exact_graph(m, [1.0]), 0, cand[0])


def test_sas_task_has_the_same_plans_as_the_translated_pddl_task(tmp_path=None):
    """compile_sas skips the translator. With each candidate cell banned, it must agree
    with compile_task + translator on whether a plan exists and whether the search space
    is exhausted: Sensor (two variables, a region) and RockSample (robot cell)."""
    if not (FAST_DOWNWARD.parent / "builds" / "release64").exists():
        import pytest
        pytest.skip("Fast Downward build not found")
    import json
    from policy_landmarks import cegar, extraction, symbolic as sy
    from policy_landmarks.planner import run_fd, run_fd_sas
    base = ROOT / "experiments/policy_graphs/alphas"
    work = Path(tmp_path or ROOT / "experiments" / "results" / "work" / "tests") / "sas-equivalence"
    cases = [("sensor-0.85", (-0.5, 0.5), None), ("rocksample-4-4-s5", (0.0, 0.0), [(1, 2)])]
    for name, (lo, hi), only in cases:
        m = sy.Model(extraction.load(base / f"{name}.json"), json.loads((base / f"{name}.alphas.json").read_text()))
        grid, edges = sy.bin_grid(m, 0), (-4.5, 4.5)
        positions = [(i, j) for i in range(1, m.n + 1) for j in range(1, m.n + 1)] if m.start() else [None]
        rules = cegar.initial_rules(m, grid, positions, edges, "any")
        region = {v: (lo, hi) for v in range(len(m.vars))}
        checks = only or [(v, c) for v in range(len(m.vars)) for c in range(1, len(grid.edges[v]) - 2)]
        for v, c in checks:
            banned = {v: {cegar._cells(grid, v)[c]}}
            seen = []
            for sub, run in (("pddl", lambda w: run_fd(w, *cegar.compile_task(m, grid, rules, banned, edges, region),
                                                         search="lazy_greedy([ff()])")),
                             ("sas", lambda w: run_fd_sas(w, cegar.compile_sas(m, grid, rules, banned, edges, region),
                                                          "lazy_greedy([ff()])"))):
                w = work / sub
                (w / "sas_plan").unlink(missing_ok=True)
                r = run(w)
                seen.append(((w / "sas_plan").exists(), r["exhausted"]))
            assert seen[0] == seen[1], (name, v, c, seen)
        if name == "sensor-0.85":
            # A real proof: refine on the SAS path until sensor a's +-2 level is a proven
            # landmark (a known result), then the translated task with the same rules must
            # be exhausted too, not only the trivial "start cell banned" cases above.
            e = grid.edges[0]
            cand = {0: [(e[1], e[2]), (e[5], e[6])]}                   # neg2 | pos2
            res = cegar.verify(m, grid, rules, cand, work / "verify", edges, region=region)
            assert res["landmark"] is True, res
            banned = cegar._banned(grid, cand)
            w = work / "pddl"
            (w / "sas_plan").unlink(missing_ok=True)
            r = run_fd(w, *cegar.compile_task(m, grid, rules, banned, edges, region), search="lazy_greedy([ff()])")
            assert r["exhausted"] and not (w / "sas_plan").exists()


def test_relative_levels_prove_evidence_for_every_prior_and_refute_with_a_prior(tmp_path=None):
    """Toy Tiger with prior-relative levels: one growl (1.386) moves the evidence into
    [1, 3) or [-3, -1) and the policy, which opens only beyond |log-odds| 2.3, is still
    listening for every prior in [-0.5, 0.5], so that level is a landmark for the region.
    Evidence 3 or more is never reached (the policy opens first), so it is refuted, and
    the witness is a prior whose own graph confirms it."""
    if not (FAST_DOWNWARD.parent / "builds" / "release64").exists():
        import pytest
        pytest.skip("Fast Downward build not found")
    import math
    from policy_landmarks import cegar, symbolic as sy
    g = {"problem": "tiger", "p_correct": 0.8, "states": ["left", "right"]}
    m = sy.Model(g, {"states": ["left", "right"], "actions": ["listen", "right", "left"],
                     "alphas": [[0.0, 0.0], [10.0, -100.0], [-100.0, 10.0]]})
    rm = cegar.RelativeModel(m)
    work = Path(tmp_path or ROOT / "experiments" / "results" / "work" / "tests") / "cegar-relative"
    lo, hi = -0.5, 0.5
    shifted = lambda pr, rr: [(a + pr, b + pr) for a, b in rr]       # noqa: E731
    for cand, expect in (([(-3.0, -1.0), (1.0, 3.0)], True), ([(3.0, sy.INF)], False)):
        grid = sy.Grid([[-sy.INF, -3.0, -1.0, 1.0, 3.0, sy.INF], [-sy.INF, lo, math.nextafter(hi, sy.INF), sy.INF]])
        edges = (-1.0, 1.0)
        rules = cegar.initial_rules(rm, grid, [None], edges, "any")
        res = cegar.verify(rm, grid, rules, {0: cand}, work, edges, region={0: (0.0, 0.0), 1: (lo, hi)})
        assert res["landmark"] is expect, (cand, res)
        if expect:
            assert all(cegar.exact_landmark(*cegar.exact_graph(m, [pr]), 0, shifted(pr, cand)) for pr in (lo, 0.0, hi))
        else:
            w = res["witness"]
            assert res["certified"] and w[0] == 0.0 and lo <= w[1] <= hi
            assert not cegar.exact_landmark(*cegar.exact_graph(m, [w[1]]), 0, shifted(w[1], cand))


def test_relative_levels_decide_evidence_that_lands_exactly_on_a_cell_edge(tmp_path=None):
    """With prior-relative levels the evidence starts at exactly 0 for every prior, so one
    growl lands exactly on the cell edge u for every witness. The replay follows the
    double-precision update the cells are exact for, so this is no tie: runs that growl
    right twice avoid [-3, -1), and the refutation is certified."""
    if not (FAST_DOWNWARD.parent / "builds" / "release64").exists():
        import pytest
        pytest.skip("Fast Downward build not found")
    import math
    from policy_landmarks import cegar, symbolic as sy
    g = {"problem": "tiger", "p_correct": 0.8, "states": ["left", "right"]}
    m = sy.Model(g, {"states": ["left", "right"], "actions": ["listen", "right", "left"],
                     "alphas": [[0.0, 0.0], [10.0, -100.0], [-100.0, 10.0]]})
    rm = cegar.RelativeModel(m)
    work = Path(tmp_path or ROOT / "experiments" / "results" / "work" / "tests") / "cegar-relative-edge"
    lo, hi = -0.5, 0.5
    grid = sy.Grid([[-sy.INF, -3.0, -1.0, m.u, 3.0, sy.INF], [-sy.INF, lo, math.nextafter(hi, sy.INF), sy.INF]])
    edges = (-1.0, 1.0)
    rules = cegar.initial_rules(rm, grid, [None], edges, "any")
    cand = [(-3.0, -1.0)]
    res = cegar.verify(rm, grid, rules, {0: cand}, work, edges, region={0: (0.0, 0.0), 1: (lo, hi)})
    assert res["landmark"] is False and res["certified"], res
    w = res["witness"]
    assert w[0] == 0.0 and lo <= w[1] <= hi
    assert not cegar.exact_landmark(*cegar.exact_graph(m, [w[1]]), 0, [(a + w[1], b + w[1]) for a, b in cand])


def test_box_test_keeps_an_action_that_loses_only_within_float_error():
    """'right' beats 'listen' by 1e-14 at every belief, far below the float error of
    values of size 100; dropping 'listen' would rest on rounding, so it must stay. A
    clear loss (by 1) is still dropped."""
    from policy_landmarks import symbolic as sy
    g = {"problem": "tiger", "p_correct": 0.8, "states": ["left", "right"]}
    for gap, kept in ((1e-14, True), (1.0, False)):
        m = sy.Model(g, {"states": ["left", "right"], "actions": ["listen", "right", "left"],
                         "alphas": [[0.0, 0.0], [gap, gap], [-100.0, 10.0]]})
        assert ("listen" in m.possible_actions(None, [(-1.0, 1.0)])) is kept, gap


def test_value_error_bound_covers_the_float_error_of_every_value():
    """The bound used by the box test and the replay must bound |fl(alpha . b) - alpha . b|
    for the beliefs the code computes. 1 - sigmoid(lam) is accurate only in absolute terms,
    so a bound relative to |alpha| b fails near p = 1 (485x at lam = 10 for alpha = (0, 1));
    checked here against 50-digit arithmetic for one and for two variables."""
    from decimal import Decimal, getcontext
    from policy_landmarks import symbolic as sy
    getcontext().prec = 50

    def exact_sigmoid(x):
        return Decimal(1) / (1 + Decimal(-x).exp())

    tiger = {"problem": "tiger", "p_correct": 0.8, "states": ["left", "right"]}
    sensor_states = ["a-ok,b-ok", "a-ok,b-bad", "a-bad,b-ok", "a-bad,b-bad"]
    sensor = {"problem": "sensor", "p_correct": 0.8, "states": sensor_states}
    cases = [(tiger, ["left", "right"], [[0.0, 1.0], [1.0, 0.0], [10.0, -100.0], [-1.0, 1.0]]),
             (sensor, sensor_states, [[0.0, 0.0, 0.0, 1.0], [5.0, -3.0, 0.0, 7.0], [0.0, 1.0, 1.0, 0.0]])]
    for g, states, alphas in cases:
        m = sy.Model(g, {"states": states, "actions": [f"a{i}" for i in range(len(alphas))], "alphas": alphas})
        bound = m.value_error(None)
        k = len(m.vars)
        for lam in (0.0, 3.0, 10.0, -10.0, 20.0, -20.0, 30.0, 36.5):
            for lams in ([lam] * k, [lam, -lam / 2][:k]):
                vals = m.A @ m.corner(None, lams)
                p = [exact_sigmoid(x) for x in lams]
                for row, val in zip(alphas, vals):
                    exact = sum(Decimal(row[i]) * _prod(p[v] if bits[v] else 1 - p[v] for v in range(k))
                                for i, bits in m.rows[None])
                    assert abs(Decimal(val) - exact) <= Decimal(bound), (g["problem"], lams, row)


def _prod(xs):
    out = 1
    for x in xs:
        out *= x
    return out


def test_successor_cells_follow_the_double_precision_update_exactly():
    """A cell [lo, hi) moves to the cells between fl(lo + s) and fl(top + s), top the
    largest double below hi; nothing is trimmed near an edge (the old 1e-9 trim dropped
    a reachable cell), and a split at threshold() separates the two sides exactly."""
    import math
    from policy_landmarks import symbolic as sy
    s, e = math.log(0.8 / 0.2), 0.5
    grid = sy.Grid([[-sy.INF, e, sy.INF]])
    lo = e - s - 1e-12                                       # lo + s lies just below the edge
    assert lo + s < e and list(grid.successors(0, lo, 1.0, s)) == [0, 1]
    t = sy.threshold(e, s)
    assert t + s >= e > math.nextafter(t, -sy.INF) + s
    assert list(grid.successors(0, -1.0, t, s)) == [0] and list(grid.successors(0, t, 1.0, s)) == [1]
    assert list(grid.successors(0, -sy.INF, t, s)) == [0] and list(grid.successors(0, t, sy.INF, s)) == [1]
    assert list(grid.successors(0, 0.0, 1.0, -sy.INF)) == [0]   # sampling sets -inf
    t0 = sy.threshold(s, s)                                  # edge = shift: the split is near 0
    assert t0 + s >= s > math.nextafter(t0, -sy.INF) + s


def test_exact_graph_from_alphas_matches_the_julia_policy_graph():
    """The Python belief graph built from alpha vectors at the uniform prior must give the
    same landmark verdicts as the SARSOP policy graph exported from Julia."""
    import json
    from policy_landmarks import cegar, extraction, symbolic as sy
    from policy_landmarks.exact import StateGraph
    levels = ["neg3", "neg2", "neg1", "unk", "pos1", "pos2", "pos3"]
    pairs = [("neg2", "neg3"), ("pos2", "pos3"), ("neg1", "pos1"), ("neg2", "pos2"), ("neg3", "pos3")]
    base = ROOT / "experiments/policy_graphs/alphas"
    for seed in (1, 3, 5):
        g = extraction.load(base / f"rocksample-4-4-s{seed}.json")
        m = sy.Model(g, json.loads((base / f"rocksample-4-4-s{seed}.alphas.json").read_text()))
        e = sy.bin_grid(m, 0).edges[0]
        span = dict(zip(levels, zip(e, e[1:])))
        start, succ = cegar.exact_graph(m, [0.0] * len(m.vars))
        julia = StateGraph(extraction.controller(g))
        for v, var in enumerate(m.vars):
            for cand in [(lv,) for lv in levels if lv != "unk"] + pairs:
                assert cegar.exact_landmark(start, succ, v, [span[lv] for lv in cand]) == \
                    julia.is_landmark([f"ev-{var}({lv})" for lv in cand]), (seed, var, cand)
