extends Node

## Coordinates game startup, world generation, visualization,
## and application-level interface requests.

## Active generated world.
var world: World

## Visual representation of the generated world.
@onready var world_view: WorldView = $WorldView

## Application-level user interface.
@onready var game_interface: GameInterface = $Interface


## Connects the interface and generates the initial world.
func _ready() -> void:
	game_interface.world_generation_requested.connect(
		_on_world_generation_requested
	)
	game_interface.exit_requested.connect(
		_on_exit_requested
	)

	print(_get_startup_message())

	var world_seed := WorldSeedProvider.get_startup_seed()

	game_interface.set_world_seed(world_seed)
	_generate_world(world_seed)


## Creates a new world and replaces the displayed starting area.
func _generate_world(world_seed: int) -> void:
	world = World.new(world_seed)

	var starting_tiles := world.generate_starting_area()

	world_view.display_tiles(starting_tiles)
	WorldDebugPrinter.print_starting_area(starting_tiles)


## Handles a world-generation request from the interface.
func _on_world_generation_requested(
	seed_text: String
) -> void:
	if seed_text.is_empty():
		var default_seed := WorldSeedProvider.DEFAULT_SEED

		game_interface.set_world_seed(default_seed)
		_generate_world(default_seed)
		return

	if not seed_text.is_valid_int():
		push_warning(
			"Invalid interface world seed '%s'. "
			+ "The current world was not changed."
			% seed_text
		)

		game_interface.show_seed_error()
		return

	var world_seed := seed_text.to_int()

	game_interface.set_world_seed(world_seed)
	_generate_world(world_seed)


## Handles an application exit request from the interface.
func _on_exit_requested() -> void:
	get_tree().quit()


## Builds the startup message from the project name and version.
func _get_startup_message() -> String:
	var project_name := str(
		ProjectSettings.get_setting(
			"application/config/name",
			"Hither"
		)
	)
	var project_version := str(
		ProjectSettings.get_setting(
			"application/config/version",
			"unknown"
		)
	)

	return "=== %s v%s started ===" % [
		project_name,
		project_version
	]
