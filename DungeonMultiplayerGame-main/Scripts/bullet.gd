extends Node2D

@onready var death_timer: Timer = $death_timer
@onready var collider: Area2D = $BaseCollider
@onready var hit_particle: GPUParticles2D = $hit_particle

var dir: int
var speed: int

func _ready() -> void:
	death_timer.timeout.connect(kill)
	
	if dir == 1:
		var process_mat: ParticleProcessMaterial = hit_particle.process_material
		process_mat.direction.x = -0.5
	else:
		var process_mat: ParticleProcessMaterial = hit_particle.process_material
		process_mat.direction.x = 0.5

func _physics_process(delta: float) -> void:
	move_local_x(dir * speed * delta)

func set_damage(damage: int, _shooter = null) -> void:
	$HitBox.damage = damage
	$HitBox.shooter = _shooter

func kill() -> void:
	queue_free()

func _body_entered(body: Node2D) -> void:
	hit_particle.emitting = true
	$Sprite2D.queue_free()
	$BaseCollider.queue_free()
	$HitBox.queue_free()
	await get_tree().create_timer(0.8).timeout
	kill()
