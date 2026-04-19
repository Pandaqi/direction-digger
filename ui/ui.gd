extends CanvasLayer
class_name UI

@export var label_turns : Label

func _on_turns_changed(cur_turn:int, max_turns:int) -> void:
	label_turns.set_text(str(cur_turn + 1) + "/" + str(max_turns))
