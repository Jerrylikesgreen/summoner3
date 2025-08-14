class_name Goblin
extends Mob

signal looking_for_apples(goblin: Goblin)
signal apple_search_done(found: bool, target: Vector2)

@export var mob_resource: MobResource
@onready var mob_body: MobBody = $MobBody

func _ready() -> void:
	if mob_resource:
		data = mob_resource
		if mob_body and mob_resource.animated_sprite:
			mob_body.set_sprite(mob_resource.animated_sprite)
	

func _on_turn_started() -> void:
	print("[Goblin] start pos root=", global_position, " body=", mob_body.global_position)
	match mob_state:
		MobState.EXPLORE:
			emit_signal("looking_for_apples", self)
			var res: Array = await apple_search_done   # [found: bool, target: Vector2]
			var found: bool = res[0]
			var target: Vector2 = res[1]

			if found:
				var moved = await _move_towards(target)  # returns bool
				if not moved:
					await _move_randomly()
			else:
				await _move_randomly()
			print("[Goblin] end pos root=", global_position, " body=", mob_body.global_position)

		MobState.ACTION:
			pass
		_:
			await get_tree().process_frame

	end_turn()

func _move_towards(target: Vector2) -> bool:
	if not mob_body:
		await get_tree().process_frame
		return false

	var delta: Vector2 = target - mob_body.global_position
	# Already at/very near target? don't consume by “doing nothing”
	if delta.length_squared() <= 0.25:
		return false

	# 4-dir, axis-priority step toward target (one tile)
	var step_dir := Vector2.ZERO
	if abs(delta.x) >= abs(delta.y):
		step_dir.x = signf(delta.x)
	else:
		step_dir.y = signf(delta.y)

	if step_dir == Vector2.ZERO:
		return false

	var motion := step_dir * float(mob_body.step_px)
	# If blocked, do not consume turn here — let caller decide
	if mob_body.test_move(mob_body.global_transform, motion):
		return false

	var step_target := mob_body.global_position + motion
	mob_body.move_to(step_target)
	mob_body.take_turn()
	var _ok: bool = await mob_body.step_finished
	return true


func notify_apple_result(found: bool, target: Vector2) -> void:
	emit_signal("apple_search_done", found, target)

func _move_randomly() -> void:
	if not mob_body:
		await get_tree().process_frame
		return

	var dirs := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	dirs.shuffle()

	for dir in dirs:
		var motion = dir * float(mob_body.step_px)
		if mob_body.test_move(mob_body.global_transform, motion):
			continue
		var target = mob_body.global_position + motion
		mob_body.move_to(target)
		mob_body.take_turn()
		var _ok: bool = await mob_body.step_finished
		return

	# all four blocked; idle a tick
	await get_tree().process_frame
