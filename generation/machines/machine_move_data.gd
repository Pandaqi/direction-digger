class_name MachineMoveData

## the index of each turn when it moved
## (first index is always -1 and refers to starting position of machine)
var turns_moved : Array[int] = []

## the entire path of the machine
var path : Array[CellData] = []

func _init(pt:Array[CellData]) -> void:
	path = pt
	turns_moved = [-1]

func is_in_play() -> bool:
	return turns_moved.size() > 1

func register_turn_moved(t:int) -> void:
	turns_moved.append(t)

func get_turn(idx:int) -> int:
	return turns_moved[idx]

func get_last_turn_moved() -> int:
	return turns_moved.back()

func get_current_cell() -> CellData:
	return path[turns_moved.size() - 1]
