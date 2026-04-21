extends Node2D
class_name PuzzleVisualizer

var bounds : Rect2
var generator : PuzzleGenerator
var commands : PuzzleCommands

@export var arrow_scene : PackedScene
var arrows : Array[Arrow]

@export var cell_scene : PackedScene
var cells : Array[Cell]

@export var machine_copies_container : Node2D
@export var machine_scene : PackedScene
var machines : Array[Machine] = []

@export var audio_arrow_click : AudioStreamPlayer2D
@export var audio_arrow_fail : AudioStreamPlayer2D
@export var audio_treasure : AudioStreamPlayer2D
@export var audio_custom : AudioStreamPlayer2D
@export var audio_directions : AudioStreamPlayer

@export var particles_treasure_scene : PackedScene

var turn := -1

var dirs_to_audio : Dictionary[PuzzleGrid.Direction, String] = {
	PuzzleGrid.Direction.LEFT: "direction-left",
	PuzzleGrid.Direction.RIGHT: "direction-right",
	PuzzleGrid.Direction.UP: "direction-up",
	PuzzleGrid.Direction.DOWN: "direction-down",
}

signal turns_changed(cur_turn:int, max_turns:int)
signal treasure_collected(tres_left:int, tres_total:int)
signal loading_finished()

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
	
	# prepare copies for all machines
	for machine_data in generator.machines:
		var machine : Machine = machine_scene.instantiate()
		machine.sync_to_data(machine_data)
		machine_copies_container.add_child(machine)
		machines.append(machine)
		machine.reset()
	
	commands = PuzzleCommands.new()
	commands.prepare_for_play(self)
	commands.set_solution(generator.solution)
	
	commands.do_finished.connect(_on_do_finished)
	commands.undo_finished.connect(_on_undo_finished)
	
	set_turn(0)
	on_treasures_changed()
	loading_finished.emit()

func animate_movement(cmd:CommandMove) -> void:
	var machine := machines[cmd.machine.index]
	var current_cell := cmd.current_cell
	var target_cell := cmd.target_cell
	var current_pos := convert_grid_pos_to_real_pos(current_cell.pos)
	var target_pos := convert_grid_pos_to_real_pos(target_cell.pos)
	
	machine.set_position(current_pos)
	machine.play_digging_animation(target_pos - current_pos)
	
	var dur : float = 0.25 / PuzzleSettings.get_value("animation_speed")
	var tw := get_tree().create_tween()
	tw.tween_property(machine, "position", target_pos, dur)
	tw.tween_callback(machine.stop_digging_animation)
	await tw.finished

func on_treasures_changed(cell:CellData = null) -> void:
	if cell:
		PuzzleAudio.play_audio_nice(audio_treasure)
		var p : ParticlesTreasure = particles_treasure_scene.instantiate()
		p.set_position(convert_grid_pos_to_real_pos(cell.pos))
		add_child(p)
	treasure_collected.emit(generator.count_treasure(), generator.treasure_total)

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

func play_audio_custom(cell:CellData, aus:AudioStream) -> void:
	audio_custom.stream = aus
	audio_custom.set_position(convert_grid_pos_to_real_pos(cell.pos))
	PuzzleAudio.play_audio_nice(audio_custom)

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
	arrow.hovered.connect(_on_arrow_hovered, CONNECT_APPEND_SOURCE_OBJECT)

func get_arrow_from_data(ad:ArrowData) -> Arrow:
	return arrows[ arrows.find_custom(func(a:Arrow): return a.data == ad) ]

func _on_arrow_clicked(a:Arrow) -> void:
	execute_arrow(a.data)

func play_click_sound(volume := 0.0) -> void:
	audio_arrow_click.volume_db = volume
	PuzzleAudio.play_audio_nice(audio_arrow_click)

func _on_arrow_hovered(hovering:bool, a:Arrow) -> void:
	if hovering and a.can_be_clicked(): 
		play_click_sound(-6.0)

func play_direction_audio(ad:ArrowData) -> void:
	var dir_key := dirs_to_audio[ad.direction]
	PuzzleAudio.play_voice(dir_key + ".ogg", audio_directions, "ui/tutorial/directions")

func execute_arrow(ad:ArrowData) -> bool:
	if commands.is_busy(): return false
	
	var cmd := CommandArrow.new(ad)
	if not cmd.is_valid():
		PuzzleAudio.play_audio_nice(audio_arrow_fail)
		return false
	
	play_direction_audio(ad)
	play_click_sound()
	commands.execute_command(cmd)
	return true

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
