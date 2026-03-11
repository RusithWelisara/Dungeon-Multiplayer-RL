class_name PickupItem
extends Area2D

@export var ITEM_NAME: String = "Pistol"
@export var IS_WEAPON: bool = true

func start():
	collision_layer = 8
	collision_mask = 0
