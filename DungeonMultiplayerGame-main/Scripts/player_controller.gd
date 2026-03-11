class_name Player
extends CharacterBody2D

@export var CAMERA: Camera2D

@export var MAX_HP: int = 100 

@export var SPEED = 100.0
@export var JUMP_VELOCITY = -300.0
@export var IS_P1: bool = true

@onready var weapon_code: WeaponCode = %Weapon
@onready var animation_code: Node = %Animation
@onready var weapon_holder: Node2D = $WeaponHolder
@onready var hurtbox_collider: CollisionShape2D = $HurtBox/CollisionShape2D

@onready var ai_controller: Node2D = $Code/AIController2D

signal update_hp_bar (remaining_hp: int)

#InputKeys
var input_moveleft: String
var input_moveright: String
var input_jump: String
var input_pickup: String
var input_shoot: String


var hp: int = 100
var disable_shooting: bool = false

func _ready() -> void:
	disable_shooting = false
	hp = MAX_HP
	if ai_controller:
		ai_controller.init(self)
	input_setup()

func input_setup() -> void:
	if IS_P1:
		input_moveleft = "P1-left"
		input_moveright = "P1-right"
		input_jump = "P1-jump"
		input_pickup = "P1-pickup"
		input_shoot = "P1-shoot"
		
	else:
		input_moveleft = "P2-left"
		input_moveright = "P2-right"
		input_jump = "P2-jump"
		input_pickup = "P2-pickup"
		input_shoot = "P2-shoot"
	
	weapon_holder.fire_btn = input_shoot

func _process(delta: float) -> void:
	if Input.is_action_pressed("Esc"): get_tree().quit()

func _physics_process(delta: float) -> void:
	jump()
	move(delta)
	move_and_slide()
	
	if ai_controller and ai_controller.control_mode == ai_controller.ControlModes.TRAINING:
		ai_controller.reward -= 0.001
		var move_vec = velocity.normalized()
		if velocity.length() > 10.0:
			var has_gun = weapon_holder.get_child_count() > 0
			if not has_gun:
				var min_dist = INF
				var gun_pickup = null
				if get_parent():
					for child in get_parent().get_children():
						if "Drop" in child.name and not child.is_queued_for_deletion():
							var dist = global_position.distance_to(child.global_position)
							if gun_pickup == null or dist < min_dist:
								gun_pickup = child
								min_dist = dist
				if gun_pickup:
					var to_gun = (gun_pickup.global_position - global_position).normalized()
					if move_vec.dot(to_gun) > 0.5:
						ai_controller.reward += 0.01
			else:
				var enemy = null
				for node in get_tree().get_nodes_in_group("Player"):
					var p = node if node is CharacterBody2D else node.get_parent()
					if p != self and p != null and "hp" in p:
						enemy = p
						break
				if enemy:
					var to_enemy = (enemy.global_position - global_position).normalized()
					if move_vec.dot(to_enemy) > 0.5:
						ai_controller.reward += 0.01


func jump() -> void:
	if Input.is_action_pressed(input_jump) and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if ai_controller and ai_controller.control_mode != ai_controller.ControlModes.HUMAN:
		if ai_controller.jump.yes and is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif ai_controller.jump.no:
			pass

func move(delta: float) -> void:
	#gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var direction := Input.get_axis(input_moveleft, input_moveright)
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if ai_controller and ai_controller.control_mode != ai_controller.ControlModes.HUMAN:
		if ai_controller.move.left:
			velocity.x = SPEED
		elif ai_controller.move.right:
			velocity.x = -SPEED
		else:
			velocity.x = 0

func take_damage(damage: int, shooter = null) -> void:
	hp -= damage
	update_hp_bar.emit(hp)
	
	if shooter and shooter.get("ai_controller") and shooter.ai_controller != null:
		if shooter.ai_controller.control_mode == shooter.ai_controller.ControlModes.TRAINING:
			shooter.ai_controller.reward += 0.1
		
	if hp <= 0 and %GameManager.game_end == false:
		if shooter and shooter.get("ai_controller") and shooter.ai_controller != null:
			if shooter.ai_controller.control_mode == shooter.ai_controller.ControlModes.TRAINING:
				shooter.ai_controller.reward += 1.0
			
		if ai_controller and ai_controller.control_mode == ai_controller.ControlModes.TRAINING:
			ai_controller.reward -= 0.5
			
		%GameManager.end_game(IS_P1)
		if IS_P1: 
			Score.Player2Score += 1
		else: 
			Score.Player1Score += 1
			
		visible = false
		set_physics_process(false)
		set_process(false)
		disable_damage_collisions()

func disable_damage_collisions() -> void:
	hurtbox_collider.disabled = true

func take_screen_pos() -> Vector2:
	var screen_coords = get_viewport_transform() * global_position
	return screen_coords
