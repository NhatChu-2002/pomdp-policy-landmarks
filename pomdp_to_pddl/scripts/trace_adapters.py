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
