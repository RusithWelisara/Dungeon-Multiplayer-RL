extends Node

@onready var sprites: AnimatedSprite2D = %Sprites
@onready var player_id: Sprite2D = %Player_Id

var dir: int

func _ready() -> void:
	set_up()

func _process(delta: float) -> void:
	animations()

func set_up() -> void:
	if owner.IS_P1:
		sprites.flip_h = false
		dir = -1
		player_id.frame = 1
	else:
		sprites.flip_h = true
		dir = 1
		player_id.frame = 2
	
	sprites.play("idle")

func animations() -> void:
	if sprites.flip_h:
		dir = -1
	else:
		dir = 1
	if owner.velocity.x == 0:
		sprites.play("idle")
	else:
		if owner.velocity.x > 0.0: sprites.flip_h = false
		else: sprites.flip_h = true
		sprites.play("run")
