extends PuzzleCommand
class_name CommandArrowsChange

var cell : CellData

func _init(c:CellData):
	cell = c

func do(_cmds:PuzzleCommands) -> bool:
	for arrow in cell.get_custom_arrows():
		arrow.change_max_times_used(+1)
	return true

func undo(_cmds:PuzzleCommands) -> bool:
	for arrow in cell.get_custom_arrows():
		arrow.change_max_times_used(-1)
	return true

func matches(cmd:PuzzleCommand) -> bool:
	if not (cmd is CommandArrowsChange): return false
	return cell == cmd.cell

func is_valid() -> bool:
	return true
