extends Node2D
class_name Swiper

var start_pos := Vector2.ZERO
var end_pos := Vector2.ZERO
var swiping := false

@export var min_distance := 32.0
@export var max_distance := INF
@export var mode_tap_in_sequence := false

signal swiped_in_direction(dir:Vector2i)
signal swiped(p1:Vector2, p2:Vector2)
signal swipe_canceled()

func _input(ev:InputEvent) -> void:
	if not (ev is InputEventMouseButton or ev is InputEventScreenTouch): return
	var pos : Vector2 = ev.position
	
	if ev.is_pressed():
		if not mode_tap_in_sequence:
			start_swipe(pos)
		return
	
	if ev.is_released():
		if mode_tap_in_sequence:
			if swiping: end_swipe(pos)
			else: start_swipe(pos)
		else:
			end_swipe(pos)

func start_swipe(pos:Vector2) -> void:
	if swiping: return
	
	start_pos = pos
	swiping = true

func get_direction() -> Vector2:
	return (end_pos - start_pos)

func get_direction_orthogonal() -> Vector2i:
	var dir := get_direction()
	if absf(dir.x) > absf(dir.y):
		if dir.x > 0: return Vector2i.RIGHT
		return Vector2i.LEFT
	
	if dir.y > 0: return Vector2i.DOWN
	return Vector2i.UP

func end_swipe(pos:Vector2) -> void:
	if not swiping: return
	
	end_pos = pos
	swiping = false
	
	var dist := start_pos.distance_to(end_pos)
	if dist < min_distance or dist > max_distance: 
		swipe_canceled.emit()
		return
	
	swiped_in_direction.emit(get_direction_orthogonal())
	swiped.emit(start_pos, end_pos)
