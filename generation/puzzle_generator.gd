class_name PuzzleGenerator

var grid_width_bounds := Vector2i(3,3)
var grid_height_bounds := Vector2i(3,3)
var num_turns_bounds := Vector2i(3,6)
var num_machines : int = PuzzleSettings.get_value("number_of_diggers")

var grid : PuzzleGrid

var arrows : Array[ArrowData] = []
var arrows_by_location : Dictionary[PuzzleGrid.Direction, Array] = {}

var machines : Array[MachineData] = []

var solution : Array[PuzzleCommand] = []

var debug_num_machines := 2

func generate() -> void:
	num_machines = clampi(num_machines, 1, 4)
	if OS.is_debug_build():
		num_machines = debug_num_machines
	
	create_grid()
	take_turns()
	clean_up()

func create_grid() -> void:
	# create the basic empty grid
	var grid_size := Vector2(randi_range(grid_width_bounds.x, grid_width_bounds.y), randi_range(grid_height_bounds.x, grid_height_bounds.y))
	grid = PuzzleGrid.new()
	grid.creation_callback = func(pos:Vector2i): return CellData.new(pos)
	grid.create(grid_size)
	
	# create all the arrows
	var directions := PuzzleGrid.get_orthogonal_directions()
	for dir in directions:
		arrows_by_location[dir] = []
	
	# @TODO: in the future we might allow arrows to point in ANY direction, but by default I'll just let them point into the map for now
	for x in range(grid_size.x):
		var arrow_top := ArrowData.new(x, PuzzleGrid.Direction.UP, PuzzleGrid.Direction.DOWN, self)
		add_arrow(arrow_top)
		var arrow_bottom := ArrowData.new(x, PuzzleGrid.Direction.DOWN, PuzzleGrid.Direction.UP, self)
		add_arrow(arrow_bottom)
	
	for y in range(grid_size.y):
		var arrow_left := ArrowData.new(y, PuzzleGrid.Direction.LEFT, PuzzleGrid.Direction.RIGHT, self)
		add_arrow(arrow_left)
		var arrow_right := ArrowData.new(y, PuzzleGrid.Direction.RIGHT, PuzzleGrid.Direction.LEFT, self)
		add_arrow(arrow_right)
	
	# create all the machines
	for i in range(num_machines):
		machines.append(MachineData.new(i))

func add_arrow(ad:ArrowData) -> void:
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

func take_turns() -> void:
	var num_turns_per_machine := randi_range(num_turns_bounds.x, num_turns_bounds.y)
	var num_turns := num_turns_per_machine * num_machines
	
	var turns_between_machine_add_bounds := Vector2i(0, num_turns_per_machine - 1)

	# place first machine; the others are added as we go
	# (we stagger this to _ensure_ machines have interplay, at least on the first turn they move)
	var last_active_machine_index := 0
	var next_machine_turn := randi_range(turns_between_machine_add_bounds.x, turns_between_machine_add_bounds.y)
	var rand_cell := get_random_cell()
	rand_cell.add_machine(machines[0])
	
	# tap random arrows to move the machines around
	var commands := PuzzleCommands.new()
	solution = []
	for i in range(num_turns):
		var valid_turns := get_all_valid_turns()
		if valid_turns.size() <= 0: break
		
		var turn_picked : CommandArrow = valid_turns.pick_random()
		solution.append(turn_picked)
		
		# when it's the right time, and we have machines left to place, place one
		# @NOTE: we do this BEFORE executing the command to make sure this new machine is moved along with it!
		if i == next_machine_turn and last_active_machine_index < (count_machines() - 1):
			last_active_machine_index += 1
			place_new_machine(turn_picked.arrow, last_active_machine_index)
			next_machine_turn += randi_range(turns_between_machine_add_bounds.x, turns_between_machine_add_bounds.y)
		
		commands.execute_command(turn_picked)
	
	# now place gold on the paths that machines took
	# (we always place one on our FINAL square, otherwise the last bit of path is meaningless)
	# @TODO: guard against picking a cell we picked before! (==> We'd want a general guard against visiting old squares we've already been anyway
	for machine in machines:
		var path := machine.path
		var next_gold := path.size() - 1
		for i in range(path.size() -1, -1, -1):
			if i != next_gold: continue
			path[i].add_treasure()
			next_gold = i - randi_range(2,4)
	
	# now place special blocks around the paths that machines took
	# @TODO
	
	# finally, set arrow data based on how they've been used
	# (disable those unused, set counter on how OFTEN an arrow has been used)
	# @TODO: A setting that FORBIDS using an arrow more than once? Could be useful for low difficulties ...
	
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

func get_all_valid_turns() -> Array[CommandArrow]:
	# first collect ALL options
	var arr : Array[CommandArrow] = []
	for machine in machines:
		if not machine.has_been_placed(): continue
		var pos := machine.cell.pos
		arr.append(CommandArrow.new(get_arrow(pos.x, PuzzleGrid.Direction.UP)))
		arr.append(CommandArrow.new(get_arrow(pos.x, PuzzleGrid.Direction.DOWN)))
		arr.append(CommandArrow.new(get_arrow(pos.y, PuzzleGrid.Direction.LEFT)))
		arr.append(CommandArrow.new(get_arrow(pos.y, PuzzleGrid.Direction.RIGHT)))
	
	# @TODO
	# then filter those that are invalid
	# -> it'd have no effect (it does not actually move any machine)
	# -> the arrow is disabled/ocked/whatever
	# -> the arrow only applies to one machine (and it's not in the row OR it would move into an occupied space)	
	
	return arr

func clean_up() -> void:
	pass
