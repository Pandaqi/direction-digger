extends PuzzleCommand
class_name CommandMove

var direction : PuzzleGrid.Direction
var machine : MachineData

func _init(dir:PuzzleGrid.Direction, m:MachineData):
	direction = dir
	machine = m

func do(cmds:PuzzleCommands) -> bool:
	var cur_cell := machine.cell
	var new_cell := cur_cell.get_neighbor_at(direction) as CellData

	cur_cell.remove_machine(machine)
	new_cell.add_machine(machine)
	
	var should_collect := new_cell.has_treasure() and (not cmds.generating)
	var can_collect : bool = (not PuzzleSettings.get_value("show_numbers_on_treasure")) or (new_cell.treasure_number == (machine.get_last_treasure_number() + 1))
	if should_collect and can_collect:
		await cmds.execute_command(CommandTreasure.new(new_cell))
	
	return true

func undo(_cmds:PuzzleCommands) -> bool:
	var cur_cell := machine.cell
	cur_cell.remove_machine(machine)
	var new_cell := cur_cell.get_neighbor_at(PuzzleGrid.get_opposite_direction_of(direction))
	new_cell.add_machine(machine)
	return true

func get_target_cell() -> CellData:
	return machine.cell.get_neighbor_at(direction)

func is_valid() -> bool:
	# move would take us off map
	var target_cell := get_target_cell()
	if not target_cell: return false
	
	# other machines don't block us if _they_ can move out of the way
	if target_cell.has_machine(): 
		var cmd_other_machine := CommandMove.new(direction, target_cell.get_machine())
		if not cmd_other_machine.is_valid():
			return false
	
	return true

func matches(cmd:PuzzleCommand) -> bool:
	if not (cmd is CommandMove): return false
	return direction == cmd.direction and machine == cmd.machine
