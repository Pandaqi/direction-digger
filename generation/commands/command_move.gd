extends PuzzleCommand
class_name CommandMove

var direction : PuzzleGrid.Direction
var machine : MachineData
var has_moved : bool

func _init(dir:PuzzleGrid.Direction, m:MachineData):
	direction = dir
	machine = m

func do(cmds:PuzzleCommands) -> bool:
	var cur_cell := machine.cell
	var new_cell := cur_cell.get_neighbor_at(direction)
	has_moved = false
	if not new_cell: return false
	
	has_moved = true
	cur_cell.remove_machine(machine)
	new_cell.add_machine(machine)
	
	if new_cell.has_treasure():
		await cmds.execute_command(CommandTreasure.new(new_cell))
	
	return true

func undo(_cmds:PuzzleCommands) -> bool:
	if not has_moved: return false
	
	var cur_cell := machine.cell
	cur_cell.remove_machine(machine)
	var new_cell := cur_cell.get_neighbor_at(PuzzleGrid.get_opposite_direction_of(direction))
	new_cell.add_machine(machine)
	return true

func matches(cmd:PuzzleCommand) -> bool:
	if not (cmd is CommandMove): return false
	return direction == cmd.direction and machine == cmd.machine
