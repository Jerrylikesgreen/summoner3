class_name Mob
extends Node2D

signal turn_started(mob: Mob)
signal turn_finished(mob: Mob)

@onready var turn_marker: Label = %Turn_Marker

enum MobState {
	REST,
	EXPLORE,
	CHASE,
	ACTION
	
	
}

@export var mob_state: MobState = MobState.EXPLORE


@export var data: MobResource
@export var mob_name: String = ""  # optional fallback

# single backing field
var _current_turn: bool = false

@export var current_turn: bool = false:
	set(value):
		if _current_turn == value:
			return
		_current_turn = value
		if _current_turn:
			print("[Mob] set current_turn TRUE for", display_name())
			emit_signal("turn_started", self)
			_on_turn_started()
		else:
			print("[Mob] set current_turn FALSE for", self)
			_on_turn_ended()
	get:
		return _current_turn


func _ready() -> void:
	# Reflect initial state using the property (not the backing field)
	if current_turn:
		_on_turn_started()
	else:
		_on_turn_ended()


func get_display_name() -> String:
	if data and data.name != "":
		return data.name
	if mob_name != "":
		return mob_name
	if name != "":
		return name
	return "Mob"

func _on_turn_started() -> void:
	if is_instance_valid(turn_marker):
		turn_marker.text = "Turn - Active"
		print("Turn started received: ", display_name())

func _on_turn_ended() -> void:
	if is_instance_valid(turn_marker):
		turn_marker.text = "Turn - Inactive"
		print("Turn End received: ", display_name())
		
func display_name() -> String:
	if data and data.name != "": return data.name
	if mob_name != "": return mob_name
	return name  # scene tree name fallback


func end_turn() -> void:
	if _current_turn:
		# Use the property to ensure setter/UI flows run
		current_turn = false
		emit_signal("turn_finished", self)
		print("Turn End called: ", display_name())
