class_name MachineData

var index : int
var cell : CellData
var path : Array[CellData]
var last_treasure_number := -1

static var colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.CYAN, Color.PURPLE]

signal changed()

func _init(idx:int) -> void:
	index = idx
	path = []

func clear_path() -> void:
	path = []

func set_cell(c:CellData) -> void:
	cell = c
	if cell != null: path.append(cell)

func set_starting_position(c:CellData) -> void:
	path = [c]

func has_been_placed() -> bool:
	return path.size() > 0

func set_last_treasure_number(tn:int) -> void:
	last_treasure_number = tn

func get_last_treasure_number() -> int:
	return last_treasure_number

func turns_since_last_treasure() -> int:
	for i in range(path.size()-1,-1,-1):
		if path[i].has_treasure(): return path.size() - 1 - i
	return path.size()

func print_path() -> void:
	var positions := path.map(func(c:CellData): return c.pos)
	print(" -> ".join(positions))
