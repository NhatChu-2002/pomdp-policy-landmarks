#!/usr/bin/env python3
"""Parse Fast Downward landmark output into JSON, CSV, and a short report.

The parser accepts either full Fast Downward logs or files filtered to lines
containing "LM ". It records each top-level landmark once and also keeps the
ordering edges shown under each landmark when those lines are present.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple


LANDMARK_RE = re.compile(
    r"^LM\s+(?P<id>\d+)\s+(?P<body>.*?)\s+Achievers\s+"
    r"\((?P<ach_min>\d+),\s*(?P<ach_max>\d+)\)"
)
ORDER_RE = re.compile(
    r"^(?P<direction><-|->)_(?P<order>[A-Za-z_]+)\s+LM\s+(?P<target>\d+)"
)
FACT_RE = re.compile(
    r"(?P<atom_type>Atom|NegatedAtom)\s+"
    r"(?P<fact>.*?)\s+"
    r"\((?P<sas_var>var\d+)\((?P<sas_index>\d+)\)->(?P<sas_value>-?\d+)\)"
)


def parse_landmark_text(text: str, *, source: Optional[str] = None) -> Dict[str, Any]:
    landmarks_by_id: Dict[int, Dict[str, Any]] = {}
    order_edges: List[Dict[str, Any]] = []
    current_id: Optional[int] = None

    for raw_line in text.splitlines():
        stripped = raw_line.strip()
        if not stripped:
            continue

        if stripped.startswith("LM "):
            landmark = _parse_landmark_line(stripped)
            if landmark is None:
                continue
            current_id = landmark["id"]
            landmarks_by_id.setdefault(current_id, landmark)
            continue

        if current_id is not None:
            edge = _parse_order_line(stripped, current_id)
            if edge is not None:
                order_edges.append(edge)

    landmarks = [landmarks_by_id[key] for key in sorted(landmarks_by_id)]
    order_edges = _dedupe_edges(order_edges)

    result = {
        "source": source,
        "landmark_count": len(landmarks),
        "simple_count": sum(1 for lm in landmarks if lm["kind"] != "disjunctive"),
        "disjunctive_count": sum(1 for lm in landmarks if lm["kind"] == "disjunctive"),
        "goal_count": sum(1 for lm in landmarks if lm["is_goal"]),
        "order_edge_count": len(order_edges),
        "landmarks": landmarks,
        "order_edges": order_edges,
    }
    result["belief_landmark_count"] = len(find_belief_landmarks(landmarks))
    return result


def parse_landmark_file(path: Path) -> Dict[str, Any]:
    text = path.read_text(encoding="utf-8", errors="replace")
    return parse_landmark_text(text, source=str(path))


def write_json(parsed: Dict[str, Any], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(parsed, indent=2), encoding="utf-8")


def write_csv(parsed: Dict[str, Any], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "id",
                "kind",
                "fact_count",
                "facts",
                "sas_variables",
                "is_goal",
                "achievers_min",
                "achievers_max",
                "raw",
            ],
        )
        writer.writeheader()
        for lm in parsed["landmarks"]:
            facts = lm["facts"]
            writer.writerow(
                {
                    "id": lm["id"],
                    "kind": lm["kind"],
                    "fact_count": len(facts),
                    "facts": "; ".join(fact["fact"] for fact in facts),
                    "sas_variables": "; ".join(
                        f'{fact["sas_var"]}->{fact["sas_value"]}' for fact in facts
                    ),
                    "is_goal": lm["is_goal"],
                    "achievers_min": lm["achievers"][0],
                    "achievers_max": lm["achievers"][1],
                    "raw": lm["raw"],
                }
            )


def write_report(parsed: Dict[str, Any], path: Path, *, name: Optional[str] = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    title = name or Path(str(parsed.get("source") or "landmarks")).stem
    belief_landmarks = find_belief_landmarks(parsed["landmarks"])
    top_disjunctive = [lm for lm in parsed["landmarks"] if lm["kind"] == "disjunctive"]

    lines = [
        f"# Landmark Report: {title}",
        "",
        "## Summary",
        "",
        f"- Total landmarks: {parsed['landmark_count']}",
        f"- Simple landmarks: {parsed['simple_count']}",
        f"- Disjunctive landmarks: {parsed['disjunctive_count']}",
        f"- Goal landmarks: {parsed['goal_count']}",
        f"- Ordering edges parsed: {parsed['order_edge_count']}",
        f"- Belief-related landmarks: {parsed['belief_landmark_count']}",
        "",
        "## Belief-Related Landmarks",
        "",
    ]

    if belief_landmarks:
        for lm in belief_landmarks[:20]:
            lines.append(f"- LM {lm['id']}: {summarize_landmark(lm)}")
        if len(belief_landmarks) > 20:
            lines.append(f"- ... {len(belief_landmarks) - 20} more")
    else:
        lines.append("- None detected by the current keyword heuristic.")

    lines.extend(["", "## Disjunctive Landmarks", ""])
    if top_disjunctive:
        for lm in top_disjunctive[:20]:
            lines.append(f"- LM {lm['id']}: {summarize_landmark(lm)}")
        if len(top_disjunctive) > 20:
            lines.append(f"- ... {len(top_disjunctive) - 20} more")
    else:
        lines.append("- None.")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def find_belief_landmarks(landmarks: Iterable[Dict[str, Any]]) -> List[Dict[str, Any]]:
    keywords = (
        "k(",
        "k-",
        "belief",
        "committed",
        "diagnosed",
        "confirmed",
        "assessed",
    )
    result = []
    for lm in landmarks:
        text = " ".join(fact["fact"].lower() for fact in lm["facts"])
        if any(keyword in text for keyword in keywords):
            result.append(lm)
    return result


def summarize_landmark(landmark: Dict[str, Any]) -> str:
    facts = [fact["fact"] for fact in landmark["facts"]]
    if landmark["kind"] == "disjunctive":
        return " OR ".join(facts)
    return facts[0] if facts else landmark["raw"]


def _parse_landmark_line(line: str) -> Optional[Dict[str, Any]]:
    match = LANDMARK_RE.search(line)
    if not match:
        return None

    body = match.group("body")
    facts = [_fact_to_dict(fact_match) for fact_match in FACT_RE.finditer(body)]
    if body.startswith("disj"):
        kind = "disjunctive"
    elif body.startswith("NegatedAtom"):
        kind = "negated_atom"
    elif body.startswith("Atom"):
        kind = "atom"
    else:
        kind = "unknown"

    return {
        "id": int(match.group("id")),
        "kind": kind,
        "is_goal": "(goal)" in line,
        "achievers": [int(match.group("ach_min")), int(match.group("ach_max"))],
        "facts": facts,
        "raw": line,
    }


def _parse_order_line(line: str, current_id: int) -> Optional[Dict[str, Any]]:
    match = ORDER_RE.search(line)
    if not match:
        return None

    target_id = int(match.group("target"))
    direction = match.group("direction")
    order = match.group("order")
    if direction == "<-":
        source, target = target_id, current_id
    else:
        source, target = current_id, target_id

    return {
        "from": source,
        "to": target,
        "order": order,
        "raw": line,
    }


def _fact_to_dict(match: re.Match[str]) -> Dict[str, Any]:
    return {
        "atom_type": match.group("atom_type"),
        "fact": match.group("fact").strip(),
        "sas_var": match.group("sas_var"),
        "sas_index": int(match.group("sas_index")),
        "sas_value": int(match.group("sas_value")),
    }


def _dedupe_edges(edges: Iterable[Dict[str, Any]]) -> List[Dict[str, Any]]:
    seen: set[Tuple[int, int, str]] = set()
    result = []
    for edge in edges:
        key = (edge["from"], edge["to"], edge["order"])
        if key in seen:
            continue
        seen.add(key)
        result.append(edge)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("landmark_file", type=Path)
    parser.add_argument("--name", help="Experiment name for the report title")
    parser.add_argument("--out-json", type=Path)
    parser.add_argument("--out-csv", type=Path)
    parser.add_argument("--out-report", type=Path)
    args = parser.parse_args()

    parsed = parse_landmark_file(args.landmark_file)
    if args.out_json:
        write_json(parsed, args.out_json)
    if args.out_csv:
        write_csv(parsed, args.out_csv)
    if args.out_report:
        write_report(parsed, args.out_report, name=args.name)

    print(
        "Parsed "
        f"{parsed['landmark_count']} landmarks "
        f"({parsed['disjunctive_count']} disjunctive, "
        f"{parsed['belief_landmark_count']} belief-related)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
