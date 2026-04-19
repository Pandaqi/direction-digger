extends Node2D
class_name PuzzleVisualizer

var bounds : Rect2
var generator : PuzzleGenerator
var commands : PuzzleCommands

@export var arrow_scene : PackedScene
var arrows : Array[Arrow]

@export var cell_scene : PackedScene
var cells : Array[Cell]

var turn := -1

signal turns_changed(cur_turn:int, max_turns:int)

static var cell_size := Vector2(256, 256)

func visualize(gen:PuzzleGenerator) -> void:
	generator = gen
	bounds = Rect2(Vector2(-1,-1)*cell_size, Vector2(gen.grid.size + Vector2i(1,1)) * cell_size)
	
	# visualize arrows
	for loc in generator.arrows_by_location:
		var arrows_at_loc := generator.arrows_by_location[loc]
		for i in range(arrows_at_loc.size()):
			place_arrow(i, loc, arrows_at_loc[i])
	
	# visualize cells
	for cell in generator.grid.get_cells():
		place_cell(cell)
	
	commands = PuzzleCommands.new()
	commands.prepare_for_play(self)
	commands.set_solution(generator.solution)
	
	commands.do_finished.connect(_on_do_finished)
	commands.undo_finished.connect(_on_undo_finished)
	
	set_turn(0)
	PuzzleFramework.start_puzzle()

func refresh_turn() -> void:
	set_turn(commands.count())

func set_turn(t:int) -> void:	
	var max_turns := generator.max_turns
	turn = clampi(t, 0, max_turns)
	turns_changed.emit(turn, max_turns)
	
	var all_treasure_grabbed := generator.count_treasure() <= 0
	var is_game_over := t >= max_turns or all_treasure_grabbed
	if is_game_over:
		PuzzleFramework.finish_puzzle(all_treasure_grabbed)
		return

func _on_do_finished(cmd:PuzzleCommand) -> void:
	if not cmd.starts_new_turn: return
	refresh_turn()

func _on_undo_finished(_cmds:Array[PuzzleCommand]) -> void:
	refresh_turn()

func convert_grid_pos_to_real_pos(pos:Vector2i) -> Vector2:
	return Vector2(pos) * cell_size

func place_cell(cell_data:CellData) -> void:
	var cell : Cell = cell_scene.instantiate()
	cell.set_position(convert_grid_pos_to_real_pos(cell_data.pos))
	cells.append(cell)
	add_child(cell)
	
	cell.sync_to_data(cell_data)

func place_arrow(idx:int, loc:PuzzleGrid.Direction, ad:ArrowData) -> void:
	var arrow : Arrow = arrow_scene.instantiate()
	arrows.append(arrow)
	add_child(arrow)

	var base_pos := Vector2i.ZERO
	if loc == PuzzleGrid.Direction.LEFT: base_pos.x = -1
	if loc == PuzzleGrid.Direction.RIGHT: base_pos.x = generator.grid.size.x
	if loc == PuzzleGrid.Direction.UP: base_pos.y = -1
	if loc == PuzzleGrid.Direction.DOWN: base_pos.y = generator.grid.size.y
	
	var layout_dir := Vector2i.DOWN if PuzzleGrid.is_horizontal(loc) else Vector2i.RIGHT
	var final_pos := Vector2(base_pos + idx * layout_dir) * cell_size
	arrow.set_position(final_pos)
	arrow.sync_to_data(ad)
	
	arrow.clicked.connect(_on_arrow_clicked, CONNECT_APPEND_SOURCE_OBJECT)

func _on_arrow_clicked(a:Arrow) -> void:
	execute_arrow(a.data)

func execute_arrow(ad:ArrowData) -> void:
	if commands.is_busy(): return
	
	var cmd := CommandArrow.new(ad)
	if not cmd.is_valid():
		print("Invalid Turn!") # @TODO: give more feedback about this?
		return
	
	await commands.execute_command(cmd)

func _input(ev:InputEvent) -> void:
	check_for_hotkeys(ev)

func check_for_hotkeys(ev:InputEvent) -> void:
	if not PuzzleSettings.get_value("enable_keyboard_shortcuts"): return
	if generator.count_machines() > 1: return
	
	var keys : Array[String] = ["", "_alt"]
	var arrow : ArrowData = null
	for i in range(2):
		if i >= generator.machines.size(): break
		
		var my_pos := generator.machines[i].cell.pos
		var arrows_relevant := generator.get_all_arrows_acting_on(my_pos)
		var key_ext := keys[i]
		if ev.is_action_released("ui_left" + key_ext):
			arrow = arrows_relevant[2]
		if ev.is_action_released("ui_right" + key_ext):
			arrow = arrows_relevant[3]
		if ev.is_action_released("ui_up" + key_ext):
			arrow = arrows_relevant[0]
		if ev.is_action_released("ui_down" + key_ext):
			arrow = arrows_relevant[1]
	
	if not arrow: return
	
	execute_arrow(arrow)
