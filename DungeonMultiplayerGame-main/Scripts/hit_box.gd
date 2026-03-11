class_name HitBox
extends Area2D

@export var damage: int = 10
var shooter = null

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
