#!/bin/sh

# We want to add the current_cycles file to the commit if modified, so
# running it as a shell script rather than a pre-commit hook.

cd $(git rev-parse --show-toplevel)
cycles_before=$(wc -l < current_cycles)
./deps.py . > /dev/null || exit 1
./dot_find_cycles.py --shortest-only Digraph.gv | sort > current_cycles || exit 1
cycles_after=$(wc -l < current_cycles)

git diff --exit-code current_cycles

[ "$?" = "1" ] && git add current_cycles

git commit -e -m "<commit message>

Commit Details

* Cycles before: ${cycles_before}, after: ${cycles_after}"
