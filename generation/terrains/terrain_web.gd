extends TerrainData
class_name TerrainWeb

@export var randomize_number := false

func generate(gen:PuzzleGenerator) -> void:
	var cells_visited := get_cells_visited(gen.get_cells_available_for_terrain())
	var cells_multi_visit : Array[CellData] = cells_visited.filter(func(c:CellData): return c.has_been_visited_multiple_times())
	cells_multi_visit = draw_elements_balanced(cells_multi_visit)
	
	for cell in cells_multi_visit:
		cell.set_terrain(CellData.TerrainType.WEB)
		var ideal_num := cell.count_visits()
		if randomize_number: ideal_num = randi_range(2, ideal_num)
		cell.set_custom_number(ideal_num)
		cell.add_treasure(-1) # just allow this one to be collected "whenever"; easiest solve
		if cell.has_seen_only_one_machine():
			cell.set_machine_filter(cell.get_machine_indices().front())
