# Creating a New Enemy

Use `enemies/orc_berserker/orc_berserker.tscn` as a reference — it was written by hand with readable sub_resource IDs.

## Steps

### 1. Create a directory and scene file

```
enemies/my_enemy/my_enemy.tscn
```

Copy `orc_berserker.tscn` as a starting point. You need to change:

- The scene-level `uid=` to something fresh (or delete the attribute — Godot will assign one on first load)
- `[node name="OrcBerserker" ...]` → your new node name
- `actor_name = "Orc Berserker"` → your display name
- Sprite textures and frame counts (see below)
- Behavior rules (see below)
- Stats (see below)

### 2. Wire up sprites

Add three `ext_resource` entries for your textures. Get the UID from the `.import` file next to each PNG:

```
head -5 path/to/Sprite-Sheet.png.import   # → uid="uid://..."
```

Then in each animation sub_resource, set the texture, `hframes`, `vframes`, and `frame` keyframes to match your sheet.

| Animation key | Loop? | Notes |
|---|---|---|
| `RESET` | — | Just sets `offset`; sets the resting state |
| `death` | No | Plays once on death |
| `idle` | Yes | Shown when no movement action is running |
| `run` | Yes | Shown while moving |

All animation track paths are relative to AnimationComponent (the AnimationPlayer's parent), so they look like `NodePath("../Sprite2D:texture")`.

Frame keyframes example for a 6-frame run strip at 0.1s each:
```gdscript
"times": PackedFloat32Array(0, 0.1, 0.2, 0.3, 0.4, 0.5),
"values": [0, 1, 2, 3, 4, 5]
```

### 3. Define the behavior

Rules are evaluated top-to-bottom each frame; the first one that passes wins. Each rule has three parts — condition, target, action — all looked up by **StringName** at runtime. No UIDs or paths needed.

**skill_type values:** `1` = Action, `2` = Target, `3` = Condition, `4` = Target Sort

Minimal rule (sub_resources in the scene):

```
[sub_resource type="Resource" id="Resource_my_params"]
script = ExtResource("6_params")       # skill_params.gd

[sub_resource type="Resource" id="Resource_my_action"]
script = ExtResource("7_spskill")      # stored_param_skill.gd
params = SubResource("Resource_my_params")
name = &"Sword Attack"                 # must match skill_name in the .tres
skill_type = 1

[sub_resource type="Resource" id="Resource_cf"]
script = ExtResource("9_sskill")       # stored_skill.gd
name = &"Closest First"
skill_type = 4

[sub_resource type="Resource" id="Resource_my_target_params"]
script = ExtResource("6_params")
editor_string = "Enemy ({sort})"
sort = SubResource("Resource_cf")

[sub_resource type="Resource" id="Resource_my_target"]
script = ExtResource("7_spskill")
params = SubResource("Resource_my_target_params")
name = &"Enemy"
skill_type = 2

[sub_resource type="Resource" id="Resource_my_rule"]
script = ExtResource("8_ruledef")      # rule_def.gd
target_selection = SubResource("Resource_my_target")
action = SubResource("Resource_my_action")
# Omit `condition` (or use an empty `conditions` array) for rules that fire unconditionally.
```

You can share `params` and `sort` sub_resources across multiple rules (orc_berserker.tscn does this).

Then wire all rules into the behavior:

```
[sub_resource type="Resource" id="Resource_behavior"]
script = ExtResource("5_behav")        # stored_behavior.gd
stored_rules = Array[ExtResource("8_ruledef")]([SubResource("Resource_rule1"), SubResource("Resource_rule2")])
```

See `behavior/BEHAVIOR.md` for the full list of available skills and how action params (range, cooldown, etc.) and condition params work.

### 4. Set attributes

```
[sub_resource type="Resource" id="Resource_attributes"]
script = ExtResource("10_attr")        # attributes.gd
speed = 35.0
health = 6
```

To add armor, add `resistance.gd` as an ext_resource and set a `resistance` property on the attributes resource — see `skeleton_warrior.tscn` for the pattern.

### 5. Document it

Add an entry to `enemies/ENEMIES.md` with the stat table and behavior list.
