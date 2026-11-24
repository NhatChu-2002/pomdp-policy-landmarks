"""Trace adapters that build FSCPomdpSpec instances.

Each adapter translates a domain-specific trace format into the shared
FSCPomdpSpec model consumed by encoder.py. This is the bridge from
"policy traces" to "compile FSC to PDDL" in the automatic pipeline.
"""

from __future__ import annotations

import csv
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from fsc_spec import BeliefUpdate, FSCPomdpSpec, FSCTransition, HiddenVariable


TIGER_VALUES = ("left", "right")
ROCK_OBS = ("good", "bad")


@dataclass(frozen=True)
class TigerTraceSummary:
    csv_path: str
    trace_id: Optional[int]
    trace_count: int
    listen_count: int
    terminal_action_count: int
    observations: Tuple[str, ...]


def tiger_trace_to_spec(
    csv_path: Path,
    *,
    trace_id: Optional[int] = None,
    name: str = "tiger-trace-fsc",
) -> tuple[FSCPomdpSpec, TigerTraceSummary]:
    """Build a compact Tiger FSC from Julia policy trace rows.

    Expected trace rows look like:
      TRACE,<id>,listen,<left|right>,<belief-left>,<belief-right>
      TRACE,<id>,<left|right>,<left|right>,<belief-left>,<belief-right>

    The resulting controller keeps the standard Tiger memory pattern:
    root -> seen-left/right -> commit, with contradictory evidence returning
    to root. The trace supplies/validates the observation symbols.
    """
    rows = _read_tiger_rows(csv_path, trace_id=trace_id)
    listen_observations = [row["symbol"] for row in rows if row["action"] == "listen"]
    if not listen_observations:
        raise ValueError(f"No listen rows found in {csv_path} (trace_id={trace_id})")

    observed = tuple(value for value in TIGER_VALUES if value in set(listen_observations))
    if not observed:
        raise ValueError(f"No Tiger observations found in {csv_path}")

    direction = HiddenVariable(name="direction", domain=TIGER_VALUES)
    fsc_nodes = ["nroot", "nseen-left", "nseen-right", "ncommit"]
    transitions: List[FSCTransition] = []

    for value in TIGER_VALUES:
        transitions.append(
            FSCTransition(
                "nroot",
                value,
                f"nseen-{value}",
                (BeliefUpdate("direction", value, "pos"),),
            )
        )

    for assumed in TIGER_VALUES:
        node = f"nseen-{assumed}"
        for observation in TIGER_VALUES:
            if observation == assumed:
                other = _other_tiger_value(assumed)
                transitions.append(
                    FSCTransition(
                        node,
                        observation,
                        "ncommit",
                        (BeliefUpdate("direction", other, "neg"),),
                    )
                )
            else:
                transitions.append(FSCTransition(node, observation, "nroot"))

    spec = FSCPomdpSpec(
        name=name,
        hidden_variables=[direction],
        fsc_nodes=fsc_nodes,
        initial_node="nroot",
        commit_nodes=["ncommit"],
        observations=list(TIGER_VALUES),
        transitions=transitions,
    )

    trace_ids = {row["trace_id"] for row in rows}
    summary = TigerTraceSummary(
        csv_path=str(csv_path),
        trace_id=trace_id,
        trace_count=len(trace_ids),
        listen_count=len(listen_observations),
        terminal_action_count=sum(1 for row in rows if row["action"] in TIGER_VALUES),
        observations=observed,
    )
    return spec, summary


def _read_tiger_rows(csv_path: Path, *, trace_id: Optional[int]) -> List[Dict[str, object]]:
    rows: List[Dict[str, object]] = []
    with csv_path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.reader(handle)
        for raw in reader:
            if not raw or len(raw) < 4 or raw[0].strip() != "TRACE":
                continue
            try:
                current_trace_id = int(raw[1].strip())
            except ValueError as exc:
                raise ValueError(f"Bad Tiger trace id in row: {raw}") from exc
            if trace_id is not None and current_trace_id != trace_id:
                continue

            action = raw[2].strip().lower()
            symbol = raw[3].strip().lower()
            if action not in ("listen", *TIGER_VALUES):
                raise ValueError(f"Unexpected Tiger action {action!r} in row: {raw}")
            if symbol not in TIGER_VALUES:
                raise ValueError(f"Unexpected Tiger symbol {symbol!r} in row: {raw}")

            rows.append(
                {
                    "trace_id": current_trace_id,
                    "action": action,
                    "symbol": symbol,
                }
            )

    if not rows:
        raise ValueError(f"No Tiger TRACE rows found in {csv_path} (trace_id={trace_id})")
    return rows


def _other_tiger_value(value: str) -> str:
    if value == "left":
        return "right"
    if value == "right":
        return "left"
    raise ValueError(value)


