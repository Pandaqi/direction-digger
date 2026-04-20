extends PuzzleCommand
class_name CommandTerrainRemove

var cell : CellData
var terrain_removed := CellData.TerrainType.NONE

func _init(c:CellData):
	cell = c

func do(_cmds:PuzzleCommands) -> bool:
	terrain_removed = cell.type
	cell.set_terrain(CellData.TerrainType.REGULAR)
	return true

func undo(_cmds:PuzzleCommands) -> bool:
	cell.set_terrain(terrain_removed)
	return true

func matches(cmd:PuzzleCommand) -> bool:
	if not (cmd is CommandTerrainRemove): return false
	return cell == cmd.cell

func is_valid() -> bool:
	return true
