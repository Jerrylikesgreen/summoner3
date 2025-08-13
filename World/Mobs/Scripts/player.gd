class_name Player extends Mob


signal player_entered_world(player)



func _ready() -> void:
	await get_tree().process_frame
	emit_signal("player_entered_world", self)
