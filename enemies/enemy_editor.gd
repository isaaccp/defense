@tool
extends Node2D

const enemy_scene = preload("res://enemies/enemy.tscn")

@export var config: EnemyConfig:
	set(value):
		print("Running setter")
		config = value
		_update_enemy()

var enemy: Enemy

func _ready():
	config = null
	for child in get_children():
		child.queue_free()

func _update_enemy():
	print("Running update enemy")
	if enemy:
		enemy.queue_free()
	if config:
		enemy = enemy_scene.instantiate() as Enemy
		enemy.config = config
		add_child(enemy)
		enemy.owner = self
		self.set_editable_instance(enemy, true)
		var animation_component = enemy.get_component_or_null(AnimationComponent) as AnimationComponent
		if animation_component:
			animation_component.play_animation("idle")
