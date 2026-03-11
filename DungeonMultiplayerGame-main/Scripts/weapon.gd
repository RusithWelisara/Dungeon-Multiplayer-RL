class_name Weapon
extends Node

@export var data: WeaponResource
@onready var bullet_point: Marker2D = $BulletPoint
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound

signal update_ammo(_text: String)

# Bullets
var NORMAL_BULLET = preload("res://scenes/Bullets/bullet.tscn")
var REVOLVER_BULLET = preload("res://scenes/Bullets/revolver_bullet.tscn")

var projectile

var ready_to_fire: bool = true

var ammo: int
var player: Player

func _ready() -> void:
	ammo = data.ammo
	randomize()

func fire() -> void:
	if ready_to_fire and ammo > 0:
		ammo -= 1
		ready_to_fire = false
		player.weapon_code.update_ammo_text("Ammo : " + str(ammo))
		
		shoot_projectile()
		shoot_sfx()
		vfx()
		reset_time()
		
		if ammo <= 0:
			player.weapon_code.weapon_equipped = false
			
			if not has_meta("respawned"):
				set_meta("respawned", true)
				var gm = get_tree().current_scene.get_node_or_null("%GameManager")
				if not gm:
					gm = get_node_or_null("/root/Game/GameManager")
					
				if gm and gm.has_method("respawn_weapon_drop"):
					gm.respawn_weapon_drop(name)
				
			queue_free()

func vfx() -> void:
	player.CAMERA.camera_shake(data.start_intensity, data.end_intensity, data.duration)

func shoot_projectile() -> void:
	match data.bullet:
		"Bullet":
			var bullet = NORMAL_BULLET.instantiate()
			bullet.dir = player.animation_code.dir 
			bullet.speed = data.speed
			bullet.global_position = bullet_point.global_position
			get_tree().get_root().add_child(bullet)
			bullet.set_damage(data.damage, player)
		"Revolver_Bullet":
			var bullet = REVOLVER_BULLET.instantiate()
			bullet.dir = player.animation_code.dir 
			bullet.speed = data.speed
			bullet.global_position = bullet_point.global_position
			get_tree().get_root().add_child(bullet)
			bullet.set_damage(data.damage, player)

func shoot_sfx() -> void:
	shoot_sound.pitch_scale = randf_range(0.9, 1.1)
	shoot_sound.play()

func reset_time() -> void:
	await get_tree().create_timer(data.fire_rate).timeout
	ready_to_fire = true	
