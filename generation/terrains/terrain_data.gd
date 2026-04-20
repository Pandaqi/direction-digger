extends Resource
class_name TerrainData

## our specific type as saved inside the grid cells
@export var type := CellData.TerrainType.NONE

## probability of picking this terrain when it's a valid option
@export var prob := 0.33

## min/max numbers of this terrain we need to enforce
@export var bounds := Vector2i(2,8)

## lower = called earlier in generation
@export var priority := 1

## whether to destroy the terrain whenever it's visited/activated its special power
@export var remove_on_visit := false

## utility function for drawing from the list of all available options
func draw_elements_balanced(list:Array[CellData]) -> Array[CellData]:
	var arr : Array[CellData] = []
	for elem in list:
		var should_add := arr.size() < bounds.x and randf() <= prob
		if should_add: arr.append(elem)
		if arr.size() >= bounds.y: break
	return arr

func get_cells_unvisited(list:Array[CellData]) -> Array[CellData]:
	return list.filter(func(c:CellData): return not c.has_been_visited())

func get_cells_visited(list:Array[CellData]) -> Array[CellData]:
	return list.filter(func(c:CellData): return c.has_been_visited())

func generate(_gen:PuzzleGenerator) -> void:
	pass

func generate_fake(_gen:PuzzleGenerator, _cell:CellData) -> bool:
	return false

func on_move(_cell:CellData, _cmd:CommandMove, _cmds:PuzzleCommands) -> void:
	pass

func on_post_move(_cell:CellData, _cmds:PuzzleCommands) -> void:
	pass

func is_move_valid(_cell:CellData, _cmd:CommandMove) -> bool:
	return true
