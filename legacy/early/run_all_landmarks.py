#!/usr/bin/env python3
"""Run landmark extraction for all configured PDDL experiments."""

from __future__ import annotations

import argparse
import csv
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional

from parse_landmarks import (
    parse_landmark_text,
    write_csv,
    write_json,
    write_report,
)


DEFAULT_SEARCH = "astar(lmcount(lm_factory=lm_rhw(disjunctive_landmarks=true)))"


@dataclass(frozen=True)
class Experiment:
    name: str
    domain: Path
    problem: Path


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def load_experiments(config_path: Path, root: Path) -> List[Experiment]:
    entries = _load_simple_yaml_list(config_path)
    experiments = []
    for entry in entries:
        missing = {"name", "domain", "problem"} - set(entry)
        if missing:
            raise ValueError(f"{config_path}: missing keys {sorted(missing)} in {entry}")
        experiments.append(
            Experiment(
                name=entry["name"],
                domain=(root / entry["domain"]).resolve(),
                problem=(root / entry["problem"]).resolve(),
            )
        )
    return experiments


def run_experiment(
    experiment: Experiment,
    *,
    root: Path,
    results_dir: Path,
    build: str,
    search: str,
    dry_run: bool,
) -> Dict[str, object]:
    full_output_dir = results_dir / "full_logs"
    landmark_dir = results_dir / "landmarks"
    parsed_dir = results_dir / "parsed"
    report_dir = results_dir / "reports"
    work_dir = results_dir / "work" / experiment.name
    for path in (full_output_dir, landmark_dir, parsed_dir, report_dir, work_dir):
        path.mkdir(parents=True, exist_ok=True)

    command = [
        sys.executable,
        str(root / "fast-downward.py"),
        "--build",
        build,
        str(experiment.domain),
        str(experiment.problem),
        "--search",
        search,
    ]

    if dry_run:
        return {
            "name": experiment.name,
            "status": "dry-run",
            "command": " ".join(command),
            "landmark_count": 0,
            "disjunctive_count": 0,
            "belief_landmark_count": 0,
            "goal_count": 0,
            "order_edge_count": 0,
        }

    completed = subprocess.run(
        command,
        cwd=work_dir,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    full_output = completed.stdout or ""
    full_log_path = full_output_dir / f"{experiment.name}.log"
    full_log_path.write_text(full_output, encoding="utf-8", errors="replace")

    landmark_text = "\n".join(
        line for line in full_output.splitlines() if "LM " in line
    )
    landmark_path = landmark_dir / f"{experiment.name}_landmarks.txt"
    landmark_path.write_text(landmark_text + ("\n" if landmark_text else ""), encoding="utf-8")

    parsed = parse_landmark_text(landmark_text, source=str(landmark_path))
    write_json(parsed, parsed_dir / f"{experiment.name}_landmarks.json")
    write_csv(parsed, parsed_dir / f"{experiment.name}_landmarks.csv")
    write_report(parsed, report_dir / f"{experiment.name}_report.md", name=experiment.name)

    return {
        "name": experiment.name,
        "status": "ok" if completed.returncode == 0 else f"failed:{completed.returncode}",
        "domain": str(experiment.domain.relative_to(root)),
        "problem": str(experiment.problem.relative_to(root)),
        "landmark_file": str(landmark_path.relative_to(root)),
        "report": str((report_dir / f"{experiment.name}_report.md").relative_to(root)),
        "landmark_count": parsed["landmark_count"],
        "simple_count": parsed["simple_count"],
        "disjunctive_count": parsed["disjunctive_count"],
        "belief_landmark_count": parsed["belief_landmark_count"],
        "goal_count": parsed["goal_count"],
        "order_edge_count": parsed["order_edge_count"],
    }


def write_summary(rows: Iterable[Dict[str, object]], path: Path) -> None:
    rows = list(rows)
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "name",
        "status",
        "domain",
        "problem",
        "landmark_file",
        "report",
        "landmark_count",
        "simple_count",
        "disjunctive_count",
        "belief_landmark_count",
        "goal_count",
        "order_edge_count",
    ]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def _load_simple_yaml_list(path: Path) -> List[Dict[str, str]]:
    """Read the small YAML subset used by experiments.yaml.

    This avoids adding a PyYAML dependency. It supports:
      experiments:
        - name: foo
          domain: path
          problem: path
    """
    entries: List[Dict[str, str]] = []
    current: Optional[Dict[str, str]] = None

    for line_no, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        stripped = line.strip()
        if stripped in {"experiments:", "domains:"}:
            continue
        if stripped.startswith("- "):
            if current is not None:
                entries.append(current)
            current = {}
            rest = stripped[2:].strip()
            if rest:
                key, value = _parse_key_value(rest, path, line_no)
                current[key] = value
            continue
        if current is None:
            raise ValueError(f"{path}:{line_no}: expected '- name: ...'")
        key, value = _parse_key_value(stripped, path, line_no)
        current[key] = value

    if current is not None:
        entries.append(current)
    return entries


def _parse_key_value(text: str, path: Path, line_no: int) -> tuple[str, str]:
    if ":" not in text:
        raise ValueError(f"{path}:{line_no}: expected 'key: value', got {text!r}")
    key, value = text.split(":", 1)
    return key.strip(), value.strip().strip("'\"")


def main() -> int:
    root = repo_root()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=root / "experiments.yaml")
    parser.add_argument("--results-dir", type=Path, default=root / "results")
    parser.add_argument("--build", default="release64")
    parser.add_argument("--search", default=DEFAULT_SEARCH)
    parser.add_argument("--only", nargs="*", help="Run only these experiment names")
    parser.add_argument("--dry-run", action="store_true", help="Print/record commands without running")
    parser.add_argument("--stop-on-error", action="store_true")
    args = parser.parse_args()

    experiments = load_experiments(args.config.resolve(), root)
    if args.only:
        wanted = set(args.only)
        experiments = [experiment for experiment in experiments if experiment.name in wanted]
        missing = wanted - {experiment.name for experiment in experiments}
        if missing:
            raise ValueError(f"Unknown experiment name(s): {sorted(missing)}")

    rows: List[Dict[str, object]] = []
    for experiment in experiments:
        if not experiment.domain.exists():
            raise FileNotFoundError(experiment.domain)
        if not experiment.problem.exists():
            raise FileNotFoundError(experiment.problem)

        print(f"[RUN] {experiment.name}")
        row = run_experiment(
            experiment,
            root=root,
            results_dir=args.results_dir.resolve(),
            build=args.build,
            search=args.search,
            dry_run=args.dry_run,
        )
        rows.append(row)
        print(
            f"[{row['status']}] {experiment.name}: "
            f"{row['landmark_count']} landmarks, "
            f"{row['disjunctive_count']} disjunctive"
        )
        if args.stop_on_error and str(row["status"]).startswith("failed:"):
            break

    summary_name = "summary_dry_run.csv" if args.dry_run else "summary.csv"
    summary_path = args.results_dir.resolve() / summary_name
    write_summary(rows, summary_path)
    print(f"[OK] summary: {summary_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
