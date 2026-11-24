### POMDP Policy to PDDL

This folder contains the spec-based pipeline for turning policy traces or
finite-state-controller descriptions into classical PDDL.

Current target:

```text
policy trace
  -> domain adapter
  -> FSCPomdpSpec
  -> encoder.compile_to_pddl(spec)
  -> domain/problem PDDL
  -> Fast Downward landmarks
```

#### Kept Scripts

```text
scripts/fsc_spec.py              Shared FSCPomdpSpec data model
scripts/encoder.py               FSCPomdpSpec -> PDDL compiler
scripts/trace_adapters.py        Trace CSV -> FSCPomdpSpec adapters
scripts/compile_trace_to_pddl.py Compile traces into generated PDDL
scripts/domains.py               Hand-authored FSCPomdpSpec examples
scripts/run.py                   Compile hand-authored specs
```

#### Compile Tiger From Trace

```powershell
python pomdp_to_pddl\scripts\compile_trace_to_pddl.py tiger
```

This writes generated PDDL to:

```text
landmark_experiments/generated/tiger_trace_fsc/
```

Then run landmark extraction from the repository root:

```powershell
python scripts\run_all_landmarks.py --only tiger_trace_fsc_auto
```

#### Compile Hand-Authored Specs

```powershell
python pomdp_to_pddl\scripts\run.py tiger --outdir pddl_out
python pomdp_to_pddl\scripts\run.py channel --outdir pddl_out
python pomdp_to_pddl\scripts\run.py mine --outdir pddl_out
python pomdp_to_pddl\scripts\run.py sensor --outdir pddl_out
```

Use hand-authored specs for domains that do not have trace CSV files yet.
These still follow the shared `FSCPomdpSpec -> PDDL` path.

#### Next Adapters

If new trace formats become available, add one adapter function per format:

```text
sensor trace      -> sensor_trace_to_spec()
mine trace        -> mine_trace_to_spec()
channel trace     -> channel_trace_to_spec()
rocksample trace  -> rock_trace_to_spec()
```

Each adapter should return an `FSCPomdpSpec`, so the rest of the pipeline stays shared.
