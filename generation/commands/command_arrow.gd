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
	
	# execute all move commands in parallel
	var commands_valid : Array[CommandMove] = get_commands().filter(func(c:CommandMove): return c.is_valid())
	for cmd in commands_valid:
		# cache/track some statistics of what we did for generation sanity checks
		var target_cell := cmd.get_target_cell()
		cells_targeted.append(target_cell)
		cells_targeted_by_machine[cmd.machine] = target_cell
		machines_targeted.append(cmd.machine)
		
		cmds.execute_command(cmd)
	
	if cmds.generating: return true
	
	# we want moves to happen in PARALLEL, so we don't await them one by one in code above
	# but catch every move as it finishes and simply count if we're done
	var cmd_seq : Array[PuzzleCommand]
	cmd_seq.assign(commands_valid)
	await cmds.await_command_sequence(cmd_seq)
	
	for cell in cells_targeted:
		await cell.get_terrain_resource().on_post_move(cell, cmds)
	
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
