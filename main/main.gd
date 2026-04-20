extends Node2D
class_name Main

var generator : PuzzleGenerator

@export var background : Background
@export var vis : PuzzleVisualizer
@export var cam : PuzzleCamera
@export var ui : CanvasLayer

func _ready() -> void:
	vis.turns_changed.connect(ui._on_turns_changed)
	vis.treasure_collected.connect(background._on_treasure_collected)
	
	generator = PuzzleGenerator.new()
	generator.generate()
	
	vis.visualize(generator)
	cam.set_target(vis.bounds)
