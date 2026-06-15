import os
import json
import glob
from collections import defaultdict
RESULTS_DIR = "tools/sim/results"
REPORTS_DIR = "tools/sim/reports"
OUTPUT_FILE = os.path.join(REPORTS_DIR, "sim_report.md")

def main():
    json_files = glob.glob(os.path.join(RESULTS_DIR, "*.json"))
    if not json_files:
        print("No results found.")
        return
        
    os.makedirs(REPORTS_DIR, exist_ok=True)
    
    # Group files by level prefix
    levels = defaultdict(list)
    for jf in sorted(json_files):
        name = os.path.basename(jf).replace(".json", "")
        # The naming scheme seems to be level_name_pair.json
        # e.g., 01_archer_rush_cleric+rogue -> level_name = "01_archer_rush", pair = "cleric+rogue"
        parts = name.split("_")
        # We assume the last part is the pair
        pair = parts[-1]
        level_name = "_".join(parts[:-1])
        levels[level_name].append((pair, jf))
        
    with open(OUTPUT_FILE, "w") as out:
        out.write("# Simulation Report\n\n")
        
        for level_name, runs in levels.items():
            out.write(f"## {level_name}\n\n")
            
            for pair, jf in runs:
                with open(jf, "r") as f:
                    data = json.load(f)
                
                outcome = data.get("outcome", "unknown")
                duration = data.get("elapsed_seconds", 0)
                min_focus = data.get("min_focus", 0.0)
                
                out.write(f"### {pair}\n")
                out.write(f"**Result:** {outcome} ({duration}s) | **Min Focus:** {min_focus}\n\n")
                
                def write_actor(c):
                    cname = c.get("name", "Unknown")
                    hp_final = c.get("hp_final", 0)
                    hp_max = c.get("hp_max", 0)
                    dmg = c.get("damage_dealt", 0)
                    heal = c.get("damage_healed", 0)
                    fgen = c.get("focus_generated", 0)
                    fspent = c.get("focus_spent", 0)
                    status = "Alive" if c.get("alive", False) else "Dead"
                    out.write(f"* **{cname} ({status})** — HP: {hp_final}/{hp_max} | Dmg: {dmg} | Heal: {heal} | Focus: {fgen} (gen) / {fspent} (spent)\n")

                towers = data.get("towers", [])
                if towers:
                    write_actor(towers[0])
                    
                chars = data.get("characters", [])
                for c in chars:
                    write_actor(c)
                    
                out.write("\n")
            
    print(f"Report generated at: {OUTPUT_FILE}")

if __name__ == '__main__':
    main()
