import json
import os
import subprocess

RESULTS_DIR = "tools/sim/results"
CONFIGS_DIR = "tools/sim/configs"

won_configs = []

for filename in os.listdir(RESULTS_DIR):
    if not filename.endswith(".json"):
        continue
    filepath = os.path.join(RESULTS_DIR, filename)
    with open(filepath, "r") as f:
        data = json.load(f)
        if data.get("outcome") == "victory":
            won_configs.append(data.get("config_path", os.path.join(CONFIGS_DIR, filename)))

print(f"Found {len(won_configs)} winning configs.")

# Run them all
for config in won_configs:
    print(f"Running {config}...")
    subprocess.run(["/data/godot/bin/godot", "--headless", "-s", "tools/sim/sim.gd", config], capture_output=True)

print("Generating report...")

report_lines = [
    "# Simulation Run Report",
    "",
    "| Config | Still Winning? | Tower Focus Gen | Character Focus Gen |",
    "|--------|----------------|-----------------|---------------------|"
]

for config in won_configs:
    result_filename = os.path.basename(config)
    result_filepath = os.path.join(RESULTS_DIR, result_filename)
    
    with open(result_filepath, "r") as f:
        data = json.load(f)
    
    still_winning = data.get("outcome") == "victory"
    
    tower_focus = 0
    towers = data.get("towers", [])
    if towers:
        tower_focus = towers[0].get("focus_generated", 0)
        
    chars_focus = []
    for char in data.get("characters", []):
        focus = char.get("focus_generated", 0)
        chars_focus.append(f"{char.get('name')}: {focus}")
        
    report_lines.append(f"| `{result_filename}` | {'✅ Yes' if still_winning else '❌ No'} | {tower_focus} | {', '.join(chars_focus)} |")

with open("/home/isaac/.gemini/antigravity-cli/brain/7c104af2-917e-450d-9ecd-5a503820bd16/sim_report.md", "w") as f:
    f.write("\n".join(report_lines))

print("Report generated.")
