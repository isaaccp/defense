@tool
extends Resource

class_name SkillTreeState

@export var skills: Array[StringName] = [&"Always", &"Enemy", &"Move To", &"Closest First"]:
	set(value):
		skills = value
		_process_skills()

# If set, all skills are available.
@export var full = false

var skills_by_name: Dictionary

var actions: Array[StringName]:
	get:
		if full:
			return SkillManager.all_actions()
		return _cast(skills_by_name[Skill.SkillType.ACTION].keys())

var target_selections: Array[StringName]:
	get:
		if full:
			return SkillManager.all_target_selections()
		return _cast(skills_by_name[Skill.SkillType.TARGET].keys())

var target_sorts: Array[StringName]:
	get:
		if full:
			return SkillManager.all_target_sorts()
		return _cast(skills_by_name[Skill.SkillType.TARGET_SORT].keys())

var conditions: Array[StringName]:
	get:
		if full:
			return SkillManager.all_conditions()
		return _cast(skills_by_name[Skill.SkillType.CONDITION].keys())

var meta_skills: Array[StringName]:
	get:
		if full:
			return SkillManager.all_meta_skills()
		return _cast(skills_by_name[Skill.SkillType.META_SKILL].keys())

func _init():
	for skill_type in Skill.SkillType.values():
		if skill_type == Skill.SkillType.UNSPECIFIED:
			continue
		skills_by_name[skill_type] = {}

func _process_skills():
	for skill_name in skills:
		var skill = SkillManager.lookup_skill(skill_name)
		skills_by_name[skill.skill_type][skill_name] = true

## Whether skill has been acquired/unlocked in the tree.
func available(skill: Skill) -> bool:
	if full:
		return true
	return skill.skill_name in skills_by_name[skill.skill_type]

## Whether skill is reachable in the tree (i.e., parent is
## available.
func reachable(skill: Skill) -> bool:
	if skill.parent and not available(skill.parent):
		return false
	return true

func mark_available(skill: Skill):
	assert(not available(skill), "Skill already available!")
	assert(skill.skill_type != Skill.SkillType.UNSPECIFIED)
	skills.append(skill.skill_name)
	skills_by_name[skill.skill_type][skill.skill_name] = true

# Used for tutorial levels, etc that need to add to a tree.
# TODO: Don't add duplicates.
# TODO: Fix so it refreshes the dictionaries, as otherwise it
# won't work for some use cases.
func add(other: SkillTreeState):
	skills += other.skills

# TODO: Remove if we ever have typed dictionaries.
func _cast(skill_names: Array) -> Array[StringName]:
	var names: Array[StringName] = []
	names.assign(skill_names)
	return names
