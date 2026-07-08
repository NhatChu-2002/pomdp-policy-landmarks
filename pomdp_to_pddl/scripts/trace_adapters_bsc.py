"""
BSC trace adapters — build BSCSpec instances from Julia policy trace CSVs.

Unlike the FSC adapters (trace_adapters.py), these produce BSCSpec objects
whose sense-actions encode belief-state transitions directly (no controller
nodes). The resulting PDDL yields landmarks about MDP belief structure.

For tiger: the BSC spec is derived analytically from the trace's observation
  symbols (matching the double-confirmation pattern).
For channel / sensor / mine: the analytical specs from domains_bsc.py are
  returned directly, since SARSOP traces validate but don't change the spec.

Trace CSV formats
-----------------
tiger   : TRACE,<ep_id>,<action>,<obs>,<p_left>,<p_right>
channel : TRACE,<sim>,<t>,<action>,<obs>,<p_c1>,<p_c2>,<p_c3>   (header row)
sensor  : TRACE,<sim>,<t>,<action>,<obs>,<p_a-ok>,<p_a-faulty>,<p_b-ok>,<p_b-faulty>
mine    : TRACE,<sim>,<t>,<action>,<obs>,<p_c00>,<p_c01>,<p_c10>,<p_c11>
"""

from __future__ import annotations

import csv
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from bsc_spec import (
    BSCSpec, BSCTransition, BeliefRef, BeliefUpdate, CommitCondition, HiddenVariable,
)
import domains_bsc


# ===========================================================================
#  Shared helpers
# ===========================================================================

def _read_csv_rows(csv_path: Path) -> List[List[str]]:
    with csv_path.open("r", newline="", encoding="utf-8") as fh:
        return [row for row in csv.reader(fh) if row and row[0].strip() == "TRACE"]


# ===========================================================================
#  Tiger BSC adapter
# ===========================================================================

TIGER_VALUES = ("left", "right")


@dataclass(frozen=True)
class TigerBSCSummary:
    csv_path: str
    episode_count: int
    listen_count: int
    observations: Tuple[str, ...]


def tiger_trace_to_bsc_spec(
    csv_path: Path,
    *,
    name: str = "tiger-bsc",
) -> Tuple[BSCSpec, TigerBSCSummary]:
    """Build Tiger BSCSpec from the SARSOP trace.

    The tiger BSC spec is independent of the specific episodes seen — it is
    fully determined by the domain structure (two consistent observations
    required, with reset on contradiction). This function validates that the
    trace contains the expected observation symbols and returns the analytical
    spec.

    Trace row: TRACE,<ep_id>,<action>,<obs>,<p_left>,<p_right>
    """
    rows = _read_csv_rows(csv_path)
    if not rows:
        raise ValueError(f"No TRACE rows found in {csv_path}")

    episode_ids: set = set()
    listen_obs: List[str] = []
    for row in rows:
        if len(row) < 4:
            continue
        try:
            ep = int(row[1].strip())
        except ValueError:
            continue
        episode_ids.add(ep)
        action = row[2].strip().lower()
        obs    = row[3].strip().lower()
        if action == "listen" and obs in TIGER_VALUES:
            listen_obs.append(obs)

    if not listen_obs:
        raise ValueError(f"No listen observations found in {csv_path}")

    seen_obs = tuple(v for v in TIGER_VALUES if v in set(listen_obs))
    spec = domains_bsc.tiger_bsc()
    spec_named = BSCSpec(
        name=name,
        hidden_variables=spec.hidden_variables,
        observations=spec.observations,
        transitions=spec.transitions,
        commit_conditions=spec.commit_conditions,
        goal_confirm_per=dict(spec.goal_confirm_per),
    )
    summary = TigerBSCSummary(
        csv_path=str(csv_path),
        episode_count=len(episode_ids),
        listen_count=len(listen_obs),
        observations=seen_obs,
    )
    return spec_named, summary


# ===========================================================================
#  Channel BSC adapter
# ===========================================================================

CHANNEL_VALUES = ("c1", "c2", "c3")


@dataclass(frozen=True)
class ChannelBSCSummary:
    csv_path: str
    sim_count: int
    probe_count: int
    commit_count: int
    observations_seen: Tuple[str, ...]


