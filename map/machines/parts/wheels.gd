extends Node2D
class_name MachinePartWheels

@export var anim_player : AnimationPlayer

func start_anim() -> void:
	anim_player.play("wheel_roll")

func stop_anim() -> void:
	anim_player.stop()
