class_name ArrowData

var location : PuzzleGrid.Direction
var index : int
var direction : PuzzleGrid.Direction
var generator : PuzzleGenerator

var enabled := true
var locked := false

var max_times_used := -1 # -1 is basically "no max"
var num_times_used := 0
var num_times_modifier := 0
var machine_filter := -1 # if >= 0, refers to the only machine it's allowed to move

signal changed()

func _init(idx:int, loc:PuzzleGrid.Direction, gen: PuzzleGenerator):
	index = idx
	location = loc
	generator = gen

func set_direction(dir:PuzzleGrid.Direction) -> void:
	direction = dir
	changed.emit()

func is_usable() -> bool:
	return enabled and (not locked) and (not is_exhausted())

func acts_on(m:MachineData) -> bool:
	if machine_filter == -1: return true
	return machine_filter == m.index

func set_machine_filter(mf:int) -> void:
	machine_filter = mf
	changed.emit()

func set_enabled(en:bool) -> void:
	enabled = en
	changed.emit()

func change_times_used(dtu:int) -> void:
	num_times_used = maxi(dtu, 0)
	changed.emit()

func is_exhausted() -> bool:
	if max_times_used == -1: return false
	return num_times_used >= max_times_used

func change_max_times_used(dmtu:int) -> void:
	max_times_used += dmtu
	change_times_used(0)

func calculate_usage_and_reset() -> void:
	max_times_used = num_times_used + num_times_modifier
	num_times_used = 0

func has_been_used() -> bool:
	return num_times_used > 0

func get_usages_left() -> int:
	if num_times_used == -1: return -1
	return max_times_used - num_times_used

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
		machines.append(cell.get_machine())
	return machines
