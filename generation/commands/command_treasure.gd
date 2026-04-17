extends PuzzleCommand
class_name CommandTreasure

var cell : CellData

func _init(c:CellData):
	cell = c

func do(_cmds:PuzzleCommands) -> bool:
	cell.remove_treasure()
	return true

func undo(_cmds:PuzzleCommands) -> bool:
	cell.add_treasure()
	return true

func matches(cmd:PuzzleCommand) -> bool:
	if not (cmd is CommandTreasure): return false
	return cell == cmd.cell
