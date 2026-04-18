class_name MachineData

var index : int
var cell : CellData
var path : Array[CellData]
var last_treasure_number := -1

signal changed()

func _init(idx:int) -> void:
	index = idx
	path = []

func clear_path() -> void:
	path = []

func set_cell(c:CellData) -> void:
	cell = c
	if cell != null: path.append(cell)

func has_been_placed() -> bool:
	return path.size() > 0

func set_last_treasure_number(tn:int) -> void:
	last_treasure_number = tn

func get_last_treasure_number() -> int:
	return last_treasure_number
