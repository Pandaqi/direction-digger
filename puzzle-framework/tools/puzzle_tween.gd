class_name PuzzleTween

static var feedback_scene := preload("res://puzzle-framework/effects/feedback/feedback.tscn")

static func play_popup_tween(obj:Node2D, dur_bounds := Vector2(0.2, 0.6)) -> Tween:
	var tw := obj.get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	var dur := randf_range(dur_bounds.x, dur_bounds.y)
	obj.set_scale(Vector2.ZERO)
	tw.tween_property(obj, "scale", Vector2.ONE, dur)
	return tw

static func play_popdown_tween(obj:Node2D, dur_bounds := Vector2(0.2, 0.6)) -> Tween:
	var tw := obj.get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	var dur := randf_range(dur_bounds.x, dur_bounds.y)
	tw.tween_property(obj, "scale", Vector2.ZERO, dur)
	return tw

static func play_resize_tween(obj:Node2D, scale:Vector2, dur_bounds := Vector2(0.2, 0.5)) -> Tween:
	var tw := obj.get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	var dur := randf_range(dur_bounds.x, dur_bounds.y)
	tw.tween_property(obj, "scale", scale, dur)
	return tw

static func play_wiggle_tween(obj:Node2D, amp_bounds := Vector2(0.02, 0.04)) -> Tween:
	var tw := obj.get_tree().create_tween()
	var dur := randf_range(0.1, 0.25)
	var amplitude := randf_range(amp_bounds.x, amp_bounds.y) * PI
	tw.tween_property(obj, "rotation", -amplitude, 0.25*dur)
	tw.tween_property(obj, "rotation", amplitude, 0.5*dur)
	tw.tween_property(obj, "rotation", 0, 0.25*dur)
	return tw

static func play_shake_tween(obj:Node2D, offset_bounds := Vector2(16, 32)) -> Tween:
	var tw := obj.get_tree().create_tween()
	var dur := randf_range(0.1, 0.25)
	var offset := Vector2.RIGHT * randf_range(offset_bounds.x, offset_bounds.y)
	var cur_pos := obj.position
	tw.tween_property(obj, "position", cur_pos - offset, 0.25*dur)
	tw.tween_property(obj, "position", cur_pos + 0.5*offset, 0.5*dur)
	tw.tween_property(obj, "position", cur_pos, 0.25*dur)
	return tw

static func play_jump_tween(obj:Node2D, jump_height_bounds := Vector2(16, 32)) -> Tween:
	var tw := obj.get_tree().create_tween().set_ease(Tween.EASE_OUT)
	var dur := randf_range(0.1, 0.25)
	var height := randf_range(jump_height_bounds.x, jump_height_bounds.y)
	var cur_pos := obj.position
	var cur_scale := obj.scale
	tw.tween_property(obj, "scale", cur_scale * Vector2(1.2, 0.8), 0.1*dur)
	tw.tween_property(obj, "scale", cur_scale * Vector2(0.8, 1.2), 0.5*dur)
	tw.parallel().tween_property(obj, "position", cur_pos + Vector2.UP * height, 0.5*dur)
	tw.tween_property(obj, "position", cur_pos, 0.5*dur)
	tw.parallel().tween_property(obj, "scale", cur_scale * Vector2(1.2, 0.8), 0.5*dur)
	tw.tween_property(obj, "scale", cur_scale, 0.1*dur)
	return tw

static func play_focus_grab_tween(obj:Node2D) -> Tween:
	var tw_wiggle := obj.get_tree().create_tween()
	var dur := randf_range(0.05, 0.15)
	var amplitude = randf_range(0.05, 0.1) * PI
	tw_wiggle.tween_property(obj, "rotation", -amplitude, dur)
	tw_wiggle.tween_property(obj, "rotation", amplitude, 2*dur)
	tw_wiggle.tween_property(obj, "rotation", -amplitude, 2*dur)
	tw_wiggle.tween_property(obj, "rotation", amplitude, 2*dur)
	tw_wiggle.tween_property(obj, "rotation", -amplitude, 2*dur)
	tw_wiggle.tween_property(obj, "rotation", amplitude, 2*dur)
	tw_wiggle.tween_property(obj, "rotation", -amplitude, 2*dur)
	tw_wiggle.tween_property(obj, "rotation", amplitude, 2*dur)
	tw_wiggle.tween_property(obj, "rotation", 0, dur)
	
	var tw := obj.get_tree().create_tween()
	var dur_flash := 0.25
	tw.tween_property(obj, "modulate", Color(3, 3, 3), dur_flash)
	tw.tween_property(obj, "modulate", Color.WHITE, dur_flash)
	tw.tween_property(obj, "modulate", Color(2,2,2), dur_flash)
	tw.tween_property(obj, "modulate", Color.WHITE, dur_flash)
	tw.tween_property(obj, "modulate", Color(1.35, 1.35, 1.35), dur_flash)
	tw.tween_property(obj, "modulate", Color.WHITE, dur_flash)
	return tw

static func play_pointer_tween(obj:Node2D, pos:Vector2) -> Tween:
	obj.show()
	obj.z_index = 1024
	obj.set_position(pos)
	
	var tw := obj.get_tree().create_tween()
	tw.tween_property(obj, "position", pos + Vector2.RIGHT*8.0, 0.5)
	tw.tween_property(obj, "position", pos, 0.5)
	tw.tween_property(obj, "position", pos + Vector2.RIGHT*8.0, 0.5)
	tw.tween_property(obj, "position", pos, 0.5)
	tw.tween_property(obj, "position", pos + Vector2.RIGHT*8.0, 0.5)
	tw.tween_property(obj, "position", pos, 0.5)
	tw.tween_callback(obj.hide)
	return tw


static func give_feedback(container:Node2D, pos := Vector2.ZERO, txt:String = "", tex:Texture2D = null, scl := Vector2.ONE) -> PuzzleFeedback:
	var fb : PuzzleFeedback = feedback_scene.instantiate()
	container.add_child(fb)
	fb.set_position(pos)
	fb.set_size(scl)
	if tex: fb.set_sprite(tex)
	if txt: fb.set_text(txt)
	return fb

static func force_tween_completion(tw:Tween, dur := 10.0) -> void:
	if not tw.is_running(): return
	
	tw.pause()
	tw.custom_step(dur)

# @TODO: this likely won't work; can I make an easy system for remembering properties and resetting as if the tween never happened/started?
# Why the fuck is this not a standard feature of Tweens?
static func force_tween_reset(tw:Tween, dur := 10.0) -> void:
	tw.pause()
	tw.custom_step(-dur)
