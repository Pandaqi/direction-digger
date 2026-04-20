extends TerrainData
class_name TerrainEnergy

var audio_positive := preload("res://generation/terrains/diamond-clink.ogg")

func generate(gen:PuzzleGenerator) -> void:
	var cells_possible : Array[CellData] = []
	var sol := gen.solution
	for i in range(sol.size()-1, -1, -1):
		var max_turns := gen.max_turns
		var unreachable_if_made_energy := i >= (max_turns - 1)
		if unreachable_if_made_energy: continue
		
		# there's a limit to how many of the options we can add
		# depending on how far away we are from the current available turns
		var max_cells_to_pick := absi(i - (max_turns - 1))
		var cells_picked := 0
		var cells_targeted : Array[CellData] = sol[i].cells_targeted.duplicate(false)
		cells_targeted.shuffle()
		for cell in cells_targeted:
			if not cell.can_receive_special_terrain(): continue
			if gen.forbid_terrains_for_treasure and cell.has_treasure(): continue
			cells_possible.append(cell)
			cells_picked += 1
			if cells_picked >= max_cells_to_pick: break
	
	cells_possible = draw_elements_balanced(cells_possible)
	for elem in cells_possible:
		elem.set_terrain(CellData.TerrainType.ENERGY)
		gen.change_max_turns(-1)

func generate_fake(_gen:PuzzleGenerator, c:CellData) -> bool:
	c.set_terrain(CellData.TerrainType.ENERGY)
	return true

func on_move(cell:CellData, _cmd:CommandMove, cmds:PuzzleCommands) -> void:
	cmds.visualizer.play_audio_custom(cell, audio_positive)
	await cmds.execute_command(CommandEnergy.new())
