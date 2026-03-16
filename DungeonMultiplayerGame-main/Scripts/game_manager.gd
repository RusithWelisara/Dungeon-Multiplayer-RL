class_name GameManager
extends Node

# End Screen
@onready var winner_text: Label = $Screen/EndScreen/EndScreenText/Winner
@onready var end_screen_text: Control = $Screen/EndScreen/EndScreenText
@onready var iris_effect: ColorRect = $Screen/EndScreen/IrisEffect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal restart_anim_finished

# Shader
var player_screen_pos: Vector2 = Vector2(128.0, 112.0)
var iris_tracking: bool = false

# Logic
var can_restart: bool = false
var game_end: bool = false
var winner: int = 0

var pistol_spawn_pos: Vector2 = Vector2(-71, 16)
var revolver_spawn_pos: Vector2 = Vector2(83, 17)

const PISTOL_DROP = preload("res://scenes/GunDrops/pistol_drop.tscn")
const REVOLVER_DROP = preload("res://scenes/GunDrops/revolver_drop.tscn")

func _ready() -> void:
	game_end = false
	end_screen_text.visible = false
	iris_tracking = false
	winner = 0

	# Ensure start positions are saved on players
	for node in get_tree().get_nodes_in_group("Player"):
		var p = node if node is CharacterBody2D else node.get_parent()
		if p != null and not p.has_meta("start_pos"):
			p.set_meta("start_pos", p.global_position)

func end_game(is_p1_ded: bool) -> void:
	animation_player.play("game_over")
	iris_tracking = true
	game_end = true
	
	end_screen_text.visible = true
	can_restart = true
	if is_p1_ded:
		winner_text.text = "Player_2 Wins1!"
		winner = 2
		if %PinkBoii:
			%PinkBoii.disable_damage_collisions()
			%PinkBoii.disable_shooting = true
	else:
		winner_text.text = "Player_1 Wins!"
		winner = 1
		if %GreenBoii:
			%GreenBoii.disable_damage_collisions()
			%GreenBoii.disable_shooting = true
			
	# For AI training, automatically restart
	await get_tree().create_timer(1.5).timeout
	animation_player.play("restart")


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Restart") and can_restart:
		animation_player.play("restart")
	
	if iris_tracking:
		if winner == 1:
			player_screen_pos = %GreenBoii.take_screen_pos()
		elif winner == 2:
			player_screen_pos = %PinkBoii.take_screen_pos()
		iris_effect.material.set_shader_parameter("center", player_screen_pos)


func restart() -> void:
	game_end = false
	end_screen_text.visible = false
	iris_tracking = false
	winner = 0
	
	# Clear active projectiles
	for bullet in get_parent().get_children():
		if "Bullet" in bullet.name or bullet.is_in_group("Bullet"):
			bullet.queue_free()
			
	# Respawn players softly
	for node in get_tree().get_nodes_in_group("Player"):
		var p = node if node is CharacterBody2D else node.get_parent()
		if p == null or not p.has_method("take_damage"):
			continue
			
		if p.has_meta("start_pos"):
			p.global_position = p.get_meta("start_pos")
		p.hp = p.MAX_HP
		p.visible = true
		p.disable_shooting = false
		p.hurtbox_collider.set_deferred("disabled", false)
		p.set_physics_process(true)
		p.set_process(true)
		
		# Drop current weapons
		if p.weapon_holder.get_child_count() > 0:
			for child in p.weapon_holder.get_children():
				child.queue_free()
			p.weapon_code.weapon_equipped = false
			p.weapon_holder.gun = null
		p.update_hp_bar.emit(p.hp)
		
		if p.get("ai_controller") and p.ai_controller:
			p.ai_controller.done = true
			
	# Remove old drops if any
	for node in %GreenBoii.get_parent().get_children():
		if "Drop" in node.name:
			node.queue_free()
			
	# Respawn map procedurally
	var map = get_parent().get_node_or_null("GameHolder/Game/Map")
	if map and map.has_method("generate"):
		map.generate()

	# Spawn default set of drops around
	var parent_node = %GreenBoii.get_parent()
	var p_drop = PISTOL_DROP.instantiate()
	p_drop.position = pistol_spawn_pos
	parent_node.add_child(p_drop)
	
	var r_drop = REVOLVER_DROP.instantiate()
	r_drop.position = revolver_spawn_pos
	parent_node.add_child(r_drop)

func respawn_weapon_drop(weapon_name: String) -> void:
	if not is_inside_tree(): return
	var parent_node = %GreenBoii.get_parent()
	
	if weapon_name == "Pistol":
		if parent_node.has_meta("spawning_pistol"): return
		for node in parent_node.get_children():
			if "PistolDrop" in node.name and not node.is_queued_for_deletion():
				return # Drop already exists!
				
		parent_node.set_meta("spawning_pistol", true)
		var p_drop = PISTOL_DROP.instantiate()
		p_drop.position = pistol_spawn_pos
		parent_node.call_deferred("add_child", p_drop)
		get_tree().create_timer(0.1).timeout.connect(func(): parent_node.remove_meta("spawning_pistol"))
		
	elif weapon_name == "Revolver":
		if parent_node.has_meta("spawning_revolver"): return
		for node in parent_node.get_children():
			if "RevolverDrop" in node.name and not node.is_queued_for_deletion():
				return # Drop already exists!
				
		parent_node.set_meta("spawning_revolver", true)
		var r_drop = REVOLVER_DROP.instantiate()
		r_drop.position = revolver_spawn_pos
		parent_node.call_deferred("add_child", r_drop)
		get_tree().create_timer(0.1).timeout.connect(func(): parent_node.remove_meta("spawning_revolver"))
