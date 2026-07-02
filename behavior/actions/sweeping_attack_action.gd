extends Action

const sweeping_attack_scene = preload("res://behavior/actions/scenes/sweeping_attack.tscn")

var sweeping_attack: ActionScene

func _init():
	max_distance = 40
	prepare_time = 0.2
	cooldown = 4.0
	focus_cost = 3

func post_prepare():
	_sweeping_attack()

func _sweeping_attack():
	sweeping_attack = spawn_melee_attack(sweeping_attack_scene, 25.0)
	Global.get_tree().create_timer(0.8, false).timeout.connect(action_finished)

func description():
	return "Performs a sweeping sword attack that hits all enemies in an area, causing 5 slashing damage"
