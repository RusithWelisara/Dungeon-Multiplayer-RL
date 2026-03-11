extends Resource
class_name WeaponResource

@export var weapon_name: String
@export var ammo: int
@export var damage: int
@export var speed: int
@export var auto_fire: bool
@export var fire_rate: float
@export var bullet: String = "Bullet"

@export_category("CameraShake")
@export var start_intensity: float = 3.0
@export var end_intensity: float = 1.0
@export var duration: float = 0.25