# ---------------------------------------------------------------------------
# RockSample adapter
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class RockTraceSummary:
    csv_path: str
    rock_count: int
    sense_events: int
    rocks_sensed: Tuple[int, ...]


def rock_trace_to_spec(
    csv_path: Path,
    *,
    name: str = "rock-trace-fsc",
) -> tuple[FSCPomdpSpec, RockTraceSummary]:
    """Build a RockSample FSC from Julia policy trace rows.

    Expected trace columns (CSV header row):
      TRACE,t,x,y,action,obs,reward,belief_r1,...,true_r1,...

    action encoding: 1-5 = move/sample; 5+k = Sense_rk
    obs encoding:    1 = GOOD, 2 = BAD, 3 = none (movement / sample)

    The FSC uses a Tiger-style double-confirmation pattern per rock:
      nr{k}-s1 --obs=good--> nr{k}-s2g  (write k(good-rk))
      nr{k}-s2g --obs=good-> nr{k+1}-s1 (write k-not(bad-rk))   [confirmed]
      nr{k}-s2g --obs=bad --> nr{k}-s1  (contradictory → reset)
      (symmetric for bad branch)
    Two consistent sense observations of the same rock confirm its quality.
    """
    sense_events, rock_count = _read_rock_rows(csv_path)

    hidden_vars = [
        HiddenVariable(name=f"quality-r{k}", domain=(f"good-r{k}", f"bad-r{k}"))
        for k in range(1, rock_count + 1)
    ]

    # nroot serves as nr1-s1; subsequent rocks have explicit s1 nodes
    fsc_nodes: List[str] = ["nroot"]
    for k in range(1, rock_count + 1):
        fsc_nodes.append(f"nr{k}-s2g")
        fsc_nodes.append(f"nr{k}-s2b")
        if k < rock_count:
            fsc_nodes.append(f"nr{k+1}-s1")
    fsc_nodes.append("ncommit")

    transitions: List[FSCTransition] = []
    for k in range(1, rock_count + 1):
        var = f"quality-r{k}"
        s1 = "nroot" if k == 1 else f"nr{k}-s1"
        s2g = f"nr{k}-s2g"
        s2b = f"nr{k}-s2b"
        nxt = "ncommit" if k == rock_count else f"nr{k+1}-s1"

        # First sensing: write positive belief
        transitions.append(FSCTransition(s1, "good", s2g, (BeliefUpdate(var, f"good-r{k}", "pos"),)))
        transitions.append(FSCTransition(s1, "bad",  s2b, (BeliefUpdate(var, f"bad-r{k}",  "pos"),)))

        # Second sensing: confirm (same obs) or reset (contradictory)
        transitions.append(FSCTransition(s2g, "good", nxt, (BeliefUpdate(var, f"bad-r{k}",  "neg"),)))
        transitions.append(FSCTransition(s2g, "bad",  s1))   # reset
        transitions.append(FSCTransition(s2b, "bad",  nxt, (BeliefUpdate(var, f"good-r{k}", "neg"),)))
        transitions.append(FSCTransition(s2b, "good", s1))   # reset

    spec = FSCPomdpSpec(
        name=name,
        hidden_variables=hidden_vars,
        fsc_nodes=fsc_nodes,
        initial_node="nroot",
        commit_nodes=["ncommit"],
        observations=list(ROCK_OBS),
        transitions=transitions,
    )

    rocks_sensed = tuple(sorted({e["rock"] for e in sense_events}))
    summary = RockTraceSummary(
        csv_path=str(csv_path),
        rock_count=rock_count,
        sense_events=len(sense_events),
        rocks_sensed=rocks_sensed,
    )
    return spec, summary


def _read_rock_rows(csv_path: Path) -> Tuple[List[Dict[str, object]], int]:
    """Parse rock_trace.csv and return (sense_events list, max_rock_index)."""
    sense_events: List[Dict[str, object]] = []
    max_rock = 0

    with csv_path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.reader(handle)
        header = next(reader, None)  # skip header row
        if header is None:
            raise ValueError(f"Empty file: {csv_path}")

        # Locate column indices from header
        try:
            action_col = header.index("action")
            obs_col    = header.index("obs")
        except ValueError as exc:
            raise ValueError(f"Missing expected column in {csv_path}: {exc}") from exc

        for raw in reader:
            if not raw or raw[0].strip() != "TRACE":
                continue
            try:
                action = int(raw[action_col].strip())
                obs    = int(raw[obs_col].strip())
            except (ValueError, IndexError):
                continue

            if action > 5 and obs != 3:          # sense action with actual observation
                rock_idx = action - 5
                obs_sym  = "good" if obs == 1 else "bad"
                sense_events.append({"rock": rock_idx, "obs": obs_sym})
                max_rock = max(max_rock, rock_idx)

    if max_rock == 0:
        raise ValueError(f"No sense events found in {csv_path}")
    return sense_events, max_rock
