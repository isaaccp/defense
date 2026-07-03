extends GutTest

const campaign_sim_runner_script = preload("res://tools/sim/campaign_sim_runner.gd")
const temp_save_path = "user://temp_campaign_save.tres"

func before_each():
	if FileAccess.file_exists(temp_save_path):
		DirAccess.remove_absolute(temp_save_path)

func after_each():
	if FileAccess.file_exists(temp_save_path):
		DirAccess.remove_absolute(temp_save_path)

func test_campaign_sim_start():
	var runner = campaign_sim_runner_script.new()
	runner.scene_tree = get_tree()
	runner.args = PackedStringArray([
		"--action=start",
		"--characters=cleric,warrior",
		"--seed=4242",
		"--save_path=" + temp_save_path
	])
	
	# Add to tree to run _ready
	add_child_autoqfree(runner)
	
	# Verify save file exists
	assert_true(FileAccess.file_exists(temp_save_path))
	
	# Load and verify state
	var rss := load(temp_save_path) as RunSaveState
	assert_not_null(rss)
	assert_eq(rss.current_stage, 1)
	assert_eq(rss.current_phase, RunSaveState.Phase.FIGHT)
	assert_eq(rss.gameplay_characters.size(), 2)
	assert_eq(rss.gameplay_characters[0].name, "Puffin")
	assert_eq(rss.gameplay_characters[1].name, "Godrick")
	assert_eq(rss.seed, 4242)
	assert_eq(rss.reward_schedule.size(), rss.level_provider.total_stages)

func test_campaign_sim_claim_reward_rest():
	# 1. Initialize
	var runner_start = campaign_sim_runner_script.new()
	runner_start.scene_tree = get_tree()
	runner_start.args = PackedStringArray([
		"--action=start",
		"--characters=cleric,warrior",
		"--seed=1111",
		"--save_path=" + temp_save_path
	])
	add_child_autoqfree(runner_start)
	
	var rss := load(temp_save_path) as RunSaveState
	
	# Artificially damage a character and set phase to REWARD
	rss.gameplay_characters[0].health = 10
	rss.current_phase = RunSaveState.Phase.REWARD
	ResourceSaver.save(rss, temp_save_path)
	
	# 2. Claim Path (assume path 0 contains Rest/Relic/Trainer)
	# Rest reward is stateless so it is guaranteed to apply correctly
	var runner_claim = campaign_sim_runner_script.new()
	runner_claim.scene_tree = get_tree()
	runner_claim.args = PackedStringArray([
		"--action=claim_reward",
		"--path_idx=0",
		"--save_path=" + temp_save_path,
		"--relic_recipient=Puffin" # in case it has relic
	])
	add_child_autoqfree(runner_claim)
	
	# 3. Reload and verify phase advanced to FIGHT and stage to 2
	var rss2 := load(temp_save_path) as RunSaveState
	assert_eq(rss2.current_stage, 2)
	assert_eq(rss2.current_phase, RunSaveState.Phase.FIGHT)
	assert_gt(rss2.gameplay_characters[0].health, 10, "Rest or recovery should have healed the Cleric")
