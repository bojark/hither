extends Node

var world: World

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("=== Hither started ===")
	world = World.new()
