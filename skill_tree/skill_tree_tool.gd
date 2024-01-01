@tool
extends EditorScript

var skill_base_path = "res://skill_tree/skills"
var trees_base_path = "res://skill_tree/trees"
var tree_types = [
	SkillTree.TreeType.GENERAL,
	SkillTree.TreeType.WARRIOR,
	SkillTree.TreeType.ROGUE,
]

func _run():
	create_skill_trees()

func load_skill_dir(dir_path: String, tree_type: SkillTree.TreeType) -> SkillTree:
	var skill_tree = SkillTree.new()
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			print("  Loading %s" % filename)
			var skill = load(dir_path + "/" + filename) as Skill
			skill_tree.add(skill)
			filename = dir.get_next()
	return skill_tree

func create_skill_trees():
	var skill_tree_collection = SkillTreeCollection.new()
	for tree_type in tree_types:
		var tree_name = SkillTree.tree_type_filesystem_string(tree_type)
		print("%s: Finding skills" % tree_name)
		var dir_path = skill_base_path + "/" + tree_name
		var skill_tree = load_skill_dir(dir_path, tree_type)
		skill_tree.tree_type = tree_type
		skill_tree.validate()
		print("%s: Writing skill tree with %d skills" % [tree_name, skill_tree.size()])
		var tree_dir_path = trees_base_path + "/" + tree_name
		DirAccess.make_dir_absolute(tree_dir_path)
		var skill_tree_path = "%s/%s_skill_tree.tres" % [tree_dir_path, tree_name]
		print("%s: %s" % [tree_name, skill_tree_path])
		ResourceSaver.save(skill_tree, skill_tree_path)
		var loaded_skill_tree = load(skill_tree_path) as SkillTree
		skill_tree_collection.add(loaded_skill_tree)
	print("Writing skill tree collection with %d trees" % skill_tree_collection.size())
	var skill_tree_collection_path = trees_base_path + "/skill_tree_collection.tres"
	ResourceSaver.save(skill_tree_collection, skill_tree_collection_path)
	print(skill_tree_collection_path)
