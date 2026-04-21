class_name PuzzleGenerator

#region DifficultySettings

var grid_width_bounds := Vector2i(3,3)
var grid_height_bounds := Vector2i(3,3)
var num_turns_bounds := Vector2i(2,4)

var allow_backtracking := false
var arrow_max_times_used := 1
var arrow_point_anywhere := false
var forbid_terrains_for_treasure := true
var forbid_treasure_below_machines := false

var arrow_randomization_prob := 0.0
var add_fake_terrains := false

# This is only about SPECIAl types; the default types + treasure are always active otherwise there is no puzzle to speak of
var terrain_types_allowed : Array[CellData.TerrainType] = []

# When introducing a new type, we want to make sure it actually appears on the map otherwise the tutorial is really confusing :p
var terrain_type_required := CellData.TerrainType.NONE

#endregion

# @NOTE: `load()` and not `preload()` because of cyclic dependency errors that only show up on exported builds => https://github.com/godotengine/godot/issues/100100
# REMINDER TO SELF: Do this in a cleaner way in future projects then
static var terrain_types_library : Dictionary[CellData.TerrainType, TerrainData] = {
	CellData.TerrainType.NONE: load("res://generation/terrains/terrain_default.tres"),
	CellData.TerrainType.STONE: load("res://generation/terrains/terrain_stone.tres"),
	CellData.TerrainType.WEB: load("res://generation/terrains/terrain_web.tres"),
	CellData.TerrainType.ENERGY: load("res://generation/terrains/terrain_energy.tres"),
	CellData.TerrainType.ICE: load("res://generation/terrains/terrain_ice_lava.tres"),
	CellData.TerrainType.LAVA: load("res://generation/terrains/terrain_ice_lava.tres"),
	CellData.TerrainType.ARROWS: load("res://generation/terrains/terrain_arrows.tres"),
}

var allow_reversing := false
var remove_all_unused_arrows := true

var treasure_probability := 0.33
var treasure_total := 0
var treasure_max_ratio := 0.75

var arrow_randomization_bounds := Vector2i(1,2)
var fake_terrains_prob := 0.25
var place_all_machines_at_start := true # @NOTE: the other implementation is BROKEN

var alt_terrain_prob := 0.2
var num_machines : int = PuzzleSettings.get_value("number_of_diggers")

var grid : PuzzleGrid

var arrows : Array[ArrowData] = []
var arrows_by_location : Dictionary[PuzzleGrid.Direction, Array] = {}

var machines : Array[MachineData] = []

var solution : Array[PuzzleCommand] = []
var max_turns := 0

func generate() -> void:
	PuzzleSettings.apply_difficulty_properties(self)
	arrow_point_anywhere = PuzzleSettings.get_value("randomize_arrow_directions")
	if PuzzleSettings.get_value("make_solution_perfect"):
		add_fake_terrains = false
		arrow_randomization_prob = 0.0
	
	var num_tries := 0
	var max_tries := 50
	while true:
		print("PuzzleGenerator | Attempt ", num_tries)
		num_tries += 1
		create_grid()
		take_turns()
		var success := clean_up(num_tries >= max_tries)
		if success: break

func create_grid() -> void:
	# some custom exceptions for extreme cases; ensure grid is large enough
	if num_machines >= 4:
		grid_width_bounds.x = maxi(grid_width_bounds.x, 4)
		grid_height_bounds.x = maxi(grid_height_bounds.x, 4)
	
	# create the basic empty grid
	var grid_size := Vector2(randi_range(grid_width_bounds.x, grid_width_bounds.y), randi_range(grid_height_bounds.x, grid_height_bounds.y))
	grid = PuzzleGrid.new()
	grid.creation_callback = func(pos:Vector2i): return CellData.new(pos)
	grid.create(grid_size)
	
	# create all the arrows
	arrows = []
	arrows_by_location = {}
	
	var directions := PuzzleGrid.get_orthogonal_directions()
	for dir in directions:
		arrows_by_location[dir] = []
	
	for x in range(grid_size.x):
		var arrow_top := ArrowData.new(x, PuzzleGrid.Direction.UP, self)
		add_arrow(arrow_top)
		var arrow_bottom := ArrowData.new(x, PuzzleGrid.Direction.DOWN, self)
		add_arrow(arrow_bottom)
	
	for y in range(grid_size.y):
		var arrow_left := ArrowData.new(y, PuzzleGrid.Direction.LEFT, self)
		add_arrow(arrow_left)
		var arrow_right := ArrowData.new(y, PuzzleGrid.Direction.RIGHT, self)
		add_arrow(arrow_right)
	
	# create all the machines
	machines = []
	for i in range(num_machines):
		machines.append(MachineData.new(i))

