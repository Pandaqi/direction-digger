extends PuzzleCell
class_name CellData

var machines : Array[MachineData] = [] # machine currently here
var machines_history : Array[MachineData] = [] # machines that have been here over time
var treasure := false
var treasure_number := -1
var type : TerrainType

# used by certain terrain types to only make it act on a SPECIFIC player
var machine_filter := -1

# used by certain terrain types
var custom_number := -1

# used by the Arrows terrain type
var custom_arrows : Array[ArrowData] = []

var is_machine_starting_pos := false
var is_machine_ending_pos := false

enum TerrainType
{
	NONE,
	REGULAR,
	REGULAR_ALT,
	STONE,
	ICE,
	LAVA,
	ARROWS,
	ENERGY,
	WEB,
	TBD,
	GOLD,
	TREASURE
}

func reset_after_generation() -> void:
	machines_history = []

func has_terrain() -> bool:
	return type != TerrainType.NONE

func is_special_terrain() -> bool:
	return not is_default_terrain()

func is_default_terrain() -> bool:
	return [TerrainType.NONE, TerrainType.REGULAR, TerrainType.REGULAR_ALT].has(type)

func get_terrain_resource() -> TerrainData:
	if not (type in PuzzleGenerator.terrain_types_library): return PuzzleGenerator.terrain_types_library[CellData.TerrainType.NONE]
	return PuzzleGenerator.terrain_types_library[type]

func get_terrain() -> TerrainType:
	return type

func set_terrain(tt:TerrainType) -> void:
	type = tt
	changed.emit()

func set_custom_number(cn:int) -> void:
	custom_number = cn
	changed.emit()

func change_custom_number(dcn:int) -> void:
	set_custom_number(custom_number + dcn)

func get_custom_number() -> int:
	return custom_number

func set_custom_arrows(ca:Array[ArrowData]) -> void:
	custom_arrows = ca

func get_custom_arrows() -> Array[ArrowData]:
	return custom_arrows

func has_machine_filter() -> bool:
	return machine_filter != -1

func set_machine_filter(mf:int) -> void:
	machine_filter = mf
	changed.emit()

# inverted = it does NOT act on machines in the filter, it acts on EVERYONE ELSE
func terrain_acts_on(m:MachineData, inverted = false) -> bool:
	if not has_machine_filter(): return true
	if inverted: return machine_filter != m.index
	return machine_filter == m.index

func has_machine() -> bool:
	return machines.size() > 0

func get_machine() -> MachineData:
	return machines.front()

func add_machine(m:MachineData) -> void:
	machines.append(m)
	machines_history.append(m)
	if m.path.size() <= 0: is_machine_starting_pos = true
	m.set_cell(self)
	changed.emit()

func remove_machine(m:MachineData) -> void:
	if not machines.has(m): return
	machines.erase(m)
	m.set_cell(null)
	changed.emit()

func has_been_visited() -> bool:
	return count_visits() > 0

func get_machine_indices() -> Array[int]:
	var arr : Array[int] = []
	for machine in machines_history:
		if arr.has(machine.index): continue
		arr.append(machine.index)
	return arr

func has_been_visited_multiple_times() -> bool:
	return count_visits() > 1

func count_visits() -> int:
	if is_machine_starting_pos: return machines_history.size() - 1 # initial placement does not count as visit
	return machines_history.size()

func has_seen_multiple_machines() -> bool:
	return get_machine_indices().size() > 1

func has_seen_only_one_machine() -> bool:
	return get_machine_indices().size() == 1

func can_place_treasure() -> bool:
	if has_treasure(): return false
	if PuzzleSettings.get_difficulty_property("forbid_treasure_below_machines") and is_machine_starting_pos: return false
	return true

func can_collect_treasure(machine:MachineData) -> bool:
	if type == TerrainType.WEB and get_custom_number() > 0: return false
	if not PuzzleSettings.get_value("show_numbers_on_treasure"): return true
	var next_num := (machine.get_last_treasure_number() + 1)
	return treasure_number == -1 or treasure_number == next_num	

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

func treasure_is_required() -> bool:
	return is_machine_ending_pos or (type == TerrainType.WEB)

# if it was visited more often than this, then a treasure in this spot will have been collected BEFORE the final move of a machine into it
func get_max_visits_allowed_for_treasure() -> int:
	return custom_number if type == CellData.TerrainType.WEB else 1

func can_receive_machine() -> bool:
	return not has_machine() and not has_treasure() and not is_machine_starting_pos

func can_receive_special_terrain() -> bool:
	return not has_terrain() and not is_machine_starting_pos

func can_receive_fake_terrain() -> bool:
	return is_default_terrain() and (not is_machine_starting_pos)
