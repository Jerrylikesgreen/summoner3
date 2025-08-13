class_name Mobs
extends Node2D

@export var mobs_in_world: Array[Mob]
@onready var player_refrence: Player = %Player
@onready var turn_label: Label = %TurnLable

var _current_index: int = 0
var _in_cycle := false

func _ready() -> void:

	for mob in mobs_in_world:
		_register_mob(mob)

	player_refrence.player_entered_world.connect(_on_player_entered)

	if mobs_in_world.size() > 0:
		_start_turn_cycle()

func _on_player_entered(player: Player) -> void:
	if not mobs_in_world.has(player):
		mobs_in_world.append(player)
		_register_mob(player)

		if mobs_in_world.size() == 1 and not _in_cycle:
			_current_index = 0
			_start_turn_cycle()
	print("Player added to array")

func _register_mob(mob: Mob) -> void:

	if not mob.turn_started.is_connected(_on_mob_turn_started):
		mob.turn_started.connect(_on_mob_turn_started)
	if not mob.turn_finished.is_connected(_on_mob_turn_finished):
		mob.turn_finished.connect(_on_mob_turn_finished)

	mob.tree_exited.connect(func():
		var idx := mobs_in_world.find(mob)
		if idx != -1:
			mobs_in_world.remove_at(idx)
			if idx <= _current_index and _current_index > 0:
				_current_index -= 1

			if mobs_in_world.is_empty():
				_in_cycle = false
			elif idx == _current_index:
				next_turn()
	)

func _start_turn_cycle() -> void:
	if mobs_in_world.is_empty():
		_in_cycle = false
		turn_label.text = "No mobs"
		return

	_in_cycle = true

	for mob in mobs_in_world:
		if is_instance_valid(mob):
			mob.current_turn = false

	var current_mob := mobs_in_world[_current_index]
	if is_instance_valid(current_mob):
		current_mob.current_turn = true
		_update_turn_label(current_mob)
	else:

		next_turn()

func next_turn() -> void:
	if mobs_in_world.is_empty():
		_in_cycle = false
		return

	_current_index = (_current_index + 1) % mobs_in_world.size()
	_start_turn_cycle()

func _on_mob_turn_started(mob: Mob) -> void:
	_update_turn_label(mob)

func _on_mob_turn_finished(mob: Mob) -> void:

	if mobs_in_world.is_empty():
		return
	var current := mobs_in_world[_current_index]
	if mob == current:
		next_turn()

func _update_turn_label(mob: Mob) -> void:
	var name := mob.mob_name if mob.mob_name != "" else "Mob " + str(_current_index + 1)
	turn_label.text = "Current Turn: " + name
