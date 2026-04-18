class_name PuzzleGenerator

var grid_width_bounds := Vector2i(3,3)
var grid_height_bounds := Vector2i(3,3)
var num_turns_bounds := Vector2i(3,6)

var allow_backtracking := false
var allow_reversing := false
var arrow_max_times_used := 1
var remove_all_unused_arrows := true
var arrow_point_anywhere := true

var treasure_probability := 0.33
var num_machines : int = PuzzleSettings.get_value("number_of_diggers")

var grid : PuzzleGrid

var arrows : Array[ArrowData] = []
var arrows_by_location : Dictionary[PuzzleGrid.Direction, Array] = {}

var machines : Array[MachineData] = []

var solution : Array[PuzzleCommand] = []

func generate() -> void:
	PuzzleSettings.apply_difficulty_properties(self)
	
	var num_tries := 0
	var max_tries := 100
	while true:
		print("PuzzleGenerator | Attempt ", num_tries)
		num_tries += 1
		create_grid()
		take_turns()
		var success := clean_up(num_tries >= max_tries)
		if success: break

func create_grid() -> void:
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

func get_random_cell() -> CellData:
	return grid.cells.pick_random()

func count_arrows() -> int:
	return arrows.size()

func count_machines() -> int:
	return machines.size()

func get_num_turns_bounds() -> Vector2i:
	return num_turns_bounds * num_machines

func take_turns() -> void:
	var turns_bounds := get_num_turns_bounds()
	var num_turns := randi_range(turns_bounds.x, turns_bounds.y) 
	
	var turns_between_machine_add_bounds := Vector2i(0, floori(num_turns / float(machines.size())) - 1)

	# place first machine; the others are added as we go
	# (we stagger this to _ensure_ machines have interplay, at least on the first turn they move)
	var last_active_machine_index := 0
	var next_machine_turn := randi_range(turns_between_machine_add_bounds.x, turns_between_machine_add_bounds.y)
	var rand_cell := get_random_cell()
	rand_cell.add_machine(machines[0])
	
	# tap random arrows to move the machines around
	var commands := PuzzleCommands.new()
	solution = []
	while solution.size() < num_turns:
		var valid_turns := get_all_valid_turns()
		if valid_turns.size() <= 0: break
		
		var cur_turn := solution.size()
		var turn_picked : CommandArrow = valid_turns.pick_random()
		solution.append(turn_picked)
		
		# when it's the right time, and we have machines left to place, place one
		# @NOTE: we do this BEFORE executing the command to make sure this new machine is moved along with it!
		if cur_turn == next_machine_turn and last_active_machine_index < (count_machines() - 1):
			last_active_machine_index += 1
			place_new_machine(turn_picked.arrow, last_active_machine_index)
			next_machine_turn += randi_range(turns_between_machine_add_bounds.x, turns_between_machine_add_bounds.y)
		
		# adding that machine might have made the turn invalid, so check
		if not turn_picked.is_valid(): continue
		
		# do the actual turn
		commands.execute_command(turn_picked)
		
		# place treasure where machines ended up (if we CAN and SHOULD)
		for machine in turn_picked.cells_targeted_by_machine:
			var cell := turn_picked.cells_targeted_by_machine[machine]
			var should_place_treasure := randf() <= treasure_probability
			if cell.can_place_treasure() and should_place_treasure:
				var new_treasure_num := machine.get_last_treasure_number() + 1
				cell.add_treasure(new_treasure_num)
				machine.set_last_treasure_number(new_treasure_num)
	
	# now always place one on our FINAL square, 
	# (otherwise the last bit of path is meaningless)
	# (in rare cases the algorithm terminates before placing all machines, which is always a failure case and we should immediately quit if so)
	var is_invalid := false
	for machine in machines:
		var last_cell := machine.cell
		if not last_cell: 
			is_invalid = true
			break
		if not last_cell.can_place_treasure(): continue
		last_cell.add_treasure(machine.get_last_treasure_number() + 1)
	
	if is_invalid: return
	
	# now place special blocks around the paths that machines took
	# @TODO
	
	# @TODO: it might be worth placing some blocks _while_ moving machines for extra variation ---> such as a block that moves one machine, but not another when pressing an arrow that has them both in line

