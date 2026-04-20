extends Node2D
class_name Arrow

var data : ArrowData

@export var sprite : Sprite2D
@export var area : Area2D
@export var label_container : Node2D
@export var label : Label

var prev_number := -1
var hovering := false

static var direction_to_frame : Dictionary[PuzzleGrid.Direction, int] = {
	PuzzleGrid.Direction.RIGHT: 0,
	PuzzleGrid.Direction.DOWN: 1,
	PuzzleGrid.Direction.LEFT: 2,
	PuzzleGrid.Direction.UP: 3,
}

signal clicked()
signal hovered(h:bool)

func _ready() -> void:
	area.input_event.connect(_on_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	clicked.connect(_on_clicked)

func _on_input_event(_vp:Node, ev:InputEvent, _sidx:int) -> void:
	if not (ev is InputEventMouseButton or ev is InputEventScreenTouch): return
	if ev.is_pressed(): return
	if not can_be_clicked(): return
	clicked.emit()

func can_be_clicked() -> bool:
	return is_enabled()

func _on_clicked() -> void:
	animate_change()

func animate_change() -> void:
	set_scale(Vector2.ONE * 1.2)

func _on_mouse_entered() -> void:
	hovering = true
	hovered.emit(true)

func _on_mouse_exited() -> void:
	hovering = false
	hovered.emit(false)

func _physics_process(dt:float) -> void:
	var target_scale := Vector2.ONE if (hovering and is_enabled()) else Vector2(0.8, 0.8)
	set_scale(get_scale().lerp(target_scale, 10*dt))
	
	var target_alpha := 1.0 if is_enabled() else 0.1
	modulate.a = lerpf(modulate.a, target_alpha, 10*dt)

func is_enabled() -> bool:
	return data.is_usable()

func sync_to_data(ad:ArrowData) -> void:
	data = ad
	data.changed.connect(_on_data_changed)
	_on_data_changed()

func _on_data_changed() -> void:
	sprite.set_frame(direction_to_frame[data.direction])
	sprite.modulate = Color.WHITE
	#sprite.modulate = Color.RED if data.is_exhausted() else Color.WHITE
	
	label_container.set_position(PuzzleGrid.convert_direction_to_vector(data.direction) * -1 * 24.0)
	
	label.hide()
	var usages_left := data.get_usages_left()
	if usages_left >= 0:
		label.show()
		label.set_text(str(usages_left))
	if usages_left > prev_number: animate_change()
	prev_number = usages_left
