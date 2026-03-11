class_name HurtBox
extends Area2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	area_entered.connect(_on_area_entered)

func _on_area_entered(hitbox: HitBox) -> void:
	if hitbox == null:
		return
	
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.damage, hitbox.shooter)