func place_new_machine(arrow:ArrowData, machine_index:int) -> bool:
	var cells_in_same_line := arrow.get_cells_in_line()
	var cells_valid := cells_in_same_line.filter(func(c:CellData): return c.can_receive_machine())
	
	var rand_cell : CellData
	if cells_valid.size() <= 0:
		rand_cell = grid.cells.filter(func(c:CellData): return c.can_receive_machine()).pick_random()
	else:
		rand_cell = cells_valid.pick_random()
	
	rand_cell.add_machine(machines[machine_index])
	return true

func get_all_arrows_acting_on(machine:MachineData) -> Array[ArrowData]:
	var pos := machine.cell.pos
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
		var arrows_relevant := get_all_arrows_acting_on(machine) 
		for arrow in arrows_relevant:
			var cmd := CommandArrow.new(arrow)
			if not cmd.is_valid(): continue # ignore moves that would do nothing
			all_turns.append(cmd)
	
	# check for more specific/complicated rules for what to filter out
	var valid_turns : Array[CommandArrow] = []
	for command_arrow in all_turns:
		for command_move in command_arrow.get_commands():
			var machine_path := command_move.machine.path
			var target_cell := command_move.get_target_cell()
			
			# this does not allow visiting ANY cell twice (with the same digger
			if not allow_backtracking and machine_path.has(target_cell):
				continue
			
			# this does not allow going BACK the way you came (a pointless shuffle usually)
			if not allow_reversing and machine_path.size() > 0 and machine_path.back() == target_cell:
				continue
			
			# this ignores arrows that have been used the maximum number of times
			# (it's NOT the same as enabled/locked as those are game state things)
			if command_arrow.arrow.num_times_used >= arrow_max_times_used:
				continue
			
			# we're fine, the turn is valid, add it
			valid_turns.append(command_arrow)
	
	valid_turns.shuffle()
	
	return valid_turns

func count_treasure() -> int:
	var sum := 0
	for cell in grid.cells:
		if cell.has_treasure():
			sum += 1
	return sum

func clean_up(desperate := false) -> bool:
	# crucial checks that must be fulfilled
	var machines_unused := machines.filter(func(m:MachineData): return not m.has_been_placed())
	if machines_unused.size() > 0: 
		print("PuzzleGenerator | Attempt Discarded | Not all machines used")
		return false
	
	# more nice-to-have checks that can be loosened
	if not desperate:
		var used_enough_turns := solution.size() >= get_num_turns_bounds().x
		if not used_enough_turns: 
			print("PuzzleGenerator | Attempt Discarded | Not enough turns")
			return false
		
		var last_move_collects_gold : bool = solution.back().cells_targeted.filter(func(c:CellData): return c.has_treasure()).size() > 0
		if not last_move_collects_gold: 
			print("PuzzleGenerator | Attempt Discarded | Last move does not collect gold (and is thus likely pointless)")
			return false
		
		var too_little_treasure : bool = count_treasure() < maxi(2, ceili(0.66*count_machines()))
		if too_little_treasure: 
			print("PuzzleGenerator | Attempt Discarded | Too little treasure placed")
			return false

	# put machines back where they started
	for machine in machines:
		machine.cell.remove_machine(machine)
		machine.path.front().add_machine(machine)
		machine.set_last_treasure_number(-1)
	
	# set arrow data based on their usage during generation
	# @TODO: some setting for "randomizing" this, so SOME unneeded arrows are shown and SOME numbers are higher than strictly needed?
	for arrow in arrows:
		if remove_all_unused_arrows and not arrow.has_been_used():
			arrow.set_enabled(false)
		arrow.calculate_usage_and_reset()
	
	return true
