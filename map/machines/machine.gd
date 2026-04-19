extends Node2D
class_name Machine

var data : MachineData

@export var sprite : Sprite2D

func sync_to_data(md:MachineData) -> void:
	data = md
	#data.changed.connect(_on_data_changed)
	_on_data_changed()

func _on_data_changed() -> void:
	#sprite.set_frame(data.index)
	modulate = MachineData.colors[data.index]