func add_arrow(ad:ArrowData) -> void:
	# point into map by default; otherwise pick random
	var direction := PuzzleGrid.get_opposite_direction_of(ad.location)
	if arrow_point_anywhere:
		direction = PuzzleGrid.get_orthogonal_directions().pick_random()
	ad.set_direction(direction)
	
	arrows.append(ad)
	arrows_by_location[ad.location].append(ad)

func get_arrow(idx:int, loc:PuzzleGrid.Direction) -> ArrowData:
	return arrows_by_location[loc][idx]

func get_all_cells() -> Array[CellData]:
	var arr : Array[CellData]
	arr.assign(grid.cells)
	return arr

func get_random_cell() -> CellData:
	return grid.cells.pick_random()

func count_arrows() -> int:
	return arrows.size()

func count_machines() -> int:
	return machines.size()

func get_num_turns_bounds() -> Vector2i:
	var grid_size := grid.cells.size()
	return Vector2i(floori(0.5*grid_size), floor(grid_size))

func take_turns() -> void:
	var turns_bounds := get_num_turns_bounds()
	var num_turns := randi_range(turns_bounds.x, turns_bounds.y) 
	
	var turns_between_machine_add_bounds := Vector2i(0, floori(num_turns / float(machines.size())) - 1)

	# place first machine; the others are added as we go
	# (we stagger this to _ensure_ machines have interplay, at least on the first turn they move)
	var last_active_machine_index := 0
	var next_machine_turn := randi_range(turns_between_machine_add_bounds.x, turns_between_machine_add_bounds.y)
	
	var cells := get_all_cells()
	if place_all_machines_at_start:
		cells.shuffle()
		for machine in machines:
			cells.pop_back().add_machine(machine)
	else:
		cells.pick_random().add_machine(machines[0])
	
	# tap random arrows to move the machines around
	var commands := PuzzleCommands.new()
	solution = []
	while solution.size() < num_turns:
		var valid_turns := get_all_valid_turns()
		if valid_turns.size() <= 0: break
		
		var cur_turn := solution.size()
		var turn_picked : CommandArrow = valid_turns.pick_random()
		
		# when it's the right time, and we have machines left to place, place one
		# @NOTE: we do this BEFORE executing the command to make sure this new machine is moved along with it!
		if (not place_all_machines_at_start) and cur_turn == next_machine_turn and last_active_machine_index < (count_machines() - 1):
			last_active_machine_index += 1
			place_new_machine(turn_picked.arrow, last_active_machine_index)
			next_machine_turn += randi_range(turns_between_machine_add_bounds.x, turns_between_machine_add_bounds.y)
		
		# adding that machine might have made the turn invalid, so check
		if not turn_picked.is_valid(): continue
		
		# do the actual turn
		commands.execute_command(turn_picked)
		solution.append(turn_picked)
		
		# place treasure where machines ended up (if we CAN and SHOULD)
		for machine in turn_picked.cells_targeted_by_machine:
			var cell := turn_picked.cells_targeted_by_machine[machine]
			var should_place_treasure := randf() <= treasure_probability or machine.turns_since_last_treasure() > 2
			if cell.can_place_treasure() and should_place_treasure:
				var new_treasure_num := machine.get_last_treasure_number() + 1
				cell.add_treasure(new_treasure_num)
				machine.set_last_treasure_number(new_treasure_num)
	
	# always place treasure on machine's FINAL squares (otherwise last path is meaningless)
	# if we can't, keep working backwards, trying and trying to place something
	# (in rare cases the algorithm terminates before placing all machines, which is always a failure case and we should immediately quit if so)
	var is_invalid := false
	for machine in machines:
		var path := machine.path
		if path.size() <= 0:
			is_invalid = true
			break
		
		machine.cell.is_machine_ending_pos = true
		
		# @NOTE: goes to 0 instead of -1 because start pos is never allowed to have treasure
		for i in range(path.size()-1,0,-1):
			var cur_cell := path[i]
			if not cur_cell.can_place_treasure(): continue
			cur_cell.add_treasure(machine.get_last_treasure_number() + 1)
			break
	
	if is_invalid: return
	
	# we set this value here because terrain types might manipulate it later
	max_turns = solution.size()
	generate_terrains()
	
	# finally, all cells that are left untouched go to the default terrain setting
	for cell in get_all_cells():
		if cell.type != CellData.TerrainType.NONE: continue
		var filler_type := CellData.TerrainType.REGULAR_ALT if randf() <= alt_terrain_prob else CellData.TerrainType.REGULAR
		cell.set_terrain(filler_type)

func get_cells_available_for_terrain() -> Array[CellData]:
	var cells_undecided := get_all_cells().filter(func(c:CellData): return c.can_receive_special_terrain())
	if forbid_terrains_for_treasure:
		cells_undecided = cells_undecided.filter(func(c:CellData): return not c.has_treasure())
	
	cells_undecided.shuffle()
	return cells_undecided

