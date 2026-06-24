# Creating a New Enemy Type (Config-Centric Workflow)

In this project, individual enemy types **do not have their own scene files (`.tscn`)**. Instead, there is a single generic [enemy.tscn](file:///data/godot/games/defense/enemies/enemy.tscn) scene that is dynamically populated at runtime with a resource file of type [EnemyConfig](file:///data/godot/games/defense/components/data_types/enemy_config.gd) (`.tres`).

All visual creation, editing, and configuration of enemies is done using the visual editor scene [enemy_editor.tscn](file:///data/godot/games/defense/enemies/enemy_editor.tscn).

---

## Use Cases

### 1. Editing an Existing Enemy Config

If you want to modify stats, shapes, or behavior for an existing enemy:

1. Open [enemy_editor.tscn](file:///data/godot/games/defense/enemies/enemy_editor.tscn) in the Godot Editor.
2. In the Inspector, select the `EnemyEditor` root node.
3. Drag and drop the enemy's `.tres` file (e.g. [orc_grunt.tres](file:///data/godot/games/defense/enemies/orc_grunt/orc_grunt.tres)) into the `Config` property slot.
4. The tool will automatically instantiate the enemy preview in the 2D Viewport and expose its component nodes in the editor **Scene dock** (e.g. `CollisionShape2D`, `AnimationPlayer`, `AttributesComponent`, `BehaviorComponent`).
5. Perform edits:
   * **Collision Shapes**: Select `CollisionShape2D` (for movement) or `HurtboxComponent/CollisionShape2D` (for hit detection) and modify/resize shapes in the viewport.
   * **Attributes**: Select `AttributesComponent` and edit fields in `base_attributes` (health, speed, armor, etc.) in the Inspector.
   * **Behaviors**: Select `BehaviorComponent` and edit the rule definitions under `stored_behavior` in the Inspector.
   * **Animations**: Select `AnimationComponent/AnimationPlayer` and edit keyframes, textures, or frame coordinates using the native Godot **Animation panel** at the bottom of the editor.
6. Once finished, toggle the `save_config` checkbox on the `EnemyEditor` inspector properties. The tool will serialize all overrides from the preview nodes back into the loaded `.tres` resource file.

### 2. Creating a New Enemy Config from Scratch

If you want to design a completely new enemy type:

1. Open [enemy_editor.tscn](file:///data/godot/games/defense/enemies/enemy_editor.tscn) in the Godot Editor.
2. Select the `EnemyEditor` root node.
3. Click the dropdown on the `Config` property and select **New EnemyConfig**.
4. The editor will automatically spawn a generic preview enemy under the `EnemyEditor` node and initialize blank/default configurations for all sub-resources (shapes, attributes, behaviors, animation library) so you can edit them immediately.
5. In the Scene Tree dock, configure your new enemy:
   * Set the enemy's display name by editing `actor_name` on the instantiated `Enemy` node.
   * Assign and resize shapes for the root `CollisionShape2D` and `HurtboxComponent/CollisionShape2D`.
   * On the `AttributesComponent`, assign a new `Attributes` resource and define its base health, speed, and armor.
   * On the `BehaviorComponent`, assign a new `StoredBehavior` resource and add rule definitions (defining conditions, target selectors, and actions).
   * Select `AnimationComponent/AnimationPlayer`, add a new `AnimationLibrary`, and create animations named `idle` (looping), `run` (looping), and `death` (non-looping) mapping to your sprite sheet textures.
6. Enter your new save path in the `save_as_path` field (e.g. `res://enemies/orc_grunt/orc_shaman.tres`).
7. Toggle the `save_as_new_config` checkbox. The visual setup will be serialized and saved as a new `.tres` resource at the specified path.

---

## EnemyConfig Structural Fields

The [EnemyConfig](file:///data/godot/games/defense/components/data_types/enemy_config.gd) resource contains the following fields:

| Field | Type | Description |
|---|---|---|
| `name` | `String` | The display name of the enemy type (e.g., `"Orc Berserker"`). |
| `collision_shape` | `Shape2D` | The physical boundary used for movement collisions. |
| `attributes_component_config` | `AttributesComponentConfig` | Wraps an `Attributes` resource defining base health, speed, focus, focus regen, and armor. |
| `behavior_component_config` | `BehaviorComponentConfig` | Wraps a `StoredBehavior` resource defining the rule-based AI logic. |
| `hurtbox_component_config` | `HurtboxComponentConfig` | Wraps a `Shape2D` used for hit detection. |
| `animation_component_config` | `AnimationComponentConfig` | Wraps an `AnimationLibrary` containing the sprite animations. |

---

## Registering and Spawning the Enemy

Once you have created your `.tres` config file:

1. **Roster Documentation**: Add the stats and behavior descriptions to [ENEMIES.md](file:///data/godot/games/defense/enemies/ENEMIES.md).
2. **Level Spawning**: To spawn this enemy in a level, add a spawner to your level scene (under the `Spawners` node) and assign your new `.tres` config to the spawner's `enemy_config` property.
