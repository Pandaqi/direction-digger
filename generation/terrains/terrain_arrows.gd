extends TerrainData
class_name TerrainArrows

func generate(gen:PuzzleGenerator) -> void:
	var cells_visited := get_cells_visited(gen.get_cells_available_for_terrain())
	
	# grab the arrows that every cell could add
	var options : Dictionary[CellData, Array] = {}
	for cell in cells_visited:
		var turn_index := gen.get_first_visit_to(cell)
		
		var arrows := gen.get_all_arrows_acting_on(cell.pos)
		var arrows_valid : Array[ArrowData] = []
		for arrow in arrows:
			# EXAMPLE: If an arrow has number 3, and it has already been used 3 times before now, then we CAN'T add it with this special cell because we'd break the puzzle and never reach this point!
			var num_times_used_so_far := gen.count_arrow_usage_until_turn(arrow, turn_index)
			var num_times_used_total := arrow.num_times_used
			if num_times_used_so_far >= num_times_used_total: continue
			arrows_valid.append(arrow)
		
		if arrows_valid.size() <= 0: continue
		
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