func get_cells_with_type(tp:CellData.TerrainType, list:Array[CellData] = []) -> Array[CellData]:
	if list.size() <= 0: list.assign(grid.cells)
	return list.filter(func(c:CellData): return c.type == tp)

func get_cells_with_machine(list:Array[CellData] = []) -> Array[CellData]:
	if list.size() <= 0: list.assign(grid.cells)
	return list.filter(func(c:CellData): return c.has_machine())

func generate_terrains() -> void:
	# sort types first; some want to generate earlier than others for maximum effect
	var types := terrain_types_allowed.duplicate(false)
	types.sort_custom(func(a:CellData.TerrainType, b:CellData.TerrainType): 
		return terrain_types_library[a].priority < terrain_types_library[b].priority
	)
	
	# then let the individual scripts handle generating that type
	for type in types:
		if not (type in terrain_types_library): continue
		terrain_types_library[type].generate(self)

func change_max_turns(dmt:int) -> void:
	max_turns += dmt

func place_new_machine(arrow:ArrowData, machine_index:int) -> bool:
	var cells_in_same_line := arrow.get_cells_in_line()
	var cells_valid := cells_in_same_line.filter(func(c:CellData): return c.can_receive_machine())
	
	var rand_cell : CellData
	if cells_valid.size() <= 0:
		rand_cell = grid.cells.filter(func(c:CellData): return c.can_receive_machine()).pick_random()
	else:
		rand_cell = cells_valid.pick_random()
	
	if not rand_cell: return false
	
	rand_cell.add_machine(machines[machine_index])
	return true

func get_all_arrows_acting_on(pos:Vector2i) -> Array[ArrowData]:
	var indices : Array[int] = [pos.x, pos.x, pos.y, pos.y]
	var directions : Array[PuzzleGrid.Direction] = [PuzzleGrid.Direction.UP, PuzzleGrid.Direction.DOWN, PuzzleGrid.Direction.LEFT, PuzzleGrid.Direction.RIGHT]
	var arr : Array[ArrowData] = []
	for i in range(indices.size()):
		arr.append(get_arrow(indices[i], directions[i]))
	return arr

func get_all_valid_turns() -> Array[CommandArrow]:
	var all_turns : Array[CommandArrow] = []
	
	# get all possible moves
	for machine in machines:
		if not machine.has_been_placed(): continue
		var arrows_relevant := get_all_arrows_acting_on(machine.cell.pos) 
		for arrow in arrows_relevant:
			var cmd := CommandArrow.new(arrow)
			if not cmd.is_valid(): continue # ignore moves that would do nothing
			all_turns.append(cmd)
	
	# check for more specific/complicated rules for what to filter out
	var valid_turns : Array[CommandArrow] = []
	for command_arrow in all_turns:
		var is_valid := true
		for command_move in command_arrow.get_commands():
			var machine_path := command_move.machine.path
			var target_cell := command_move.get_target_cell()
			
			# this does not allow visiting ANY cell twice (with the same digger
			if not allow_backtracking and machine_path.has(target_cell):
				is_valid = false
				break
			
			# this does not allow going BACK the way you came (a pointless shuffle usually)
			if (not allow_reversing) and machine_path.size() > 1 and machine_path[machine_path.size() - 2] == target_cell:
				is_valid = false
				break
			
			# this ignores arrows that have been used the maximum number of times
			# (it's NOT the same as enabled/locked as those are game state things)
			if command_arrow.arrow.num_times_used >= arrow_max_times_used:
				is_valid = false
				break
		
		if not is_valid: continue
		
		# we're fine, the turn is valid, add it
		valid_turns.append(command_arrow)
	
	valid_turns.shuffle()
	
	return valid_turns

func get_first_visit_to(cell:CellData) -> int:
	for i in range(solution.size()):
		var cmd := solution[i] as CommandArrow
		if cmd.cells_targeted.has(cell):
			return i
	return -1

func count_arrow_usage_until_turn(arrow:ArrowData, turn:int) -> int:
	var sum := 0
	for i in range(turn + 1):
		var cmd := solution[i] as CommandArrow
		if cmd.arrow != arrow: continue
		sum += 1
	return sum

func count_treasure() -> int:
	var sum := 0
	for cell in grid.cells:
		if cell.has_treasure():
			sum += 1
	return sum

