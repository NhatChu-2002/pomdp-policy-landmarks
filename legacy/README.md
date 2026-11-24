# Legacy code (not maintained)

Kept for reference. Nothing in the current pipeline or the paper depends on
it, and paths inside refer to the layout before November 2026, so scripts may
not run as they are.

| Folder | What it was |
|---|---|
| `fsc/` | First pipeline: finite-state-controller specs (`fsc_spec.py`, `domains.py`) compiled to PDDL with controller-node predicates (`encoder.py`). Its PDDL output is frozen in `experiments/baselines/fsc/` for the ablation. |
| `bsc_trace_check/` | Checked SARSOP traces against the hand-written BSCs. Replaced by trace induction (`policy_landmarks/induction.py`). |
| `early/` | Batch runner over hand-written PDDL (`run_all_landmarks.py`, `experiments.yaml`), shell wrapper, PDDL templates and generators from the first experiments. |
