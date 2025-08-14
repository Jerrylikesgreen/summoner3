class_name Objects
extends TileMapLayer
@onready var mobs: Mobs = %Mobs

## Atlas coords
const ATLAS_APPLE_TREE          := Vector2i(1, 0)
const ATLAS_APPLE               := Vector2i(2, 0)
const ATLAS_MOB_SPAWN_LOCATION  := Vector2i(0, 0)  # marker tile for mob spawns

## Custom data keys (TileSet → Custom Data Layers)
const CD_CAN_SPAWN_MOB    := "can_spawn_mob"     # bool
const CD_MOB_TYPE         := "mob_type"          # string, e.g. "Goblin"
const CD_CAN_SPAWN_APPLE  := "can_spawn_apple"   # bool

@export var mob_scenes: Dictionary[String, PackedScene] = {}  # type the dict

# Track what we spawned per cell
var _spawned_mobs: Dictionary[Vector2i, Node] = {}

func _ready() -> void:
	for t in get_spawnable_trees():
		if can_tree_spawn(t):
			spawn_apple_next_to_tree(t)

	spawn_mobs_from_map()

# ─────────────────────────────
# MOB SPAWN FLOW
# ─────────────────────────────

func spawn_mobs_from_map() -> void:
	for cell in get_mob_spawn_cells():
		if _spawned_mobs.has(cell):
			var existing: Node = _spawned_mobs[cell]
			if is_instance_valid(existing):
				continue

		var td: TileData = get_cell_tile_data(cell)
		var mob_type: String = ""
		if td and td.has_custom_data(CD_MOB_TYPE):
			mob_type = String(td.get_custom_data(CD_MOB_TYPE)).strip_edges()

		if mob_type.is_empty():
			continue

		if !mob_scenes.has(mob_type):
			push_warning("No scene assigned for mob_type: %s" % mob_type)
			continue

		var scene: PackedScene = mob_scenes[mob_type]
		if scene == null:
			push_warning("Scene is null for mob_type: %s" % mob_type)
			continue

		var mob: Node2D = scene.instantiate() as Node2D
		if mob == null:
			push_warning("Scene for %s is not a Mob (got different base)" % mob_type)
			continue

		var local_pos: Vector2 = map_to_local(cell)
		var tile_sz: Vector2 = Vector2(tile_set.tile_size) 
		mob.global_position = to_global(local_pos + tile_sz)
		mobs.add_child(mob)
		mobs.mobs_in_world.append(mob)
		mobs.looking_for_apples.connect()
		_spawned_mobs[cell] = mob

func _on_looking_for_apples()->void:
	
	pass


func get_mob_spawn_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in get_used_cells():
		if is_mob_spawn_marker(c):
			out.append(c)
	return out

func is_mob_spawn_marker(cell: Vector2i) -> bool:
	if get_cell_source_id(cell) == -1:
		return false
	var td: TileData = get_cell_tile_data(cell)
	if td and td.has_custom_data(CD_CAN_SPAWN_MOB) and bool(td.get_custom_data(CD_CAN_SPAWN_MOB)):
		return true
	return get_cell_atlas_coords(cell) == ATLAS_MOB_SPAWN_LOCATION

# ─────────────────────────────
# APPLE HELPERS
# ─────────────────────────────

func is_tree_spawner(cell: Vector2i) -> bool:
	if get_cell_source_id(cell) == -1:
		return false
	var td: TileData = get_cell_tile_data(cell)
	if td and td.has_custom_data(CD_CAN_SPAWN_APPLE):
		return bool(td.get_custom_data(CD_CAN_SPAWN_APPLE))
	return get_cell_atlas_coords(cell) == ATLAS_APPLE_TREE

func get_spawnable_trees() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in get_used_cells_by_id():
		if is_tree_spawner(c):
			out.append(c)
	return out

func neighbors_4(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0),
		cell + Vector2i(0, 1),
		cell + Vector2i(0, -1),
	]

func tree_has_apple(cell: Vector2i) -> bool:
	for n in neighbors_4(cell):
		if get_cell_source_id(n) != -1 and get_cell_atlas_coords(n) == ATLAS_APPLE:
			return true
	return false

func find_free_neighbor_for_apple(tree_cell: Vector2i) -> Variant:
	for n in neighbors_4(tree_cell):
		if get_cell_source_id(n) == -1:
			return n
	return null

func can_tree_spawn(cell: Vector2i) -> bool:
	if !is_tree_spawner(cell):
		return false
	if tree_has_apple(cell):
		return false
	return find_free_neighbor_for_apple(cell) != null

func spawn_apple_next_to_tree(tree_cell: Vector2i) -> void:
	var spot = find_free_neighbor_for_apple(tree_cell)
	if spot == null:
		return
	var src := get_cell_source_id(tree_cell)
	set_cell(spot, src, ATLAS_APPLE, 0)

func get_apples_from_map()->Array[Vector2i]:
	var out: Array[Vector2i] = []
	for a in get_used_cells_by_id(-1, ATLAS_APPLE):
			out.append(a)
	return out