func clean_up(desperate := false) -> bool:
	# crucial checks that must be fulfilled
	# > All machines must have been used
	var machines_unused := machines.filter(func(m:MachineData): return not m.has_been_placed())
	if machines_unused.size() > 0: 
		print("PuzzleGenerator | Attempt Discarded | Not all machines used")
		return false
	
	# > Required type unused
	if terrain_type_required != CellData.TerrainType.NONE:
		var cells := get_cells_with_type(terrain_type_required)
		if cells.size() <= 0:
			print("PuzzleGenerator | Attempt Discarded | A required terrain type was not present")
			return false
	
	# > We can't have too much treasure 
	# > (looks silly + too few special terrains + makes moves not matter much)
	# (this does not "fail" our generation, but we need to do it here because later checks require an accurate final treasure count)
	var num_cells := grid.cells.size()
	var cells_with_treasure := get_all_cells().filter(func(c:CellData): return c.has_treasure())
	var num_treasure := cells_with_treasure.size()
	var too_much_treasure := (num_treasure / float(num_cells)) > treasure_max_ratio
	if too_much_treasure:
		var cells_removable := cells_with_treasure.filter(func(c:CellData): return not c.treasure_is_required())
		cells_removable.shuffle()
		while too_much_treasure and cells_removable.size() > 0:
			var cell : CellData = cells_removable.pop_back()
			cell.remove_treasure()
			num_treasure -= 1
			too_much_treasure = (num_treasure / float(num_cells)) > treasure_max_ratio
	
	# > Check when treasure is first collected
	# > So we can figure out if all of it is collected too soon ( = before end of solution)
	var turn_treasure_collected : Dictionary[CellData, Array] = {}
	for i in range(solution.size()):
		var cmd := solution[i] as CommandArrow
		for cell in cmd.cells_targeted:
			if not cell.has_treasure(): continue
			if not (cell in turn_treasure_collected):
				turn_treasure_collected[cell] = []
			
			var is_web := cell.type == CellData.TerrainType.WEB
			var max_registers := cell.custom_number if is_web else 1
			if turn_treasure_collected[cell].size() >= max_registers: continue
			
			turn_treasure_collected[cell].append(i)
	
	var final_moves_collecting_treasure := turn_treasure_collected.keys().filter(func(c:CellData): return turn_treasure_collected[c].back() == (solution.size() - 1))
	var last_move_collects_treasure := final_moves_collecting_treasure.size() > 0
	if not last_move_collects_treasure:
		print("PuzzleGenerator | Attempt Discarded | Last move does not collect gold (and thus part of the solution is likely pointless)")
		return false
	
	# more nice-to-have checks that can be loosened
	if not desperate:
		var num_turns := solution.size()
		var used_enough_turns := num_turns >= get_num_turns_bounds().x
		if not used_enough_turns: 
			print("PuzzleGenerator | Attempt Discarded | Not enough turns")
			return false
		
		var too_little_treasure : bool = num_treasure < maxi(2, ceili(0.66*count_machines()))
		if too_little_treasure: 
			print("PuzzleGenerator | Attempt Discarded | Too little treasure placed")
			return false
		
		var machines_moved_enough := true
		var min_moves := mini(grid.size.x, floori(0.5 * num_turns / float(num_machines))) # seems a reasonable lower bound
		for machine in machines:
			if machine.path.size() < min_moves:
				machines_moved_enough = false
				break
		if not machines_moved_enough:
			print("PuzzleGenerator | Attempt Discarded | One or more machines did not move often enough")
			return false
		
		for machine in machines:
			var final_cell_has_treasure := machine.cell.has_treasure()
			if not final_cell_has_treasure or (machine.cell.count_visits() > machine.cell.get_max_visits_allowed_for_treasure()):
				print("PuzzleGenerator | Attempt Discarded | A machine doesn't end on treasure or that treasure will have been captured earlier.")
				return false

	# put machines back where they started
	for machine in machines:
		machine.cell.remove_machine(machine)
		machine.path.front().add_machine(machine)
		machine.set_last_treasure_number(-1)
	
	# add "wrong" special cells not needed for the solution
	# @NOTE: must come before cell reset because that removes history of machines visiting
	var terrains_that_can_be_fake : Array[CellData.TerrainType] = terrain_types_allowed.duplicate(false)
	if add_fake_terrains:
		var regular_cells := get_all_cells().filter(func(c:CellData): return c.can_receive_fake_terrain())
		for cell in regular_cells:
			if randf() > fake_terrains_prob: continue
			terrains_that_can_be_fake.shuffle()
			for terrain in terrains_that_can_be_fake:
				var success := terrain_types_library[terrain].generate_fake(self, cell)
				if success: break
	
	# reset cells similarly
	for cell in get_all_cells():
		cell.reset_after_generation()
	
	# cache how much total treasure there is to collect
	treasure_total = count_treasure()
	
	# set arrow data based on their usage during generation
	for arrow in arrows:
		if randf() <= arrow_randomization_prob:
			arrow.num_times_used = clampi(arrow.num_times_used + randi_range(arrow_randomization_bounds.x, arrow_randomization_bounds.y), 0, arrow_max_times_used)
		if remove_all_unused_arrows and not arrow.has_been_used():
			arrow.set_enabled(false)
		arrow.calculate_usage_and_reset()
	
	return true
