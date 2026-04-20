extends CanvasLayer
class_name UI

@export var turns_indicator_container : Node2D
@export var indicator_scene : PackedScene
@export var indicator_size := 64.0
var indicators : Array[TurnIndicator] = []

func _ready() -> void:
	get_viewport().size_changed.connect(_on_size_changed)
	_on_size_changed()

func _on_size_changed() -> void:
	var vp := get_viewport().get_visible_rect().size
	turns_indicator_container.set_position(Vector2(0.5*vp.x, 16 + 0.5 * indicator_size))

func _on_turns_changed(cur_turn:int, max_turns:int) -> void:
	var cur_indicator_size := indicator_size if max_turns < 15 else (0.5*indicator_size) 
	
	# create more if we're lacking
	while indicators.size() < max_turns:
		var ind : TurnIndicator = indicator_scene.instantiate()
		turns_indicator_container.add_child(ind)
		indicators.append(ind)
	
	# show and reposition them all as needed
	var ind_offset := -0.5 * (max_turns - 1) * cur_indicator_size * Vector2.RIGHT
	for i in range(indicators.size()):
		var ind := indicators[i]
		var should_show := i < max_turns
		if not should_show: 
			ind.hide()
			continue
		
		var is_enabled := i <= (max_turns - 1 - cur_turn)
		ind.show()
		ind.set_size(cur_indicator_size)
		ind.set_enabled(is_enabled)
		ind.set_position(ind_offset + i * cur_indicator_size * Vector2.RIGHT)
