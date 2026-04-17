@abstract class_name PuzzleCommand

var starts_new_turn := false

@abstract func do(cmds:PuzzleCommands) -> bool
@abstract func undo(cmds:PuzzleCommands) -> bool
@abstract func matches(cmd:PuzzleCommand) -> bool
