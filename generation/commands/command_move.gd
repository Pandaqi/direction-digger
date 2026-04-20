extends PuzzleCommand
class_name CommandMove

var direction : PuzzleGrid.Direction
var machine : MachineData
var current_cell : CellData
var target_cell : CellData

func _init(dir:PuzzleGrid.Direction, m:MachineData):
	direction = dir
	machine = m

func do(cmds:PuzzleCommands) -> bool:
	current_cell = get_current_cell()
	target_cell = get_target_cell()

	current_cell.remove_machine(machine)
	
	if cmds.visualizer and (not cmds.generating):
		await (cmds.visualizer as PuzzleVisualizer).animate_movement(self)
	
	target_cell.add_machine(machine)
	
	# terrains and treasure and stuff are generated in a forward manner
	# as such, we DON'T want to actually interact with anything we encounter during generation
	# so just move the machine and don't do anything else
	if cmds.generating: return true
	
	# ask terrain to do whatever it wants
	var terrain_data := target_cell.get_terrain_resource()
	await terrain_data.on_move(target_cell, self, cmds)
	
	# remove terrain if the type demands it
	if terrain_data.remove_on_visit:
		await cmds.execute_command(CommandTerrainRemove.new(target_cell))
	
	# collect treasures as needed
	var should_collect := target_cell.has_treasure()
	var can_collect := target_cell.can_collect_treasure(machine)
	if should_collect and can_collect:
		await cmds.execute_command(CommandTreasure.new(target_cell))
	
	return true

func undo(_cmds:PuzzleCommands) -> bool:
	var cur_cell := machine.cell
	cur_cell.remove_machine(machine)
	var new_cell := cur_cell.get_neighbor_at(PuzzleGrid.get_opposite_direction_of(direction))
	new_cell.add_machine(machine)
	return true

func get_target_cell() -> CellData:
	return machine.cell.get_neighbor_at(direction)

func get_current_cell() -> CellData:
	return machine.cell

func is_valid() -> bool:
	# move would take us off map
	target_cell = get_target_cell()
	current_cell = get_current_cell()
	if (not target_cell) or (not current_cell): return false
	
	# other machines don't block us if _they_ can move out of the way
	if target_cell.has_machine(): 
		var cmd_other_machine := CommandMove.new(direction, target_cell.get_machine())
		if not cmd_other_machine.is_valid():
			return false
	
	# check if the terrain type protests for some reason
	if not current_cell.get_terrain_resource().is_move_valid(current_cell, self): return false
	if not target_cell.get_terrain_resource().is_move_valid(target_cell, self): return false
	
	return true

func matches(cmd:PuzzleCommand) -> bool:
	if not (cmd is CommandMove): return false
	return direction == cmd.direction and machine == cmd.machine
