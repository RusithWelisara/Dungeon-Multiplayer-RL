extends Control

@onready var hp_bar_contaior: ColorRect = $MarginContainer/Control/HPBar
@onready var hp_bar: TextureProgressBar = $MarginContainer/Control/HPBar/MarginContainer/Control/HealthBar
@onready var pickup_text: Label = $MarginContainer/Control/Infomation/PickupText
@onready var ammo_text: Label = $MarginContainer/Control/Infomation/AmmoText
@onready var score_label: Label = $MarginContainer/Control/Infomation/Score

@onready var infomation: VBoxContainer = $MarginContainer/Control/Infomation


@export var P1_HP_BAR_TEXTURE: Texture
@export var P2_HP_BAR_TEXTURE: Texture

@onready var weapon: Node = %Weapon

var health: int
var health_bar_speed: int = 20


func _ready() -> void:
	# Setting up player
	visible = true
	set_up_player_ui()
	
	# Connecting Functions
	owner.update_hp_bar.connect(update_health_bar)
	weapon.update_pickup_text.connect(update_pickup_text)
	
	# Health
	health = owner.MAX_HP
	hp_bar.value = health

func set_up_player_ui() -> void:
	pickup_text.text = ""
	
	if owner.IS_P1:
		score_label.text = "Score: " + str(Score.Player1Score)
		hp_bar.fill_mode = 0
		infomation.layout_direction = Control.LAYOUT_DIRECTION_LTR
		hp_bar_contaior.layout_direction = Control.LAYOUT_DIRECTION_LTR
		hp_bar.texture_progress = P1_HP_BAR_TEXTURE
	else:
		score_label.text = "Score: " + str(Score.Player2Score)
		hp_bar.fill_mode = 1
		infomation.layout_direction = Control.LAYOUT_DIRECTION_RTL
		hp_bar_contaior.layout_direction = Control.LAYOUT_DIRECTION_RTL
		hp_bar.texture_progress = P2_HP_BAR_TEXTURE

func refresh_health_bar(delta: float) -> void:
	hp_bar.value = lerp(hp_bar.value, float(health), health_bar_speed * delta)

func _physics_process(delta: float) -> void:
	refresh_health_bar(delta)

func update_health_bar(_remaining_hp: int) -> void:
	health = _remaining_hp

func update_pickup_text(_text: String) -> void:
	pickup_text.text = _text

func update_ammo_text(_text: String) -> void:
	ammo_text.text = _text
