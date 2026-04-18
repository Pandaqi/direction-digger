extends Node2D
class_name Cell

var data : CellData

@export var sprite_terrain : Sprite2D
@export var sprite_treasure : Sprite2D
@export var machine : Machine

func sync_to_data(cd:CellData) -> void:
	data = cd
	data.changed.connect(_on_data_changed)
	_on_data_changed()

func _on_data_changed() -> void:
	sprite_terrain.set_frame(data.get_terrain())
	sprite_treasure.set_visible(data.has_treasure())
	
	machine.hide()
	if data.has_machine():
		machine.show()
		machine.sync_to_data(data.get_machine())
