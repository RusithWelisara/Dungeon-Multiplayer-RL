class_name Portal
extends Area2D

@export var linked_portal: Portal
@onready var teleport_pos: Node2D = $TeleportPos

signal teleport(tp_obj: Teleport)

func _init() -> void:
	# Check the linked pottal
	if teleport_pos == null:
		push_error("Add a node2d called 'TeleportPos' into your portal")
	
	# Setting collisiton details
	collision_layer = 0
	collision_mask = 16

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	linked_portal.teleport.connect(_on_teleport)

func _on_area_entered(area: Teleport):
	teleport.emit(area)

func _on_teleport(tp_obj: Teleport):
	var obj = tp_obj.owner
	obj.global_position.x = teleport_pos.global_position.x
