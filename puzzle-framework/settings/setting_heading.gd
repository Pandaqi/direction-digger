extends PuzzleSetting
class_name PuzzleSettingHeading

@export var alignment : HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER

func create_nodes(container:Control) -> void:
	var subcont := MarginContainer.new()
	subcont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subcont.add_theme_constant_override("margin_top", 32)
	subcont.add_theme_constant_override("margin_bottom", 4)
	container.add_child(subcont)
	
	var header := create_header_node()
	header.horizontal_alignment = alignment
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_font_override("font", PuzzleFramework.font_heading)
	subcont.add_child(header)
