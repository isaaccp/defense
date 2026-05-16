#!/usr/bin/env python3
"""
Compare two sim summary JSONs and print what changed.

Usage:
    tools/sim/diff.py <summary_a.json> <summary_b.json>

Useful for "what's different between attempt N and attempt N+1?" — outcome
delta, time delta, per-character HP/damage delta, enemy kill delta, events
that fired in one run but not the other.
"""
import json
import sys
from pathlib import Path


def load(path):
    with open(path) as f:
        return json.load(f)


def fmt_delta(a, b, unit=""):
    """Format a numeric delta with sign + unit. None if equal."""
    if a == b:
        return None
    d = b - a
    sign = "+" if d > 0 else ""
    return f"{a}{unit} -> {b}{unit} ({sign}{d:g}{unit})"


def diff_actors(a_list, b_list, label):
    """Compare two lists of actor dicts by name (matched by index within same-name groups)."""
    lines = []
    # Pair up by name + occurrence index. Two "Godrick" entries pair by order.
    def keyed(actors):
        out = {}
        counts = {}
        for actor in actors:
            n = actor["name"]
            counts[n] = counts.get(n, 0) + 1
            key = f"{n}#{counts[n] - 1}"
            out[key] = actor
        return out
    a_map = keyed(a_list)
    b_map = keyed(b_list)
    all_keys = sorted(set(a_map) | set(b_map))
    for key in all_keys:
        a = a_map.get(key)
        b = b_map.get(key)
        if not a:
            lines.append(f"    + {key}: appears only in B")
            continue
        if not b:
            lines.append(f"    - {key}: appears only in A")
            continue
        sub = []
        for field, unit in [
            ("hp_final", "hp"),
            ("damage_dealt", "dmg"),
            ("enemies_killed", "kills"),
            ("damage_healed", "heal"),
        ]:
            d = fmt_delta(a.get(field, 0), b.get(field, 0), unit)
            if d:
                sub.append(f"{field} {d}")
        if a.get("alive") != b.get("alive"):
            sub.append(f"alive {a.get('alive')} -> {b.get('alive')}")
        if a.get("killed_by") != b.get("killed_by"):
            sub.append(f"killed_by {a.get('killed_by', '-')} -> {b.get('killed_by', '-')}")
        if sub:
            lines.append(f"    {key}: " + ", ".join(sub))
    if lines:
        print(f"  {label}:")
        for l in lines:
            print(l)


def diff_events(a_events, b_events):
    """Show counts per event-kind and any kinds unique to one side."""
    def counts(events):
        c = {}
        for e in events:
            c[e["kind"]] = c.get(e["kind"], 0) + 1
        return c
    a_c = counts(a_events)
    b_c = counts(b_events)
    kinds = sorted(set(a_c) | set(b_c))
    lines = []
    for k in kinds:
        d = fmt_delta(a_c.get(k, 0), b_c.get(k, 0))
        if d:
            lines.append(f"    {k}: {d}")
    if lines:
        print("  events (count by kind):")
        for l in lines:
            print(l)


def main():
    if len(sys.argv) != 3:
        print("Usage: diff.py <summary_a.json> <summary_b.json>", file=sys.stderr)
        sys.exit(1)
    a_path, b_path = sys.argv[1], sys.argv[2]
    a = load(a_path)
    b = load(b_path)

    print(f"A: {Path(a_path).name}  ({a.get('notes', '')})")
    print(f"B: {Path(b_path).name}  ({b.get('notes', '')})")
    print()

    # Outcome
    a_out = f"{a['outcome']} ({a.get('victory_type') or a.get('loss_type') or ''})"
    b_out = f"{b['outcome']} ({b.get('victory_type') or b.get('loss_type') or ''})"
    if a_out != b_out:
        print(f"  outcome: {a_out} -> {b_out}")
    else:
        print(f"  outcome: {a_out} (same)")

    # Time
    d = fmt_delta(a["elapsed_seconds"], b["elapsed_seconds"], "s")
    if d:
        print(f"  elapsed: {d}")

    # Enemies aggregate
    a_e = a["enemies"]
    b_e = b["enemies"]
    for field in ["spawned", "killed"]:
        d = fmt_delta(a_e.get(field, 0), b_e.get(field, 0))
        if d:
            print(f"  enemies {field}: {d}")

    # XP
    d = fmt_delta(a.get("xp_gained", 0), b.get("xp_gained", 0), "xp")
    if d:
        print(f"  xp_gained: {d}")

    # Per-actor
    diff_actors(a["characters"], b["characters"], "characters")
    diff_actors(a["towers"], b["towers"], "towers")

    # Event counts
    diff_events(a.get("events", []), b.get("events", []))


if __name__ == "__main__":
    main()
