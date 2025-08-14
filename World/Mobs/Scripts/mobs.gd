class_name Mobs
extends Node2D

@export var mobs_in_world: Array[Mob]
@onready var player_refrence: Player = %Player
@onready var turn_label: Label = %TurnLable
@onready var objects: Objects = %Objects ## Tile map layer fo all Non Movable Object, Example Trees, Apples, Ect. 

var _current_index: int = 0
var _in_cycle := false
var _current_mobs_turn: Mob
var _current_target: Vector2

func _ready() -> void:

	for mob in mobs_in_world:
		_register_mob(mob)

	player_refrence.player_entered_world.connect(_on_player_entered)

	if mobs_in_world.size() > 0:
		_start_turn_cycle()

func _on_player_entered(player: Player) -> void:
	if not mobs_in_world.has(player):
		mobs_in_world.push_front(player)
		_register_mob(player)
		_current_index = 0
		_start_turn_cycle()  # makes player current + updates labels
	_update_turn_order_label()



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
		_update_turn_label(current_mob)        # "Current Turn: ..."
		_update_turn_order_label()             # "Turn Order: Goblin, Goblin, ..."
	else:
		next_turn()



func next_turn() -> void:
	print("Next Turn -- ", )
	if mobs_in_world.is_empty():
		_in_cycle = false
		return

	_current_index = (_current_index + 1) % mobs_in_world.size()
	_start_turn_cycle()

func _on_mob_turn_started(mob: Mob) -> void:
	_update_turn_label(mob)
	Events.update_turn(mob)

func _on_mob_turn_finished(mob: Mob) -> void:

	if mobs_in_world.is_empty():
		return
	var current := mobs_in_world[_current_index]
	if mob == current:
		next_turn()

func _update_turn_label(mob: Mob) -> void:
	turn_label.text = "Current Turn: " + _mob_display_name(mob)
	_update_turn_order_label()

func _update_turn_order_label() -> void:
	var names: Array[String] = []
	for m in mobs_in_world:
		names.append(_mob_display_name(m))
	turn_label.text += "\nTurn Order: " + ", ".join(names)
	
func _mob_display_name(m: Mob) -> String:
	if m == null or !is_instance_valid(m):
		return "<freed>"
	if m.has_method("get_display_name"):
		return m.get_display_name()
	return "Mob"

func _look_for_nearest_apple() -> Vector2:
	var apples_in_map: Array[Vector2i] = objects.get_apples_from_map()
	if apples_in_map.is_empty():
		return global_position

	var my_pos := global_position
	var closest_world := my_pos
	var min_dist := INF

	for cell in apples_in_map:
		var world_pos := objects.to_global(objects.map_to_local(cell))

		var dist := my_pos.distance_to(world_pos)
		if dist < min_dist:
			min_dist = dist
			closest_world = world_pos

	return closest_world
