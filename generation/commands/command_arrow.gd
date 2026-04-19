extends PuzzleCommand
class_name CommandArrow

var arrow : ArrowData
var cells_targeted : Array[CellData] = []
var cells_targeted_by_machine : Dictionary[MachineData, CellData] = {}
var machines_targeted : Array[MachineData] = []

func _init(a:ArrowData):
	arrow = a
	starts_new_turn = true

func do(cmds:PuzzleCommands) -> bool:
	arrow.change_times_used(+1)
	
	cells_targeted = []
	cells_targeted_by_machine = {}
	machines_targeted = []
	
	for cmd in get_commands():
		if not cmd.is_valid(): continue
		
		# cache/track some statistics of what we did for generation sanity checks
		var target_cell := cmd.get_target_cell()
		cells_targeted.append(target_cell)
		cells_targeted_by_machine[cmd.machine] = target_cell
		machines_targeted.append(cmd.machine)
		
		await cmds.execute_command(cmd)
	
	# ice/lava changes are applied AFTER moving everyone
	# otherwise we get issues with order (sometimes unfreeze comes before frozen machine tries to move, sometimes after, blabla)
	var lava_cells := cells_targeted.filter(func(c:CellData): return c.type == CellData.TerrainType.LAVA)
	if lava_cells.size() > 0 and (not cmds.generating):
		for lava_cell in lava_cells:
			await cmds.execute_command(CommandTerrainRemove.new(lava_cell))
		var gen : PuzzleGenerator = cmds.visualizer.generator
		var ice_cells_occupied := gen.get_cells_with_type(CellData.TerrainType.ICE, gen.get_cells_with_machine())
		for ice_cell in ice_cells_occupied:
			await cmds.execute_command(CommandTerrainRemove.new(ice_cell))
	
	return true

# this command mostly spawns new commands; they undo themselves
func undo(_cmds:PuzzleCommands) -> bool:
	arrow.change_times_used(-1)
	return true

func matches(cmd:PuzzleCommand) -> bool:
	if not (cmd is CommandArrow): return false
	return arrow == cmd.arrow

func is_valid() -> bool:
	if not arrow.is_usable(): return false
	
	var cmds := get_commands()
	if cmds.size() <= 0: return false
	
	# it's fine if SOME diggers move and SOME don't, 
	# it's just not allowed for ALL of them to not move
	var all_commands_invalid := true
	for cmd in cmds:
		if cmd.is_valid():
			all_commands_invalid = false
			break
	
	if all_commands_invalid: return false
	
	return true

func get_commands() -> Array[CommandMove]:
	var machines := arrow.get_machines_in_line()
	var arr : Array[CommandMove] = []
	for machine in machines:
		if not arrow.acts_on(machine): continue
		arr.append(CommandMove.new(get_direction(), machine))
	return arr

func get_direction() -> PuzzleGrid.Direction:
	return arrow.direction
