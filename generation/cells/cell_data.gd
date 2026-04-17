extends PuzzleCell
class_name CellData

var machine : MachineData = null
var treasure := false

func has_machine() -> bool:
	return machine != null

func add_machine(m:MachineData) -> void:
	if has_machine(): return
	machine = m
	machine.set_cell(self)
	changed.emit()

func remove_machine(m:MachineData) -> void:
	if not has_machine() or not machine == m: return
	machine.set_cell(null)
	machine = null
	changed.emit()

func add_treasure() -> void:
	treasure = true
	changed.emit()

func remove_treasure() -> void:
	treasure = false
	changed.emit()

func has_treasure() -> bool:
	return treasure

# @TODO: this must likely be extended once we introduce specific TYPES that the cell can be
func can_receive_machine() -> bool:
	return not has_machine() and not has_treasure()
