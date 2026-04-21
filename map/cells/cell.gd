extends Node2D
class_name Cell

var data : CellData

@export var sprite_base : Sprite2D
@export var sprite_terrain : Sprite2D
@export var sprite_treasure : Sprite2D
@export var sprite_treasure_shine : Sprite2D
@export var label_treasure : Label
@export var machine : Machine

@export var arrows_container : Node2D
@export var arrow_scene : PackedScene
@export var arrows : Dictionary[PuzzleGrid.Direction, ArrowSimplified] = {}

var old_terrain := CellData.TerrainType.NONE
var tween_active : Tween

func _ready() -> void:
	sprite_treasure.material = sprite_treasure.material.duplicate(false)
	sprite_terrain.material = sprite_terrain.material.duplicate(false)

func sync_to_data(cd:CellData) -> void:
	data = cd
	data.changed.connect(_on_data_changed)
	_on_data_changed()

func _on_data_changed() -> void:
	var new_terrain := data.get_terrain()
	sprite_terrain.z_index = 0
	sprite_terrain.modulate = Color.WHITE
	if data.has_machine_filter() and data.is_special_terrain():
		sprite_terrain.modulate = MachineData.colors[data.machine_filter]
	
	if old_terrain != new_terrain:
		play_terrain_dissolve(old_terrain, new_terrain)
		old_terrain = data.get_terrain()
	
	hide_arrows()
	if data.type == CellData.TerrainType.ARROWS:
		display_arrows()
	
	sprite_treasure.hide()
	label_treasure.hide()
	if data.has_treasure():
		var frame := CellData.TerrainType.GOLD
		var display_shine := true
		if PuzzleSettings.get_value("make_machine_destination_treasure") and data.is_machine_ending_pos:
			frame = CellData.TerrainType.TREASURE
			display_shine = false
		
		if PuzzleSettings.get_value("disable_visual_effects"):
			display_shine = false
		
		var blend_treasure := data.is_special_terrain()
		var cell_num := data.get_custom_number()
		
		sprite_treasure_shine.set_visible(display_shine)
		
		var label_text := str(data.treasure_number + 1)
		var label_show : bool = PuzzleSettings.get_value("show_numbers_on_treasure") and data.treasure_number != -1
		
		# @EXCEPTION: the web just goes on TOP of the treasure below
		sprite_terrain.modulate.a = 1.0
		if data.type == CellData.TerrainType.WEB:
			sprite_terrain.z_index = 8
			sprite_terrain.modulate.a = 0.5 if (cell_num == 1) else 1.0
			label_show = true
			label_text = str(cell_num)
		
		label_treasure.z_index = 16
		label_treasure.set_visible(label_show)
		label_treasure.set_text(label_text)
		
		sprite_treasure.show()
		sprite_treasure.set_frame(frame)
		sprite_treasure.material.set_shader_parameter("blend_enabled", blend_treasure)
	
	machine.hide()
	if data.has_machine():
		machine.show()
		machine.sync_to_data(data.get_machine())

func hide_arrows() -> void:
	arrows_container.hide()

func display_arrows() -> void:
	# create them if not already present
	var no_arrows_yet := arrows.is_empty()
	var arrow_offset := 78.0
	if no_arrows_yet:
		var dirs := PuzzleGrid.get_orthogonal_directions()
		for dir in dirs:
			var arrow : ArrowSimplified = arrow_scene.instantiate()
			arrow.set_direction(dir)
			arrow.set_position(PuzzleGrid.convert_direction_to_vector(dir) * arrow_offset)
			arrows[dir] = arrow
			arrows_container.add_child(arrow)
	
	# hide all first, then make sure only the right ones appear
	arrows_container.show()
	for dir in arrows:
		arrows[dir].hide()
	
	for arrow in data.get_custom_arrows():
		arrows[arrow.location].show()

func play_terrain_dissolve(start_terrain:CellData.TerrainType, target_terrain:CellData.TerrainType) -> void:
	var instant_update := [start_terrain, target_terrain].has(CellData.TerrainType.NONE)
	if instant_update: 
		sprite_terrain.set_frame(target_terrain)
		return
	
	sprite_base.set_frame(target_terrain)
	sprite_base.show()
	sprite_base.z_index = sprite_terrain.z_index - 1
	
	sprite_terrain.set_frame(start_terrain)
	sprite_terrain.show()
	
	if tween_active and tween_active.is_running():
		PuzzleTween.force_tween_completion(tween_active)
	
	var dur : float = 0.75 / PuzzleSettings.get_value("animation_speed")
	var tw := get_tree().create_tween()
	tw.tween_method(
	  func(value:float): sprite_terrain.material.set_shader_parameter("factor", value),  
	  0.0,  # Start value
	  1.0,  # End value
	  dur     # Duration
	)
	tween_active = tw
	await tw.finished
	
	# make the change definitive
	sprite_base.hide()
	sprite_terrain.set_frame(target_terrain)
	sprite_terrain.material.set_shader_parameter("factor", 0.0)
