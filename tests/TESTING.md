# Testing

This project uses [GUT (Godot Unit Test)](https://github.com/bitwes/Gut) for testing. Due to the high execution time of the full test suite (which heavily simulates gameplay, movement, and timing), we have split the tests into two distinct categories to enable a fast Test-Driven Development (TDD) workflow.

## 1. Unit Tests (`tests/unit/`)
These are pure logic tests. They do not simulate gameplay, spawn scenes with physical components, or use `await wait_seconds(...)`. 
- **Execution Time**: ~0.5 seconds
- **When to run**: Constantly. Your TDD loop should be built around these. 
- **How to run**: By default, the `.gutconfig.json` file is configured to *only* run the `tests/unit/` directory. You can run them via the GUT UI panel in the editor or via CLI using `gut`.

## 2. Integration Tests (`tests/integration/`)
These tests spawn actual gameplay scenes (e.g. dummy levels, dummy characters) and use `await` to verify movement, action execution, and physics over time. Because they simulate real game time, they are significantly slower.
- **Execution Time**: ~40 seconds (accelerated)
- **When to run**: At the end of a session, before committing, or when specifically working on physical interactions like action distance thresholds or `BehaviorComponent` evaluations.
- **How to run**: Use the `run_integration_tests.sh` bash script in the root directory. This script uses a secondary config (`.gutconfig_integration.json`) and forces Godot to run with `--time-scale 2.0`, safely cutting the test execution time in half without breaking physics engine calculations.
