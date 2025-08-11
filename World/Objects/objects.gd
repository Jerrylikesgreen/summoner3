class_name Objects
extends TileMapLayer

## Atlas coords
const ATLAS_APPLE_TREE := Vector2i(0, 0)
const ATLAS_APPLE      := Vector2i(1, 0)

var list_of_objects: Array[Vector2i]

func _ready() -> void:
	list_of_objects = get_used_cells()
	# find all apple trees on this layer
	var trees = cells_matching(ATLAS_APPLE_TREE)
	print("Found trees at: ", trees)

func cells_matching(atlas_coords: Vector2i, source_id: int = -1) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell in get_used_cells():
		var s := get_cell_source_id(cell)
		if s == -1: 
			continue
		if (source_id == -1 or s == source_id) and get_cell_atlas_coords(cell) == atlas_coords:
			out.append(cell)
	return out

func set_cell_atlas(cell: Vector2i, atlas_coords: Vector2i) -> void:
	var s := get_cell_source_id(cell)
	if s == -1: return
	var alt := get_cell_alternative_tile(cell)
	set_cell(cell, s, atlas_coords, alt)

func toggle_tree_apple(cell: Vector2i) -> void:
	var s := get_cell_source_id(cell)
	if s == -1: return
	var a := get_cell_atlas_coords(cell)
	var alt := get_cell_alternative_tile(cell)
	var new_a := ATLAS_APPLE if a == ATLAS_APPLE_TREE else ATLAS_APPLE_TREE
	set_cell(cell, s, new_a, alt)
