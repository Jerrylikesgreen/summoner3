class_name PlayerBody extends CharacterBody2D


@onready var body_sprite: AnimatedSprite2D = %BodySprite
@export var step_px := 16
@export var step_speed := 96.0  # px/sec
var _dir := Vector2.ZERO
var _remaining := 0.0
var player_turn: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if !player_turn: return
	if not event.is_pressed(): return
	if event is InputEventKey and event.echo: return
	if _remaining > 0.0: return

	if event.is_action_pressed("Left"):
		_dir = Vector2.LEFT
	elif event.is_action_pressed("Right"):
		_dir = Vector2.RIGHT
	elif event.is_action_pressed("Up"):
		_dir = Vector2.UP
	elif event.is_action_pressed("Down"):
		_dir = Vector2.DOWN
	else:
		return

	_remaining = float(step_px)
	body_sprite.play("Moving")
	Events.player_turn_ended()
	player_turn = false

func _physics_process(delta: float) -> void:
	if _remaining <= 0.0: return

	var step = min(step_speed * delta, _remaining)
	var motion = _dir * step
	var collision = move_and_collide(motion)
	if collision:
		_remaining = 0.0
		body_sprite.play("Idle")
		return

	_remaining -= step
	if _remaining <= 0.0:
		body_sprite.play("Idle")
