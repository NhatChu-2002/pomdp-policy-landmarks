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
