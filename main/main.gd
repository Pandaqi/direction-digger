extends Node2D
class_name Main

var generator : PuzzleGenerator

@export var background : Background
@export var vis : PuzzleVisualizer
@export var cam : PuzzleCamera
@export var tutorial : PuzzleTutorial
@export var ui : CanvasLayer

func _ready() -> void:
	vis.turns_changed.connect(ui._on_turns_changed)
	vis.treasure_collected.connect(background._on_treasure_collected)
	vis.loading_finished.connect(_on_loading_finished)
	
	generator = PuzzleGenerator.new()
	generator.generate()
	
	vis.visualize(generator)

func _on_loading_finished() -> void:
	var focus_objects : Array[Node2D] = []
	for cmd in generator.solution:
		focus_objects.append( vis.get_arrow_from_data(cmd.arrow) )
	tutorial.set_focus_objects(focus_objects)
	
	cam.set_target(vis.bounds)
	
	PuzzleFramework.start_puzzle()
