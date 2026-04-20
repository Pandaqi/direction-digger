extends TerrainData
class_name TerrainIceLava

@export var debug_print := false

func generate(gen:PuzzleGenerator) -> void:
	# small helper class to track statistics in a clean (type-checked) way
	var machine_move_data : Dictionary[MachineData, MachineMoveData] = {}
	for machine in gen.machines:
		machine_move_data[machine] = MachineMoveData.new(machine.path)
	
	# step through the solution;
	# every turn, determine if this could be a LAVA turn
	# by placing LAVA now and ICE on the last cell of previous (non-moving) machines
	var sol := gen.solution
	var last_lava_turn := -1
	var cells_visited_so_far : Array[CellData] = []
	
	for i in range(sol.size()): 
		var cmd := sol[i] as CommandArrow
		
		# register which machines moved this turn
		var machines_moved := cmd.machines_targeted
		for machine in machines_moved:
			machine_move_data[machine].register_turn_moved(i)
		
		# check which machines are in play, but did NOT move this turn
		# it means those machines could be FROZEN (on their last cell)
		# and the machines that DID move this turn can enter a LAVA cell (to unfreeze them)
		var machines_in_play : Array[MachineData] = []
		var machines_can_be_frozen : Array[MachineData] = []
		for machine in gen.machines:
			var move_data := machine_move_data[machine]
			if not move_data.is_in_play(): continue
			
			machines_in_play.append(machine)
			
			var gap_in_movement := move_data.get_last_turn_moved() != i
			var last_move_after_last_lava := move_data.get_last_turn_moved() > last_lava_turn
			if gap_in_movement and last_move_after_last_lava:
				machines_can_be_frozen.append(machine)
		
		var success := try_lava_placement(i, sol.size(), machines_moved, machines_can_be_frozen, machine_move_data, cells_visited_so_far)
		if success: last_lava_turn = i
		
		# finally, register the cells visited now
		# this prevents anyone accidentally visiting lava/ice BEFORE it actually has to be used, removing it and breaking the puzzle
		cells_visited_so_far += cmd.cells_targeted
	
	# debugging: print what our move data tells us
	if debug_print:
		for machine in gen.machines:
			var move_data := machine_move_data[machine]
			var steps : Array[String] = []
			for i in range(machine.path.size()):
				steps.append(str(move_data.get_turn(i)) + ": " + str(machine.path[i].pos))
			print(" -> ".join(steps))

func try_lava_placement(
	turn: int,
	max_turns: int,
	machines_moved:Array[MachineData], 
	machines_can_be_frozen:Array[MachineData], machine_move_data:Dictionary[MachineData,MachineMoveData], cells_visited_so_far:Array[CellData]) -> bool:
	
	var is_last_turn := turn >= (max_turns - 1)
	if is_last_turn: return false
	
	var can_add_lava := machines_can_be_frozen.size() > 0
	if not can_add_lava: return false
	
	# collect possible cells for the LAVA; if none available, we abort
	var possible_lava_cells : Array[CellData] = []
	for machine in machines_moved:
		var cur_cell := machine_move_data[machine].get_current_cell()
		if not cur_cell.can_receive_special_terrain(): continue
		if cells_visited_so_far.has(cur_cell): continue
		possible_lava_cells.append(cur_cell)
	
	if possible_lava_cells.size() <= 0: return false
	
	# collect possible cells for the ICE; if none available, we abort too
	var possible_ice_cells : Array[CellData] = []
	for machine in machines_can_be_frozen:
		var cur_cell := machine_move_data[machine].get_current_cell()
		if not cur_cell.can_receive_special_terrain(): continue
		
		# the machine currently here obviously visited it, so it should appear ONCE
		# but if it appears TWICE or more, then we can't use this cell as it will be the wrong order and break the puzzle
		var num_times_visited := cells_visited_so_far.filter(func(c:CellData): return c == cur_cell).size()
		if num_times_visited > 1: continue
		
		possible_ice_cells.append(cur_cell)
	
	if possible_ice_cells.size() <= 0: return false
	
	# the coast is clear! we can do this!
	# the likelihood of going for this increases as the puzzle goes on
	# (to ensure we do it at least ONCE, but also keep some randomness and not do it at the start)
	var probability := (turn + 1) / float(max_turns)
	if randf() > probability: return false
	
	var rand_lava : CellData = possible_lava_cells.pick_random()
	rand_lava.set_terrain(CellData.TerrainType.LAVA)
	
	var num_ice_cells := ceili(lerpf(1.0, possible_ice_cells.size(), probability))
	var ice_cells_chosen := possible_ice_cells.slice(0, num_ice_cells)
	for cell in ice_cells_chosen:
		cell.set_terrain(CellData.TerrainType.ICE)
	
	return true

# we can add lava cells anywhere; ice cells not so much
func generate_fake(_gen:PuzzleGenerator, c:CellData) -> bool:
	# we heavily prefer placing lava on unvisited cells
	if c.has_been_visited() and randf() <= 0.75: return false
	c.set_terrain(CellData.TerrainType.LAVA)
	return true
