class_name Mob
extends Node2D

signal turn_started(mob: Mob)
signal turn_finished(mob: Mob)

@export var mob_name: String = ""

# Backing field + property with setter/getter
var _current_turn := false
@export var current_turn := false:
	set(value):
		if _current_turn == value:
			return
		_current_turn = value
		if _current_turn:
			emit_signal("turn_started", self)
			_on_turn_started()
		else:
			_on_turn_ended()
	get:
		return _current_turn

func _on_turn_started() -> void:
	print(self)
	pass

func _on_turn_ended() -> void:
	# Optional hook
	pass

func end_turn() -> void:
	# Call this from the mob when it’s finished its actions
	if _current_turn:
		_current_turn = false
		emit_signal("turn_finished", self)
