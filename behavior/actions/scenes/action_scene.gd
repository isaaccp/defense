extends Node2D

class_name ActionScene

signal hurtbox_hit(hurtbox: HurtboxComponent)

func _on_area_2d_area_entered(area: Area2D):
	var hurtbox = area as HurtboxComponent
	if not hurtbox:
		assert(false, "Unexpected hit area was not hurtbox")
	hurtbox_hit.emit(hurtbox)
