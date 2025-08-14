class_name Goblin
extends Mob

signal looking_for_apples(mob:Mob)

@export var goblin_mob_resource: MobResource
@onready var mob_body: MobBody = $MobBody

func _ready() -> void:

	mob_body.set_sprite(goblin_mob_resource.animated_sprite)
	data = goblin_mob_resource
	
func _on_turn_started() -> void:

	match mob_state:
		MobState.EXPLORE:
			emit_signal("looking_for_apples", self)
			var success: bool = await looking_for_apples
			
		MobState.ACTION:
			await _attack_target()
		_:
			await get_tree().process_frame

	end_turn()

func _move_randomly() -> void:
	var dirs := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	var dir = dirs[randi() % dirs.size()]
	var target = mob_body.global_position + dir * mob_body.step_px

	mob_body.move_to(target)
	mob_body.take_turn()
	var ok = await mob_body.step_finished



func _attack_target() -> void:
	# Dummy example attack
	print("Goblin attacks!")
