import os
import json
import glob

RESULTS_DIR = "tools/sim/results"
REPORTS_DIR = "tools/sim/reports"
OUTPUT_FILE = os.path.join(REPORTS_DIR, "sim_report.md")

def main():
    json_files = glob.glob(os.path.join(RESULTS_DIR, "*.json"))
    if not json_files:
        print("No results found.")
        return
        
    os.makedirs(REPORTS_DIR, exist_ok=True)
    
    with open(OUTPUT_FILE, "w") as out:
        out.write("# Simulation Report\n\n")
        out.write("## Overview\n")
        out.write("| Run Config | Result | Time | Min Focus | Tower | Character 1 | Character 2 |\n")
        out.write("|------------|--------|------|-----------|-------|-------------|-------------|\n")
        
        for jf in sorted(json_files):
            with open(jf, "r") as f:
                data = json.load(f)
            
            name = os.path.basename(jf).replace(".json", "")
            outcome = data.get("outcome", "unknown")
            duration = data.get("elapsed_seconds", 0)
            min_focus = data.get("min_focus", 0.0)
            
            def format_actor(c):
                cname = c.get("name", "Unknown")
                hp_final = c.get("hp_final", 0)
                hp_max = c.get("hp_max", 0)
                dmg = c.get("damage_dealt", 0)
                heal = c.get("damage_healed", 0)
                fgen = c.get("focus_generated", 0)
                fspent = c.get("focus_spent", 0)
                status = "Alive" if c.get("alive", False) else "Dead"
                return f"**{cname}** ({status})<br>HP: {hp_final}/{hp_max}<br>Dmg: {dmg}<br>Heal: {heal}<br>Focus: {fgen}/{fspent}"

            towers = data.get("towers", [])
            tower_str = format_actor(towers[0]) if towers else "-"
            
            chars = data.get("characters", [])
            char_strs = [format_actor(c) for c in chars]
                
            c1 = char_strs[0] if len(char_strs) > 0 else "-"
            c2 = char_strs[1] if len(char_strs) > 1 else "-"
            
            out.write(f"| {name} | {outcome} | {duration}s | {min_focus} | {tower_str} | {c1} | {c2} |\n")
            
    print(f"Report generated at: {OUTPUT_FILE}")

if __name__ == '__main__':
    main()
