@tool
extends EditorScript

var skill_base_path = "res://skill_tree/skills"
var trees_base_path = "res://skill_tree/trees"
var tree_names = ["general", "warrior"]

func _run():
	create_skill_trees()

func load_skill_dir(dir_path: String) -> SkillCollection:
	var skill_collection = SkillCollection.new()
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			print("  Loading %s" % filename)
			var skill = load(dir_path + "/" + filename) as Skill
			skill_collection.add(skill)
			filename = dir.get_next()
	return skill_collection
	
func create_skill_trees():
	for tree_name in tree_names:
		print("%s: Finding skills" % tree_name)
		var dir_path = skill_base_path + "/" + tree_name
		var skill_collection = load_skill_dir(dir_path)
		skill_collection.validate()
		print("%s: Writing collection with %d skills" % [tree_name, skill_collection.size()])
		var tree_dir_path = trees_base_path + "/" + tree_name
		DirAccess.make_dir_absolute(tree_dir_path)
		ResourceSaver.save(skill_collection, tree_dir_path + "/skill_collection.tres")
