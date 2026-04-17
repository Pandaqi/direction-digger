extends PuzzleCommand
class_name CommandArrow

var arrow : ArrowData

func _init(a:ArrowData):
	arrow = a
	starts_new_turn = true

func do(cmds:PuzzleCommands) -> bool:
	var machines := arrow.get_machines_in_line()
	for machine in machines:
		await cmds.execute_command(CommandMove.new(get_direction(), machine))
	return true

# this command merely spawns new commands; they undo themselves
func undo(_cmds:PuzzleCommands) -> bool:
	return true

func matches(cmd:PuzzleCommand) -> bool:
	if not (cmd is CommandArrow): return false
	return arrow == cmd.arrow

func get_direction() -> PuzzleGrid.Direction:
	return arrow.direction
