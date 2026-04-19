extends Node2D
class_name TurnIndicator

@export var sprite : Sprite2D
var enabled := false

func set_size(s:float) -> void:
	sprite.set_scale(Vector2.ONE * s / 256.0)

func set_enabled(val:bool) -> void:
	var was_enabled = enabled
	enabled = val
	sprite.set_frame(0 if val else 1)
	sprite.modulate.a = 1.0 if val else 0.33
	
	if was_enabled != enabled:
		PuzzleTween.play_shake_tween(sprite, Vector2(4,8))
