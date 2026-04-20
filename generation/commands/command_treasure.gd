extends PuzzleCommand
class_name CommandTreasure

var cell : CellData
var treasure_num_removed := -1
var treasure_num_machine := -1

func _init(c:CellData):
	cell = c

func do(cmds:PuzzleCommands) -> bool:
	treasure_num_removed = cell.treasure_number
	cell.remove_treasure()
	treasure_num_machine = cell.get_machine().get_last_treasure_number()
	cell.get_machine().set_last_treasure_number(treasure_num_removed)
	if cmds.visualizer: cmds.visualizer.on_treasures_changed(cell)
	return true

func undo(cmds:PuzzleCommands) -> bool:
	if cmds.visualizer: cmds.visualizer.on_treasures_changed(cell)
	cell.add_treasure(treasure_num_removed)
	cell.get_machine().set_last_treasure_number(treasure_num_machine)
	return true

func matches(cmd:PuzzleCommand) -> bool:
	if not (cmd is CommandTreasure): return false
	return cell == cmd.cell

func is_valid() -> bool:
	return true
