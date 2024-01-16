@tool
extends EditorScript

var skill_tree_base_path = "res://skill_tree"

# Output for trees.
var trees_base_path = "res://skill_tree/trees"

# Output for e.g. set of actions, etc.
var skill_type_collections_path = "res://skill_tree/skill_type_collections"

# Could just do all except unspecified for simplicity.
var skill_types = [
	Skill.SkillType.ACTION,
	Skill.SkillType.TARGET,
	Skill.SkillType.CONDITION,
	Skill.SkillType.TARGET_SORT,
]

var tree_types = [
	SkillTree.TreeType.GENERAL,
	SkillTree.TreeType.WARRIOR,
	SkillTree.TreeType.ROGUE,
	SkillTree.TreeType.CLERIC,
	SkillTree.TreeType.WIZARD,
]

# To ensure there is no duplicate names.
var skill_names = {}

func _show_error(error: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Error in skill tree tool"
	dialog.dialog_text = error
	EditorInterface.popup_dialog_centered(dialog)

func _run():
	create_skill_trees()

# TODO: Do some checking for skill type.
func load_skill_type_dir(trees: Dictionary, base_path: String, skill_type: Skill.SkillType):
	var collection = SkillTypeCollection.new()
	var skill_fs_string = Skill.skill_type_filesystem_string(skill_type)
	var dir_path = base_path + "/" + skill_fs_string + "s"
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			if not filename.ends_with(".tres"):
				_show_error("Found unexpected file %s" % filename)
				return
			print("  Loading %s" % filename)
			var skill = load(dir_path + "/" + filename) as Skill
			if skill.skill_name in skill_names:
				_show_error("Duplicate skill name: %s (processing: %s, found before in: %s)" % [skill.skill_name, skill.resource_path, skill_names[skill.skill_name]])
				return
			skill_names[skill.skill_name] = skill.resource_path
			assert(skill.skill_type == skill_type, "wrong skill type")
			collection.add(skill)
			var skill_tree = trees[skill.tree_type]
			skill_tree.add(skill)
			filename = dir.get_next()
	print("%s: Writing skill type collection with %d skills" % [skill_fs_string, collection.size()])
	var collection_path = "%s/%s_collection.tres" % [skill_type_collections_path, skill_fs_string]
	print("%s: %s" % [skill_fs_string, collection_path])
	ResourceSaver.save(collection, collection_path)

func create_skill_trees():
	var num_skills = 0
	var skill_tree_collection = SkillTreeCollection.new()
	var trees = {}
	for tree_type in tree_types:
		var skill_tree = SkillTree.new()
		skill_tree.tree_type = tree_type
		trees[tree_type] = skill_tree

	for skill_type in skill_types:
		print("%s: Finding skills" % Skill.skill_type_filesystem_string(skill_type))
		load_skill_type_dir(trees, skill_tree_base_path, skill_type)

	for tree_type in tree_types:
		var skill_tree = trees[tree_type]
		var tree_name = SkillTree.tree_type_filesystem_string(tree_type)
		print("%s: Writing skill tree with %d skills" % [tree_name, skill_tree.size()])
		var tree_dir_path = trees_base_path + "/" + tree_name
		DirAccess.make_dir_absolute(tree_dir_path)
		var skill_tree_path = "%s/%s_skill_tree.tres" % [tree_dir_path, tree_name]
		print("%s: %s" % [tree_name, skill_tree_path])
		ResourceSaver.save(skill_tree, skill_tree_path)
		var loaded_skill_tree = load(skill_tree_path) as SkillTree
		skill_tree_collection.add(loaded_skill_tree)
		num_skills += skill_tree.size()
	# TODO: Do one last validation to make sure some invariants are respected.
	print("Writing skill tree collection with %d trees, %d skills" % [skill_tree_collection.size(), num_skills])
	var skill_tree_collection_path = trees_base_path + "/skill_tree_collection.tres"
	ResourceSaver.save(skill_tree_collection, skill_tree_collection_path)
	print(skill_tree_collection_path)