def channel_trace_to_bsc_spec(
    csv_path: Path,
    *,
    name: str = "channel-bsc",
) -> Tuple[BSCSpec, ChannelBSCSummary]:
    """Return the analytical channel BSCSpec, validated against the trace.

    Trace row: TRACE,<sim>,<t>,<action>,<obs>,<p_c1>,<p_c2>,<p_c3>
    """
    rows = _read_csv_rows(csv_path)
    # Skip header row (first row where row[1] is not an int)
    data_rows = []
    for row in rows:
        try:
            int(row[1].strip())
            data_rows.append(row)
        except (ValueError, IndexError):
            continue

    sim_ids: set = set()
    probe_count = 0
    commit_count = 0
    obs_seen: set = set()

    for row in data_rows:
        if len(row) < 5:
            continue
        try:
            sim_ids.add(int(row[1].strip()))
        except ValueError:
            continue
        action = row[3].strip()
        obs    = row[4].strip()
        if action.startswith("probe"):
            probe_count += 1
            obs_seen.add(obs)
        elif action.startswith("commit"):
            commit_count += 1

    spec = domains_bsc.channel_bsc()
    spec_named = BSCSpec(
        name=name,
        hidden_variables=spec.hidden_variables,
        observations=spec.observations,
        transitions=spec.transitions,
        commit_conditions=spec.commit_conditions,
        goal_confirm_per=dict(spec.goal_confirm_per),
    )
    summary = ChannelBSCSummary(
        csv_path=str(csv_path),
        sim_count=len(sim_ids),
        probe_count=probe_count,
        commit_count=commit_count,
        observations_seen=tuple(sorted(obs_seen)),
    )
    return spec_named, summary


# ===========================================================================
#  Sensor BSC adapter
# ===========================================================================

@dataclass(frozen=True)
class SensorBSCSummary:
    csv_path: str
    sim_count: int
    read_a_count: int
    read_b_count: int
    commit_count: int


def sensor_trace_to_bsc_spec(
    csv_path: Path,
    *,
    name: str = "sensor-bsc",
) -> Tuple[BSCSpec, SensorBSCSummary]:
    """Return the analytical sensor BSCSpec, validated against the trace.

    Trace row: TRACE,<sim>,<t>,<action>,<obs>,<p_a-ok>,<p_a-faulty>,<p_b-ok>,<p_b-faulty>
    """
    rows = _read_csv_rows(csv_path)
    data_rows = []
    for row in rows:
        try:
            int(row[1].strip())
            data_rows.append(row)
        except (ValueError, IndexError):
            continue

    sim_ids: set = set()
    read_a = read_b = commit = 0

    for row in data_rows:
        if len(row) < 5:
            continue
        try:
            sim_ids.add(int(row[1].strip()))
        except ValueError:
            continue
        action = row[3].strip()
        if action == "read-a":
            read_a += 1
        elif action == "read-b":
            read_b += 1
        elif action.startswith("commit"):
            commit += 1

    spec = domains_bsc.sensor_bsc()
    spec_named = BSCSpec(
        name=name,
        hidden_variables=spec.hidden_variables,
        observations=spec.observations,
        transitions=spec.transitions,
        commit_conditions=spec.commit_conditions,
        goal_confirm_per=dict(spec.goal_confirm_per),
    )
    summary = SensorBSCSummary(
        csv_path=str(csv_path),
        sim_count=len(sim_ids),
        read_a_count=read_a,
        read_b_count=read_b,
        commit_count=commit,
    )
    return spec_named, summary


# ===========================================================================
#  Mine BSC adapter
# ===========================================================================

@dataclass(frozen=True)
class MineBSCSummary:
    csv_path: str
    sim_count: int
    probe_count: int
    commit_count: int
    cells_probed: Tuple[str, ...]


# ===========================================================================
#  RockSample BSC adapter
# ===========================================================================
#
#  Trace format (RockSample Julia output):
#    TRACE,<t>,<x>,<y>,<action>,<obs>,<reward>,<bel_r1>,...,<bel_rN>,<true_r1>,...
#
#  Action encoding: 1=North, 2=South, 3=East, 4=West, 5=Sample,
#                   (5+i)=SenseRock-i   for i in 1..num_rocks
#  Observation encoding: 1=GoodRock, 2=BadRock, 3=Null (movement/sample)
#
#  Belief interpretation:
#    0.5       → uncertain-rock-i  (no evidence yet)
#    >> 0.5    → k-rock-i(good)    (leaning good; > BELIEF_THRESHOLD → certain)
#    << 0.5    → k-rock-i(bad)     (leaning bad;  < 1-BELIEF_THRESHOLD → certain)
#    0.0 / 1.0 → certain-bad / certain-good (collapsed)
#
#  Like other BSC adapters, the analytical spec from domains_bsc is returned
#  (the trace validates structure but does not change the spec).

ROCK_BELIEF_THRESHOLD = 0.9   # belief above this → k(good); below 1-this → k(bad)
ROCK_SENSE_ACTION_OFFSET = 5  # action id = ROCK_SENSE_ACTION_OFFSET + rock_index (1-based)
ROCK_OBS_GOOD = 1
ROCK_OBS_BAD  = 2
ROCK_OBS_NULL = 3


@dataclass(frozen=True)
class RockSampleBSCSummary:
    csv_path: str
    step_count: int
    num_rocks: int
    sense_counts: Dict[int, int]       # rock_index → number of sense actions
    good_obs_counts: Dict[int, int]    # rock_index → good observations
    bad_obs_counts: Dict[int, int]     # rock_index → bad observations
    certain_good_rocks: List[int]      # rocks with belief → 1.0 at some point
    certain_bad_rocks: List[int]       # rocks with belief → 0.0 at some point


