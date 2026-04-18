extends PuzzleCell
class_name CellData

var machines : Array[MachineData] = []
var treasure := false
var treasure_number := -1
var type : TerrainType

var is_machine_starting_pos := false

enum TerrainType
{
	NONE,
	REGULAR
}

func get_terrain() -> TerrainType:
	return type

# @TODO: Actually set and use this in puzzle generation
func set_terrain(tt:TerrainType) -> void:
	type = tt
	changed.emit()

func has_machine() -> bool:
	return machines.size() > 0

func get_machine() -> MachineData:
	return machines.front()

func add_machine(m:MachineData) -> void:
	machines.append(m)
	if m.path.size() <= 0: is_machine_starting_pos = true
	m.set_cell(self)
	changed.emit()

func remove_machine(m:MachineData) -> void:
	if not machines.has(m): return
	machines.erase(m)
	m.set_cell(null)
	changed.emit()

func can_place_treasure() -> bool:
	return (not has_treasure()) and (not is_machine_starting_pos)

func add_treasure(num:int) -> void:
	treasure = true
	treasure_number = num
	changed.emit()

func remove_treasure() -> void:
	treasure = false
	treasure_number = -1
	changed.emit()

func has_treasure() -> bool:
	return treasure

# @TODO: this must likely be extended once we introduce specific TYPES that the cell can be
func can_receive_machine() -> bool:
	return not has_machine() and not has_treasure()
