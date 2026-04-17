class_name ArrowData

var location : PuzzleGrid.Direction
var index : int
var direction : PuzzleGrid.Direction
var generator : PuzzleGenerator

func _init(idx:int, loc:PuzzleGrid.Direction, dir:PuzzleGrid.Direction, gen: PuzzleGenerator):
	index = idx
	location = loc
	direction = dir
	generator = gen

func get_cells_in_line() -> Array[CellData]:
	var cells : Array[CellData] = []
	if PuzzleGrid.is_horizontal(location):
		cells.assign(generator.grid.get_row(index))
	else:
		cells.assign(generator.grid.get_column(index))
	return cells

func get_machines_in_line() -> Array[MachineData]:
	var machines : Array[MachineData] = []
	for cell in get_cells_in_line():
		if not cell.has_machine(): continue
		machines.append(cell.machine)
	return machines
