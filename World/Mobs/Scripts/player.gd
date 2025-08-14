class_name Player extends Mob


signal player_entered_world(player)
@onready var player_body: PlayerBody = %PlayerBody

@onready var turn_label: Label = %TurnLabel


func _ready() -> void:
	turn_started.connect(_on_player_turn_started)
	await get_tree().process_frame
	emit_signal("player_entered_world", self)
	Events.player_turn_ended_signal.connect(do_player_turn_logic)

	

func _on_player_turn_started(mob: Mob) -> void:
	if mob == self:
		print("Player's turn started!")
		player_body.player_turn = true

func do_player_turn_logic() -> void:
	end_turn()
