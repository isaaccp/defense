extends Resource

## Minimal data that needs to be saved for a rule in Behavior to be able to
## restore it.
class_name RuleSkillDef

## Skill identifier, can be ActionDef.Id, TargetSelectionDef.Id, etc.
@export var id: int
## The namespace are not disjoint, so need to know the type to restore.
@export var skill_type: Skill.SkillType
## Parameters configured for the skill.
@export var params: SkillParams
