class_name Player
extends Mob

signal player_entered_world(player)

@onready var player_body: PlayerBody = %PlayerBody

func _ready() -> void:
	await get_tree().process_frame
	emit_signal("player_entered_world", self)
	print("[Player] emitted player_entered_world")
	
# IMPORTANT: override the SAME hook name/signature as the base
func _on_turn_started() -> void:
	print("[Player] turn started (override)")
	player_body.enable_player_control(true)

	# Wait for exactly one step from PlayerBody
	var ok: bool = await player_body.step_finished
	print("[Player] step finished ok=", ok)

	player_body.enable_player_control(false)
	end_turn()
