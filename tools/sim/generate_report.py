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
        out.write("# Focus Generation Report\n\n")
        out.write("## Overview\n")
        out.write("| Run Config | Outcome | Duration (s) | Tower Focus | Character Focus |\n")
        out.write("|------------|---------|--------------|-------------|-----------------|\n")
        
        for jf in sorted(json_files):
            with open(jf, "r") as f:
                data = json.load(f)
            
            name = os.path.basename(jf).replace(".json", "")
            outcome = data.get("outcome", "unknown")
            duration = data.get("elapsed_seconds", 0)
            
            towers = data.get("towers", [])
            tower_focus = sum(t.get("focus_generated", 0) for t in towers)
            
            chars = data.get("characters", [])
            char_focus_strs = []
            for c in chars:
                cname = c.get("name", "Unknown")
                cfocus = c.get("focus_generated", 0)
                char_focus_strs.append(f"{cname}: {cfocus}")
                
            char_focus_col = ", ".join(char_focus_strs) if char_focus_strs else "None"
            
            out.write(f"| {name} | {outcome} | {duration} | {tower_focus} | {char_focus_col} |\n")
            
    print(f"Report generated at: {OUTPUT_FILE}")

if __name__ == '__main__':
    main()
