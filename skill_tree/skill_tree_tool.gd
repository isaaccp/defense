@tool
extends EditorScript

var skill_tree_base_path = "res://skill_tree"

#Input for skills, to be removed.
var skill_base_path = "res://skill_tree/skills"
# Output for trees.
var trees_base_path = "res://skill_tree/trees"
# Output for e.g. set of actions, etc.
var skill_type_collections_path = "res://skill_tree/skill_type_collections"

var skill_types = [
	SkillBase.SkillType.ACTION,
]
var tree_types = [
	SkillTree.TreeType.GENERAL,
	SkillTree.TreeType.WARRIOR,
	SkillTree.TreeType.ROGUE,
	SkillTree.TreeType.CLERIC,
]

func _run():
	create_skill_trees()

func load_skill_dir(skill_tree: SkillTree, dir_path: String, tree_type: SkillTree.TreeType):
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			print("  Loading %s" % filename)
			var skill = load(dir_path + "/" + filename) as Skill
			skill_tree.add(skill)
			filename = dir.get_next()

# TODO: Do some checking for skill type.
func load_skill_type_dir(trees: Dictionary, base_path: String, skill_type: SkillBase.SkillType):
	var collection = SkillTypeCollection.new()
	var skill_fs_string = SkillBase.skill_type_filesystem_string(skill_type)
	var dir_path = base_path + "/" + skill_fs_string + "s"
	print(dir_path)
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			print("  Loading %s" % filename)
			var skill = load(dir_path + "/" + filename) as SkillBase
			assert(skill.skill_type == skill_type)
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

	print("Loading actions")
	load_skill_type_dir(trees, skill_tree_base_path, SkillBase.SkillType.ACTION)
	for tree_type in tree_types:
		var skill_tree = trees[tree_type]
		var tree_name = SkillTree.tree_type_filesystem_string(tree_type)
		print("%s: Finding skills" % tree_name)
		var dir_path = skill_base_path + "/" + tree_name
		load_skill_dir(skill_tree, dir_path, tree_type)
		print("%s: Writing skill tree with %d skills" % [tree_name, skill_tree.size()])
		var tree_dir_path = trees_base_path + "/" + tree_name
		DirAccess.make_dir_absolute(tree_dir_path)
		var skill_tree_path = "%s/%s_skill_tree.tres" % [tree_dir_path, tree_name]
		print("%s: %s" % [tree_name, skill_tree_path])
		ResourceSaver.save(skill_tree, skill_tree_path)
		var loaded_skill_tree = load(skill_tree_path) as SkillTree
		skill_tree_collection.add(loaded_skill_tree)
		num_skills += skill_tree.size()
	print("Writing skill tree collection with %d trees, %d skills" % [skill_tree_collection.size(), num_skills])
	var skill_tree_collection_path = trees_base_path + "/skill_tree_collection.tres"
	ResourceSaver.save(skill_tree_collection, skill_tree_collection_path)
	print(skill_tree_collection_path)
