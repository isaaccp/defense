#!/usr/bin/env python3
"""
Print a sim summary's events as one terse line each.

Usage:
    tools/sim/events.py <summary.json>
    tools/sim/events.py <summary.json> --kind death,low_hp   # filter

Output format:
    t=  9.17  death     Puffin@(331,339)  <- Orc Archer
    t= 17.55  loss      TOWER_DIED
"""
import json
import sys


def fmt_pos(at):
    if not at:
        return ""
    return f"@({at['x']},{at['y']})"


def fmt_event(ev):
    t = ev.get("t", 0.0)
    kind = ev.get("kind", "?")
    actor = ev.get("actor", "")
    pos = fmt_pos(ev.get("at"))
    if kind == "spawn":
        body = f"{actor}{pos}"
    elif kind == "death":
        body = f"{actor}{pos}  <- {ev.get('killed_by', '?')}"
    elif kind == "low_hp":
        body = f"{actor}{pos}  {ev.get('hp_pct', '?')}%"
    elif kind == "victory":
        body = ev.get("victory_type", "")
    elif kind == "loss":
        body = ev.get("loss_type", "")
    else:
        body = " ".join(f"{k}={v}" for k, v in ev.items() if k not in {"t", "kind"})
    return f"t={t:>6.2f}  {kind:<9} {body}"


def main():
    if len(sys.argv) < 2:
        print("Usage: events.py <summary.json> [--kind k1,k2,...]", file=sys.stderr)
        sys.exit(1)
    path = sys.argv[1]
    filter_kinds = None
    for i, a in enumerate(sys.argv[2:], start=2):
        if a == "--kind" and i + 1 < len(sys.argv):
            filter_kinds = set(sys.argv[i + 1].split(","))
    with open(path) as f:
        summary = json.load(f)
    for ev in summary.get("events", []):
        if filter_kinds and ev.get("kind") not in filter_kinds:
            continue
        print(fmt_event(ev))


if __name__ == "__main__":
    main()
