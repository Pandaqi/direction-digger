extends Node2D
class_name ArrowSimplified

@export var sprite : Sprite2D

func set_direction(dir:PuzzleGrid.Direction) -> void:
	sprite.set_frame(Arrow.direction_to_frame[dir])
