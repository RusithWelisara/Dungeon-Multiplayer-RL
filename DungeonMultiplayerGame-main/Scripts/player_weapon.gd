class_name WeaponCode
extends Node

# Pickups
const PISTOL_WEAPON = preload("res://scenes/Guns/pistol.tscn")
const REVOLVER_WEAPON = preload("res://scenes/Guns/revolver.tscn")


@onready var weapon_holder: Node2D = $"../../WeaponHolder"
@onready var pickup_detector: PickupDetector = $"../../PickupDetector"
@onready var player_ui: Control = $"../../UI/PlayerUI"

var current_pickable_item: String
var weapon_equipped: bool

signal update_pickup_text (text: String)

func _ready() -> void:
	setup_variabels()
	weapon_holder.fire_btn = owner.input_shoot

func _physics_process(delta: float) -> void:
	if not weapon_equipped and pickup_detector.current_available_item != null and is_instance_valid(pickup_detector.current_available_item):
		_update_pickups(pickup_detector.current_available_item.ITEM_NAME, pickup_detector.current_available_item.IS_WEAPON)

func check_input() -> void:
	pass

func setup_variabels():
	current_pickable_item = ""
	pickup_detector.picked_up.connect(_update_pickups)
	
	if weapon_holder.get_child_count() != 0: weapon_equipped = true

func _update_pickups(_name: String, _is_weapon: bool) -> void:
	if _is_weapon:
		if _name == "Nothing":
			update_pickup_text.emit("")
			current_pickable_item = ""
		else:
			if weapon_equipped:
				return
				
			current_pickable_item = _name
			print("Automatically picking up: " + current_pickable_item)
			pickup_weapon(current_pickable_item)
			
			if pickup_detector.current_available_item != null and is_instance_valid(pickup_detector.current_available_item):
				pickup_detector.current_available_item.get_parent().queue_free()
				pickup_detector.current_available_item = null

func update_ammo_text(_text: String) -> void:
	player_ui.update_ammo_text(_text)

func pickup_weapon(_item: String) -> void:
	if weapon_equipped:
		for child in weapon_holder.get_children():
			child.queue_free()
		weapon_equipped = false

	equip(_item)

func equip(_item: String) -> void:
	match _item:
		"Pistol":
			var weapon = PISTOL_WEAPON.instantiate()
			weapon.name = current_pickable_item
			weapon_holder.add_child(weapon)
			weapon_equipped = true
			if owner.get("ai_controller") and owner.ai_controller:
				if owner.ai_controller.control_mode == owner.ai_controller.ControlModes.TRAINING:
					owner.ai_controller.reward += 0.5
			#weapon.scale = weapon_holder.scale
		"Revolver":
			var weapon = REVOLVER_WEAPON.instantiate()
			weapon.name = current_pickable_item
			weapon_holder.add_child(weapon)
			weapon_equipped = true
			if owner.get("ai_controller") and owner.ai_controller:
				if owner.ai_controller.control_mode == owner.ai_controller.ControlModes.TRAINING:
					owner.ai_controller.reward += 0.5

