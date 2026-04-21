extends Node2D
class_name MachinePartDrill

@export var anim_player : AnimationPlayer

func start_anim() -> void:
	anim_player.play("drill")

func stop_anim() -> void:
	anim_player.stop()
