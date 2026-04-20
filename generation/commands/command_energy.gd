extends PuzzleCommand
class_name CommandEnergy

func do(cmds:PuzzleCommands) -> bool:
	cmds.visualizer.generator.change_max_turns(+1)
	return true

func undo(cmds:PuzzleCommands) -> bool:
	cmds.visualizer.generator.change_max_turns(-1)
	return true

func matches(cmd:PuzzleCommand) -> bool:
	return cmd is CommandEnergy

func is_valid() -> bool:
	return true
