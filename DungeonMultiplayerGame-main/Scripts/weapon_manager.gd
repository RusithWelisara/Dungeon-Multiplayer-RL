extends Node2D

@onready var weapon_check_timer: Timer = %weapon_check_timer

var gun: Weapon
var fire_btn: String = ""

func _ready() -> void:
	weapon_check_timer.timeout.connect(update_weaopns)

func _physics_process(delta: float) -> void:
	scale.x = owner.animation_code.dir
	if gun:
		fire()

func update_weaopns() -> void:
	if get_child_count() != 0:
		var _gun = get_child(0)
		if _gun and _gun.is_in_group("Weapon"):
			gun = _gun
			gun.player = owner
	else:
		gun = null

func fire() -> void:
	if owner.disable_shooting == true: return
	
	if owner.get("ai_controller") and owner.ai_controller and owner.ai_controller.control_mode != owner.ai_controller.ControlModes.HUMAN:
		if owner.ai_controller.shoot:
			gun.fire()
	else:
		if gun.data.auto_fire:
			if Input.is_action_pressed(fire_btn):
				gun.fire()
		else:
			if Input.is_action_just_pressed(fire_btn):
				gun.fire()
