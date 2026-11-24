# POMDP Policy Landmarks

Experimental pipeline for explaining probabilistic policies by compiling
finite-state-controller-like policies into classical PDDL and extracting
landmarks with Fast Downward.

## Reproducing the paper

```powershell
python pomdp_to_pddl\scripts\paper_experiments.py
```

Runs all six experiments (main, exactness, ablation, induced, mutation,
scaling) in about a minute and writes `landmark_experiments/results/paper/*.json`.
The current pipeline compiles belief-state controllers (`domains_bsc.py`,
`encoder_bsc.py`); commitment actions come from each policy's own commitment
rules. `landmark_experiments/ablation_generic_gates/` freezes the earlier
generic-gate encoding for the ablation.

The Fast Downward build used here differs from stock Fast Downward in two ways:

- `src/search/landmarks/landmark_factory.cc` exits after dumping the landmark
  graph (no search is run).
- `src/search/landmarks/landmark_factory_rpg_sasp.cc` keeps disjunctive
  landmarks of up to 64 facts (stock: 4), needed for Mine grids beyond 2x2.

The long-term target pipeline is:

```text
POMDP / solved policy
  -> policy traces
  -> infer or build an FSC model
  -> compile FSC to PDDL
  -> extract landmarks
  -> produce explanation reports
```

## Repository Structure

```text
pomdp_to_pddl/
  Pomdp/                Julia POMDP models and trace CSV files
  scripts/              Shared FSC spec, trace adapters, and PDDL compiler
  tools/                Older domain-specific autogen scripts
  policy_template/      PDDL domain templates
  policy_pddl_autogen/  Auto-generated PDDL output

landmark_experiments/
  channel/              Channel domain
  mine/                 Mine domain
  nd_policy/            Nondeterministic policy versions
  sensor/               Sensor domain versions
  tiger/                Hand-written Tiger policy PDDL
  generated/            Spec-generated PDDL experiments

scripts/
  run_all_landmarks.py  Batch Fast Downward runner
  parse_landmarks.py    Landmark parser and report generator
```

Fast Downward source is included at the root and used as the landmark extraction backend.

## Current Automation

The project now supports the lower half of the pipeline for all configured PDDL experiments:

```text
PDDL domain/problem
  -> extract landmarks
  -> JSON/CSV/report explanation
```

Run all configured experiments:

```powershell
python scripts\run_all_landmarks.py
```

Run one experiment:

```powershell
python scripts\run_all_landmarks.py --only tiger
```

Outputs are written under `results/`:

```text
results/landmarks/   Raw landmark lines
results/parsed/      JSON and CSV landmark data
results/reports/     Markdown explanation reports
results/summary.csv  Per-domain summary table
```

## PDDL Auto-Generation

There are two auto-generation modes.

Trace-backed generation is used when a policy trace exists:

```text
Tiger trace CSV
  -> FSCPomdpSpec
  -> generated PDDL
  -> landmark extraction
```

Generate the trace-derived Tiger FSC PDDL:

```powershell
python pomdp_to_pddl\scripts\compile_trace_to_pddl.py tiger
```

Then run its landmark experiment:

```powershell
python scripts\run_all_landmarks.py --only tiger_trace_fsc_auto
```

Static-spec generation is used for domains that do not have CSV traces yet:

```powershell
python pomdp_to_pddl\scripts\run.py channel --outdir landmark_experiments\generated\channel_spec_fsc
python pomdp_to_pddl\scripts\run.py mine --outdir landmark_experiments\generated\mine_spec_fsc
python pomdp_to_pddl\scripts\run.py sensor --outdir landmark_experiments\generated\sensor_spec_fsc
```

Then run:

```powershell
python scripts\run_all_landmarks.py --only channel_spec_fsc_auto mine_spec_fsc_auto sensor_spec_fsc_auto
```

Generated files are written under:

```text
landmark_experiments/generated/
```

## Dependencies

- Julia with POMDPs.jl for generating policy traces
- Python 3
- Fast Downward, included in this repository
- CMake, for rebuilding Fast Downward if needed

## Building Fast Downward

```powershell
python build.py
```

## Status

Implemented:

- Batch landmark extraction for existing PDDL domains.
- Landmark parsing into JSON and CSV.
- Markdown explanation reports.
- A first trace-to-FSC adapter for Tiger.
- Static FSCPomdpSpec generation for Channel, Mine, and Sensor.

Next:

- Add richer trace adapters if Sensor, Mine, Channel, or RockSample traces become available.
- Compare hand-written PDDL encodings against trace-derived FSC encodings.
- Improve explanation reports with domain-specific landmark labels.
