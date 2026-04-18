extends Node2D
class_name Main

var generator : PuzzleGenerator

@export var vis : PuzzleVisualizer
@export var cam : PuzzleCamera

func _ready() -> void:
	generator = PuzzleGenerator.new()
	generator.generate()
	
	vis.visualize(generator)
	cam.set_target(vis.bounds)
	
	for cmd in generator.solution:
		cmd = cmd as CommandArrow
		print(cmd.arrow.direction, cmd.arrow.index)
