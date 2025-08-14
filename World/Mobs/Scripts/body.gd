class_name PlayerBody
extends CharacterBody2D

signal step_finished(success: bool)

@onready var body_sprite: AnimatedSprite2D = %BodySprite
@export var step_px: int = 16
@export var step_speed: float = 96.0

var _dir: Vector2 = Vector2.ZERO
var _remaining: float = 0.0
var _control_enabled := false

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	safe_margin = 0.001
	max_slides = 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[PlayerBody] ready; sprite=", body_sprite)

func enable_player_control(enable: bool) -> void:
	_control_enabled = enable
	print("[PlayerBody] control =", enable)

func _input(event: InputEvent) -> void:
	if !_control_enabled: return
	if !event.is_pressed(): return
	if event is InputEventKey and event.echo: return
	if _remaining > 0.0: return

	var dir := Vector2.ZERO
	# Ensure these exist in Project Settings → Input Map
	if event.is_action_pressed("Left"):  dir = Vector2.LEFT
	elif event.is_action_pressed("Right"): dir = Vector2.RIGHT
	elif event.is_action_pressed("Up"):    dir = Vector2.UP
	elif event.is_action_pressed("Down"):  dir = Vector2.DOWN
	else:
		return

	print("[PlayerBody] input dir =", dir)
	_start_step(dir)

func _start_step(dir: Vector2) -> void:
	dir = Vector2(sign(dir.x), sign(dir.y))
	if dir == Vector2.ZERO: return
	_dir = dir
	_remaining = float(step_px)
	if body_sprite: body_sprite.play("Moving")
	print("[PlayerBody] step start dir=", _dir, " remaining=", _remaining)

func _physics_process(delta: float) -> void:
	if _remaining <= 0.0: return

	var step = min(step_speed * delta, _remaining)
	var motion = _dir * step
	var coll = move_and_collide(motion)

	if coll:
		_remaining = 0.0
		if body_sprite: body_sprite.play("Idle")
		print("[PlayerBody] COLLISION -> emit false")
		emit_signal("step_finished", false)
		return

	_remaining -= step
	if _remaining <= 0.0:
		if body_sprite: body_sprite.play("Idle")
		print("[PlayerBody] step done -> emit true")
		emit_signal("step_finished", true)
