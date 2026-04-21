extends PuzzleCommand
class_name CommandWearDown

var cell : CellData
var audio_stream : AudioStream = load("res://puzzle-framework/game/sfx/windup_stretch.ogg")

func _init(c:CellData):
	cell = c

func do(cmds:PuzzleCommands) -> bool:
	cell.change_custom_number(-1)
	if cmds.visualizer: cmds.visualizer.play_audio_custom(cell, audio_stream)
	if cell.get_custom_number() <= 0 and cell.type == CellData.TerrainType.WEB:
		await cmds.execute_command(CommandTerrainRemove.new(cell))
	return true

func undo(_cmds:PuzzleCommands) -> bool:
	cell.change_custom_number(+1)
	return true

func matches(cmd:PuzzleCommand) -> bool:
	if not (cmd is CommandWearDown): return false
	return cell == cmd.cell

func is_valid() -> bool:
	return true
