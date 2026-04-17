extends Node2D
class_name Main

var generator : PuzzleGenerator

func _ready() -> void:
	generator = PuzzleGenerator.new()
	generator.generate()
	
	print(generator.solution)
