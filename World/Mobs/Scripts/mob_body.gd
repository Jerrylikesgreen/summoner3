class_name MobBody
extends CharacterBody2D

signal step_finished(success: bool)   # â ADD
@onready var body_sprite: AnimatedSprite2D = %BodySprite

@export var step_px: int = 16
@export var step_speed: float = 96.0  # px/sec
@export var snap_to_grid_on_stop: bool = true
@export var prefer_horizontal_first: bool = true  # axis priority when both differ

var _dir: Vector2 = Vector2.ZERO
var _remaining: float = 0.0

var _has_target: bool = false
var _target: Vector2 = Vector2.ZERO


func set_sprite(sprite:SpriteFrames)->void:
	body_sprite.set_sprite_frames(sprite)


func move_to(target_global_pos: Vector2) -> void:
	# You can grid-snap the target if you want perfect alignment
	_target = target_global_pos
	_has_target = true

func take_turn() -> void:
	# If weâre mid-step, ignore (finish the current move first)
	if _remaining > 0.0:
		return
	if !_has_target:
		return

	var delta := _target - global_position

	# Already at target? stop.
	if is_on_target(delta):
		_has_target = false
		return

	# Choose one 4-dir step toward the target (axis priority)
	_dir = choose_step_dir(delta)

	# Distance remaining along that axis â clamp final step if closer than step_px
	var dist_to_target_along_dir = abs(delta.dot(_dir))
	_remaining = min(float(step_px), dist_to_target_along_dir)

	if _remaining > 0.0:
		body_sprite.play("Moving")

func _physics_process(delta: float) -> void:
	if _remaining <= 0.0:
		return

	var step = min(step_speed * delta, _remaining)
	var motion = _dir * step
	var collision := move_and_collide(motion)

	if collision:
		_remaining = 0.0
		body_sprite.play("Idle")
		if snap_to_grid_on_stop:
			global_position = global_position.snapped(Vector2(step_px, step_px))
		emit_signal("step_finished", false) # â emit here if blocked
		return

	_remaining -= step
	if _remaining <= 0.0:
		body_sprite.play("Idle")
		if snap_to_grid_on_stop:
			global_position = global_position.snapped(Vector2(step_px, step_px))
		emit_signal("step_finished", true)  # â emit here if finished


func is_on_target(delta: Vector2) -> bool:
	# Consider within half a pixel as "on target"
	return delta.length_squared() <= 0.25

func choose_step_dir(delta: Vector2) -> Vector2:
	var dx := int(sign(delta.x))
	var dy := int(sign(delta.y))

	if dx != 0 and dy != 0:
		# both differ: pick an axis based on preference
		return Vector2(dx, 0) if prefer_horizontal_first else Vector2(0, dy)
	elif dx != 0:
		return Vector2(dx, 0)
	elif dy != 0:
		return Vector2(0, dy)
	else:
		return Vector2.ZERO
		
