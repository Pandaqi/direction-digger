class_name MachineData

var index : int
var cell : CellData
var path : Array[CellData]

func _init(idx:int) -> void:
	index = idx
	path = []

func clear_path() -> void:
	path = []

func set_cell(c:CellData) -> void:
	cell = c
	if cell != null: path.append(cell)

func has_been_placed() -> bool:
	return cell != null
