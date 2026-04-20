extends Node2D
class_name Machine

var data : MachineData

@export var visuals : Node2D
@export var sprite : Sprite2D
@export var anim_player : AnimationPlayer
@export var audio_digging : AudioStreamPlayer2D
@export var particles_digging : CPUParticles2D

func _ready() -> void:
	audio_digging.bus = "Game"
	particles_digging.set_emitting(false)

func reset() -> void:
	visuals.hide()

func sync_to_data(md:MachineData) -> void:
	data = md
	#data.changed.connect(_on_data_changed)
	_on_data_changed()

func _on_data_changed() -> void:
	#sprite.set_frame(data.index)
	visuals.modulate = MachineData.colors[data.index]

func play_digging_animation() -> void:
	visuals.show()
	audio_digging.play()
	anim_player.play("dig")
	
	if not PuzzleSettings.get_value("disable_visual_effects"):
		particles_digging.set_emitting(true)

func stop_digging_animation() -> void:
	particles_digging.set_emitting(false)
	audio_digging.stop()
	anim_player.stop()
	visuals.hide()
	