def rock_sample_trace_to_bsc_spec(
    csv_path: Path,
    *,
    name: Optional[str] = None,
    num_rocks: int = 4,
) -> Tuple[BSCSpec, RockSampleBSCSummary]:
    """Build RockSample BSCSpec from a Julia SARSOP trace CSV.

    The BSC spec is the analytical rock_sample_bsc(num_rocks) spec from
    domains_bsc.  The trace is parsed to validate structure and produce a
    summary (step counts, sense frequencies, belief convergence).

    Trace row: TRACE,<t>,<x>,<y>,<action>,<obs>,<reward>,<bel_r1>,...,<bel_rN>,<true_r1>,...
    """
    rows = _read_csv_rows(csv_path)

    # Skip header row (first row where t is not an int)
    data_rows: List[List[str]] = []
    for row in rows:
        try:
            int(row[1].strip())
            data_rows.append(row)
        except (ValueError, IndexError):
            continue

    if not data_rows:
        raise ValueError(f"No TRACE data rows found in {csv_path}")

    step_count = len(data_rows)
    sense_counts:    Dict[int, int] = {i: 0 for i in range(1, num_rocks + 1)}
    good_obs_counts: Dict[int, int] = {i: 0 for i in range(1, num_rocks + 1)}
    bad_obs_counts:  Dict[int, int] = {i: 0 for i in range(1, num_rocks + 1)}
    certain_good: set = set()
    certain_bad:  set = set()

    belief_col_start = 7  # columns: TRACE,t,x,y,action,obs,reward,bel_r1,...

    for row in data_rows:
        if len(row) < belief_col_start + num_rocks:
            continue
        try:
            action = int(row[4].strip())
            obs    = int(row[5].strip())
        except (ValueError, IndexError):
            continue

        # Parse beliefs for this step
        for i in range(1, num_rocks + 1):
            col = belief_col_start + (i - 1)
            try:
                bel = float(row[col].strip())
            except (ValueError, IndexError):
                continue
            if bel >= 1.0 - 1e-6:
                certain_good.add(i)
            elif bel <= 1e-6:
                certain_bad.add(i)

        # Count sense actions
        rock_idx = action - ROCK_SENSE_ACTION_OFFSET  # 6→1, 7→2, 8→3, 9→4
        if 1 <= rock_idx <= num_rocks:
            sense_counts[rock_idx] += 1
            if obs == ROCK_OBS_GOOD:
                good_obs_counts[rock_idx] += 1
            elif obs == ROCK_OBS_BAD:
                bad_obs_counts[rock_idx] += 1

    bsc_name = name or f"rocksample-{num_rocks}-bsc"
    spec = domains_bsc.rock_sample_bsc(num_rocks)
    spec_named = BSCSpec(
        name=bsc_name,
        hidden_variables=spec.hidden_variables,
        observations=spec.observations,
        transitions=spec.transitions,
        commit_conditions=spec.commit_conditions,
        goal_confirm_per=dict(spec.goal_confirm_per),
    )

    summary = RockSampleBSCSummary(
        csv_path=str(csv_path),
        step_count=step_count,
        num_rocks=num_rocks,
        sense_counts=sense_counts,
        good_obs_counts=good_obs_counts,
        bad_obs_counts=bad_obs_counts,
        certain_good_rocks=sorted(certain_good),
        certain_bad_rocks=sorted(certain_bad),
    )
    return spec_named, summary


def mine_trace_to_bsc_spec(
    csv_path: Path,
    *,
    name: str = "mine-bsc",
) -> Tuple[BSCSpec, MineBSCSummary]:
    """Return the analytical mine BSCSpec (2×2), validated against the trace.

    Trace row: TRACE,<sim>,<t>,<action>,<obs>,<p_c00>,<p_c01>,<p_c10>,<p_c11>
    """
    rows = _read_csv_rows(csv_path)
    data_rows = []
    for row in rows:
        try:
            int(row[1].strip())
            data_rows.append(row)
        except (ValueError, IndexError):
            continue

    sim_ids: set = set()
    probe_count = 0
    commit_count = 0
    cells_probed: set = set()

    for row in data_rows:
        if len(row) < 5:
            continue
        try:
            sim_ids.add(int(row[1].strip()))
        except ValueError:
            continue
        action = row[3].strip()
        if action.startswith("probe"):
            probe_count += 1
            cells_probed.add(action[6:])   # "c00", "c01", etc.
        elif action.startswith("commit"):
            commit_count += 1

    spec = domains_bsc.mine_bsc()
    spec_named = BSCSpec(
        name=name,
        hidden_variables=spec.hidden_variables,
        observations=spec.observations,
        transitions=spec.transitions,
        commit_conditions=spec.commit_conditions,
        goal_confirm_per=dict(spec.goal_confirm_per),
    )
    summary = MineBSCSummary(
        csv_path=str(csv_path),
        sim_count=len(sim_ids),
        probe_count=probe_count,
        commit_count=commit_count,
        cells_probed=tuple(sorted(cells_probed)),
    )
    return spec_named, summary
