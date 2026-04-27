# POMDP Policy Landmarks

Experimental pipeline for extracting **landmarks** from probabilistic policies by encoding them as classical PDDL planning problems.

The core idea: run a POMDP solver in Julia, export the policy as an execution trace, encode it as a PDDL domain/problem, then run [Fast Downward](http://www.fast-downward.org/) to extract landmarks — enabling symbolic analysis of probabilistic policies.

---

## Repository Structure

```
pomdp_to_pddl/          # Pipeline: POMDP policy → PDDL encoding
  Pomdp/                #   Julia POMDP models (Tiger, RockSample, LightDark, ...)
  scripts/              #   Python encoder (FSC spec, PDDL generation)
  tools/                #   Autogen scripts for tiger/rock PDDL
  policy_template/      #   PDDL domain templates
  policy_pddl_autogen/  #   Auto-generated PDDL output

landmark_experiments/   # Landmark extraction experiments per domain
  nd_policy/            #   Nondeterministic policy (versions 1–8)
  tiger/                #   Tiger problem
  channel/              #   Channel domain
  mine/                 #   Mine domain
  sensor/               #   Sensor domain (v1, v2, v3)
```

Fast Downward source is included at the root and used as the landmark extraction backend.

---

## Pipeline Overview

1. **Solve POMDP** — Run a Julia POMDP solver (POMDPs.jl) to obtain a policy
2. **Trace execution** — Export the policy trace as a CSV
3. **Encode to PDDL** — Use scripts in `pomdp_to_pddl/scripts/` to generate a PDDL domain and problem
4. **Extract landmarks** — Run Fast Downward with a landmark heuristic on the generated PDDL

---

## Dependencies

- [Julia](https://julialang.org/) with [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl)
- Python 3
- [Fast Downward](http://www.fast-downward.org/) (included)
- CMake (to build Fast Downward)

---

## Building Fast Downward

```bash
python build.py
```

---

## Usage

### 1. Generate PDDL from a POMDP policy

```bash
cd pomdp_to_pddl
python scripts/run.py
```

Or use the autogen tools directly:

```bash
python tools/autogen_tiger_pddl.py
python tools/autogen_rock_pddl.py
```

### 2. Run landmark extraction

```bash
./builds/release32/bin/downward --search "astar(lmcut())" \
  < landmark_experiments/tiger/tiger_policy_domain.pddl \
    landmark_experiments/tiger/tiger_policy_problem.pddl
```

---

## Status

Work in progress. Domains currently explored: Tiger, RockSample, Channel, Mine, Sensor.
