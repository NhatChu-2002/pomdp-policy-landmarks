# POMDP Policy Landmarks

Explains a POMDP policy by the beliefs it cannot avoid. The policy is written
as a belief-state controller (BSC), compiled into a classical PDDL task whose
plans are exactly the controller's successful executions, and the task's
planning landmarks are extracted with Fast Downward's RHW method. Each landmark
is a belief that every successful execution reaches; each ordering is an order
in which the policy must collect its evidence.

## Quick start

Run everything from the repository root (Python 3, tested with 3.12; the planner binary in
`fast-downward/builds/release64` must exist, see `fast-downward/README.md`).

```bash
python -m policy_landmarks list                   # available controllers
python -m policy_landmarks explain tiger          # landmarks and orderings
python -m policy_landmarks explain sensor-2 --induced --check
python experiments/run_paper.py extracted         # main paper results (SARSOP policy graphs), ~1 min
python experiments/run_paper.py                   # every experiment
python -m pytest tests                            # fast checks
```

`explain` prints the landmark graph in plain text, and `--check` verifies
every landmark and ordering by exhaustive search. `--induced` learns the
controller from a SARSOP trace instead of using the hand-written one.

## Layout

```text
policy_landmarks/        the pipeline (Python package)
  spec.py                controller data model: variables, sensing rules, commitment rules
  domains.py             hand-written controllers (HAND_WRITTEN registry)
  induction.py           controllers learned from SARSOP traces (TRACE_SOURCES, induce)
  extraction.py          controllers extracted from SARSOP policy graphs (main results):
                         evidence abstraction, PDDL, first-passage times, exact policy value
  encoder.py             controller -> PDDL (one commit action per commitment rule)
  planner.py             run Fast Downward, read the landmark graph
  fd_output.py           parser for Fast Downward's landmark output
  ground_truth.py        exact landmarks/orderings by exhaustive search (checks RHW)
  __main__.py            command line: list / compile / explain
experiments/
  run_paper.py           every table (extracted = main paper results; main, exactness,
                         ablation, induced, mutation, scaling = hand-written controllers)
  policy_graphs/*.json   SARSOP policy graphs (pomdp/extract_policy_graph.jl), 25 policies
  baselines/             frozen PDDL of earlier encodings, used by the ablation
  results/*.json         paper results; results/work/ holds every run's files
pomdp/                   Julia POMDP models (SARSOP), traces, and extract_policy_graph.jl
tests/                   pytest checks
generated/               PDDL written by `compile` / `explain` (one folder per controller)
fast-downward/           the planner, with two small patches (see its README)
legacy/                  earlier FSC pipeline and scripts, kept for reference
```

## Debugging a run

Each planner run leaves its inputs and outputs in one folder:
`generated/<name>/` for the CLI and `experiments/results/work/<experiment>/<run>/`
for the experiments. A folder holds `domain.pddl`, `problem.pddl`, `fd.log`
(full planner output, landmark graph near the end) and `output.sas` (the
translated task, which `ground_truth.Task` reads).

Common problems:

- `translation failed`: read `fd.log`; usually a PDDL syntax error from a
  malformed spec. `spec.validate()` catches unknown variables and values first.
- A landmark you expected is missing: run `explain <name> --check`. If the
  check passes, the belief is genuinely not necessary for this policy (for
  example, a commitment rule does not require it).
- Traces: regenerate with `julia pomdp/<model>.jl <out.csv> <episodes>`
  (needs POMDPs.jl, QuickPOMDPs, NativeSARSOP).

## Results

**Main results** (`experiments/results/extracted.json`): 25 SARSOP policies
(Tiger, Sensor, Channel, Mine, RockSample up to (7,8)). The exact value of
each extracted policy graph equals SARSOP's value (or exceeds its lower bound
where SARSOP had not converged), except Mine-3x3, whose policy commits to only
2 of 9 cells. All 1,093 landmarks and orderings are confirmed by exhaustive
search. Regenerate a policy graph with

```bash
julia pomdp/extract_policy_graph.jl tiger 0.85 experiments/policy_graphs/tiger-0.85.json
julia pomdp/extract_policy_graph.jl batch jobs.txt      # one job per line, one Julia process
```

**Hand-written controllers** (earlier experiments):

| Controller | Landmarks | Disjunctive | Orderings |
|---|---|---|---|
| Tiger | 7 | 2 | 9 |
| Channel | 6 | 1 | 6 |
| Mine-2x2 | 6 | 1 | 6 |
| Sensor-2 | 10 | 2 | 11 |
| Sensor-3 | 14 | 3 | 16 |
| RockSample-4 | 18 | 4 | 21 |

All landmarks and orderings are confirmed by exhaustive search
(`experiments/results/exactness.json`).
