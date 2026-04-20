extends CanvasLayer
class_name Background

@export var texture_rect : TextureRect
@export var texture_alpha_bounds := Vector2i(0.5, 1.0)

func _on_treasure_collected(treasure_left:int, total_treasure:int) -> void:
	texture_rect.modulate.a = lerpf(texture_alpha_bounds.x, texture_alpha_bounds.y, 1.0 - treasure_left / float(total_treasure))
