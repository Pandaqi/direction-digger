extends Node2D
class_name PuzzleFeedback

@export var container : Node2D
@export var sprite : Sprite2D
@export var label : RichTextLabel
@export var anim_player : AnimationPlayer

func _ready() -> void:
	sprite.hide()
	label.hide()
	z_index = 512
	anim_player.play("feedback_disappear")

func set_size(s := Vector2.ONE) -> void:
	container.set_scale(s)

func set_text(txt:String) -> void:
	label.show()
	label.set_text(txt)

func set_sprite(tex:Texture2D) -> void:
	sprite.show()
	sprite.texture = tex
