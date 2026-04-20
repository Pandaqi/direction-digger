extends TerrainData
class_name TerrainStone

func generate(gen:PuzzleGenerator) -> void:
	var cells_undecided := gen.get_cells_available_for_terrain()
	
	var elems_complete_block := draw_elements_balanced(get_cells_unvisited(cells_undecided))
	for cell in elems_complete_block:
		cell.set_terrain(CellData.TerrainType.STONE)
	
	var elems_visited_by_one := get_cells_visited(cells_undecided).filter(func(c:CellData): return c.has_seen_only_one_machine())
	elems_visited_by_one = draw_elements_balanced(elems_visited_by_one)
	for cell in elems_visited_by_one:
		cell.set_terrain(CellData.TerrainType.STONE)
		cell.set_machine_filter(cell.get_machine_indices().front())

func generate_fake(_gen:PuzzleGenerator, c:CellData) -> bool:
	if c.has_been_visited(): return false
	c.set_terrain(CellData.TerrainType.STONE)
	return true

func is_move_valid(cell:CellData, cmd:CommandMove) -> bool:
	if cell != cmd.target_cell: return true
	var terrain_active := cmd.target_cell.terrain_acts_on(cmd.machine, true)
	return not terrain_active
