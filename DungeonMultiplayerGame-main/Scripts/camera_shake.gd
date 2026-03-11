extends Node

@onready var camera: Camera2D = %Camera
var camera_shake_noise : FastNoiseLite

func _ready() -> void:
	camera_shake_noise = FastNoiseLite.new()

func camera_shake(start_intensity: float, end_intensity: float, duration: float) -> void:
	var camera_tween = get_tree().create_tween()
	camera_tween.tween_method(start_camera_shake, start_intensity, end_intensity, duration)


func start_camera_shake(_intensity: float) -> void:
	var camera_offset = camera_shake_noise.get_noise_1d(Time.get_ticks_msec()) * _intensity
	camera.offset.x = camera_offset
	camera.offset.y = camera_offset
	
