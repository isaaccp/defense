import json

base_dirs = [
    "tools/sim/behaviors/level/02_corridor_pocket",
    "tools/sim/behaviors/level/02_warrior_press"
]

rogue_char = "res://character/playable_characters/larian_the_rogue.tres"
rogue_behavior = {
    "name": "rogue_snipe_and_stab",
    "rules": [
        {
            "action": { "name": "Sword Attack" },
            "target": { "name": "Enemy" },
            "sort": { "name": "Closest First" }
        },
        {
            "action": { "name": "Bow Attack" },
            "target": { "name": "Enemy" },
            "sort": { "name": "Closest First" }
        },
        {
            "action": { "name": "Move To" },
            "target": { "name": "Enemy" },
            "sort": { "name": "Closest First" }
        }
    ]
}

for d in base_dirs:
    # cleric+rogue
    with open(f"{d}/cleric+warrior.json") as f:
        data = json.load(f)
    data["characters"][0] = {
        "character": rogue_char,
        "acquired_skills": "full",
        "behavior": rogue_behavior
    }
    with open(f"{d}/cleric+rogue.json", "w") as f:
        json.dump(data, f, indent=2)
        
    # rogue+warrior (replace wizard with rogue in warrior+wizard)
    with open(f"{d}/warrior+wizard.json") as f:
        data = json.load(f)
    data["characters"][0] = {
        "character": rogue_char,
        "acquired_skills": "full",
        "behavior": rogue_behavior
    }
    with open(f"{d}/rogue+warrior.json", "w") as f:
        json.dump(data, f, indent=2)

    # rogue+wizard (replace cleric with rogue in cleric+wizard)
    with open(f"{d}/cleric+wizard.json") as f:
        data = json.load(f)
    data["characters"][0] = {
        "character": rogue_char,
        "acquired_skills": "full",
        "behavior": rogue_behavior
    }
    with open(f"{d}/rogue+wizard.json", "w") as f:
        json.dump(data, f, indent=2)
