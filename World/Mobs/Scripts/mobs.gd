class_name Mobs
extends Node2D

@export var mobs_in_world: Array[Mob]
@onready var player_refrence: Player = %Player
@onready var turn_label: Label = %TurnLable           # check the node's actual name/spelling
@onready var objects: Objects = %Objects              # TileMap/Layer with apples, etc.

var _current_index := 0
var _in_cycle := false
var _advance_pending := false

func _ready() -> void:
	# Register any mobs already in the scene
	for mob in mobs_in_world:
		_register_mob(mob)
	print("[Mobs] roster:")
	for i in range(mobs_in_world.size()):
		var m := mobs_in_world[i]
		var cls = (m.get_script().get_global_name() if m.get_script() and m.get_script().has_method("get_global_name") else m.get_class())
		print("  #", i, " -> ", m.name, "  class=", cls, "  display=", _display_name(m))

	# Player joins a frame later
	if not player_refrence.player_entered_world.is_connected(_on_player_entered):
		player_refrence.player_entered_world.connect(_on_player_entered)

	# Kick the first turn after children are ready
	call_deferred("_maybe_start_cycle")

func _maybe_start_cycle() -> void:
	if mobs_in_world.is_empty():
		turn_label.text = "No mobs"
		return
	_current_index = clamp(_current_index, 0, max(0, mobs_in_world.size()-1))
	_start_turn_cycle()

func _on_player_entered(player: Player) -> void:
	# Put player at the front and (re)start the loop with player first
	if not mobs_in_world.has(player):
		mobs_in_world.push_front(player)
		_register_mob(player)
	_current_index = 0
	_start_turn_cycle()
	_update_turn_ui(mobs_in_world[_current_index])

func _register_mob(mob: Mob) -> void:
	if mob == null: return
	if not mob.turn_started.is_connected(_on_mob_turn_started):
		mob.turn_started.connect(_on_mob_turn_started)
	if not mob.turn_finished.is_connected(_on_mob_turn_finished):
		mob.turn_finished.connect(_on_mob_turn_finished)

	# Wire goblins to apple lookup
	if mob is Goblin:
		var g := mob as Goblin
		if not g.looking_for_apples.is_connected(_on_goblin_looking_for_apples):
			g.looking_for_apples.connect(_on_goblin_looking_for_apples)

	# Remove safely if it leaves the tree
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

	# reset all
	for m in mobs_in_world:
		if is_instance_valid(m):
			m.current_turn = false

	var current_mob := mobs_in_world[_current_index]
	if is_instance_valid(current_mob):
		current_mob.current_turn = true
		_update_turn_ui(current_mob)
	else:
		next_turn()  # deferred/guarded

func next_turn() -> void:
	# De-dupe & defer any turn advances this frame.
	if _advance_pending:
		return
	_advance_pending = true
	call_deferred("_advance_turn")

func _advance_turn() -> void:
	_advance_pending = false
	if mobs_in_world.is_empty():
		_in_cycle = false
		return
	print("Next Turn --")
	_current_index = (_current_index + 1) % mobs_in_world.size()
	_start_turn_cycle()

func _on_mob_turn_started(mob: Mob) -> void:
	_update_turn_ui(mob)
	# Ensure Events.update_turn(mob) does NOT advance turns.
	Events.update_turn(mob)

func _on_mob_turn_finished(mob: Mob) -> void:
	if mobs_in_world.is_empty(): return
	var current := mobs_in_world[_current_index]
	if mob == current:
		next_turn()

# ---------- UI ----------
func _update_turn_ui(current: Mob) -> void:
	var current_line := "Current Turn: " + _display_name(current)
	var order_line  := "Turn Order: " + _turn_order_line()
	turn_label.text = current_line + "\n" + order_line

func _turn_order_line() -> String:
	var names: Array[String] = []
	for m in mobs_in_world:
		names.append(_display_name(m))
	return ", ".join(names)

func _display_name(m: Mob) -> String:
	if m == null or !is_instance_valid(m): return "<freed>"
	if m.has_method("get_display_name"): return m.get_display_name()
	return m.name

# ---------- Apples ----------
func get_nearest_apple_to(origin: Vector2) -> Vector2:
	print("Apples Get Near")
	var cells: Array[Vector2i] = objects.get_apples_from_map()
	if cells.is_empty():
		return origin
	var nearest := origin
	var min_d := INF
	for c in cells:
		var w := objects.to_global(objects.map_to_local(c))
		var d := origin.distance_to(w)
		if d < min_d:
			min_d = d
			nearest = w
	return nearest
	

func _on_goblin_looking_for_apples(g: Goblin) -> void:
	# Use the body position, not the Goblin (Mob) root
	var origin := g.mob_body.global_position
	var target := get_nearest_apple_to(origin)
	var found := target.distance_squared_to(origin) > 0.25
	g.notify_apple_result(found, target)
