extends Node2D
class_name Cell

var data : CellData

@export var sprite_terrain : Sprite2D
@export var sprite_treasure : Sprite2D
@export var label_treasure : Label
@export var machine : Machine

@export var arrows_container : Node2D
@export var arrow_scene : PackedScene
@export var arrows : Dictionary[PuzzleGrid.Direction, ArrowSimplified] = {}

func _ready() -> void:
	sprite_treasure.material = sprite_treasure.material.duplicate(false)

func sync_to_data(cd:CellData) -> void:
	data = cd
	data.changed.connect(_on_data_changed)
	_on_data_changed()

func _on_data_changed() -> void:
	sprite_terrain.set_frame(data.get_terrain())
	sprite_terrain.z_index = 0
	sprite_terrain.modulate = Color.WHITE
	if data.has_machine_filter():
		sprite_terrain.modulate = MachineData.colors[data.machine_filter]
	
	hide_arrows()
	if data.type == CellData.TerrainType.ARROWS:
		display_arrows()
	
	sprite_treasure.hide()
	label_treasure.hide()
	if data.has_treasure():
		var frame := CellData.TerrainType.GOLD
		if PuzzleSettings.get_value("make_machine_destination_treasure") and data.is_machine_ending_pos:
			frame = CellData.TerrainType.TREASURE
		
		var blend_treasure := data.is_special_terrain()
		var cell_num := data.get_custom_number()
		
		var label_text := str(data.treasure_number + 1)
		var label_show : bool = PuzzleSettings.get_value("show_numbers_on_treasure") and data.treasure_number != -1
		
		# the web just goes on TOP of the treasure below
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
	
