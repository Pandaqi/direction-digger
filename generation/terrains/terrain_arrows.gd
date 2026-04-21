extends TerrainData
class_name TerrainArrows

var audio_positive := load("res://generation/terrains/diamond-clink.ogg")

func generate(gen:PuzzleGenerator) -> void:
	var options : Dictionary[CellData, Array] = {}
	var turns_exhausted : Array[int] = []
	var cells_visited := get_cells_visited(gen.get_cells_available_for_terrain())
	
	# grab the arrows that every cell could add
	for cell in cells_visited:
		var turn_index := gen.get_first_visit_to(cell)
		
		# there's a nasty situation in which MULTIPLE machines grab this type of cell within the same turn, which can lead to broken puzzles because we do -2 to the _same arrow_, making it unclickable and that turn unreachable
		# SO, just only allow a single cell option per turn
		if turns_exhausted.has(turn_index): continue
		
		var arrows := gen.get_all_arrows_acting_on(cell.pos)
		var arrows_valid : Array[ArrowData] = []
		for arrow in arrows:
			if not arrow.has_been_used(): continue
			
			# EXAMPLE: If an arrow has number 3, and it has already been used 3 times before now, then we CAN'T add it with this special cell because we'd break the puzzle and never reach this point!
			var num_times_used_so_far := gen.count_arrow_usage_until_turn(arrow, turn_index)
			var num_times_used_total := arrow.num_times_used
			if num_times_used_so_far >= num_times_used_total: continue
			arrows_valid.append(arrow)
		
		if arrows_valid.size() <= 0: continue
		
		turns_exhausted.append(turn_index)
		options[cell] = arrows_valid
	
	if options.size() <= 0: return
	
	# randomly apply the terrain to some of the options
	var options_picked := draw_elements_balanced(options.keys())
	for cell in options_picked:
		var arrows_to_add : Array[ArrowData]
		arrows_to_add.assign(options[cell])
		
		cell.set_terrain(CellData.TerrainType.ARROWS)
		cell.set_custom_arrows(arrows_to_add)
		
		# remember we need to lower the starting value of this arrow
		for arrow in arrows_to_add:
			arrow.num_times_modifier -= 1

func generate_fake(gen:PuzzleGenerator, c:CellData) -> bool:
	var arrows := gen.get_all_arrows_acting_on(c.pos)
	arrows.shuffle()
	var rand_num := randi_range(1, arrows.size())
	
	c.set_terrain(CellData.TerrainType.ARROWS)
	c.set_custom_arrows(arrows.slice(0, rand_num))
	return true

func on_move(cell:CellData, _cmd:CommandMove, cmds:PuzzleCommands) -> void:
	cmds.visualizer.play_audio_custom(cell, audio_positive)
	await cmds.execute_command(CommandArrowsChange.new(cell))
