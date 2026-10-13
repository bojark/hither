extends Node

## Coordinates game startup, world generation, visualization,
## and temporary debug output.

const DEFAULT_WORLD_SEED: int = 12345
const SEED_ARGUMENT_PREFIX: String = "--seed="
const WORLD_SEED_FILE_PATH: String = "res://config/world_seed.txt"

## Active generated world.
var world: World

## Visual representation of the generated world.
@onready var world_view: WorldView = $WorldView


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


## Returns the seed used to generate the world.
##
## A command-line argument has the highest priority. When no argument
## is supplied, the seed is read from WORLD_SEED_FILE_PATH. Invalid,
## empty, or missing values fall back to DEFAULT_WORLD_SEED.
func _get_world_seed() -> int:
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with(
			SEED_ARGUMENT_PREFIX
		):
			continue

		var argument_seed_text := argument.trim_prefix(
			SEED_ARGUMENT_PREFIX
		).strip_edges()

		if argument_seed_text.is_empty():
			break

		if argument_seed_text.is_valid_int():
			return argument_seed_text.to_int()

		push_warning(
			"Invalid command-line world seed '%s'. "
			+ "Using default seed %d."
			% [
				argument_seed_text,
				DEFAULT_WORLD_SEED
			]
		)

		return DEFAULT_WORLD_SEED

	if not FileAccess.file_exists(
		WORLD_SEED_FILE_PATH
	):
		push_warning(
			"World seed file '%s' was not found. "
			+ "Using default seed %d."
			% [
				WORLD_SEED_FILE_PATH,
				DEFAULT_WORLD_SEED
			]
		)

		return DEFAULT_WORLD_SEED

	var file_seed_text := FileAccess.get_file_as_string(
		WORLD_SEED_FILE_PATH
	).strip_edges()

	if file_seed_text.is_empty():
		push_warning(
			"World seed file '%s' is empty. "
			+ "Using default seed %d."
			% [
				WORLD_SEED_FILE_PATH,
				DEFAULT_WORLD_SEED
			]
		)

		return DEFAULT_WORLD_SEED

	if file_seed_text.is_valid_int():
		return file_seed_text.to_int()

	push_warning(
		"Invalid world seed '%s' in file '%s'. "
		+ "Using default seed %d."
		% [
			file_seed_text,
			WORLD_SEED_FILE_PATH,
			DEFAULT_WORLD_SEED
		]
	)

	return DEFAULT_WORLD_SEED


## Creates the world, generates its starting area, and displays it.
func _ready() -> void:
	print(_get_startup_message())

	var world_seed := _get_world_seed()

	world = World.new(world_seed)

	var starting_tiles := world.generate_starting_area()

	world_view.display_tiles(starting_tiles)
	_print_starting_area(starting_tiles)


## Prints the starting tile and its six neighbours.
func _print_starting_area(
	starting_tiles: Array[Tile]
) -> void:
	print("=== Starting area ===")

	for tile_index in range(starting_tiles.size()):
		var tile := starting_tiles[tile_index]

		if tile_index == 0:
			print(
				"Start tile: ",
				tile.coord.q,
				", ",
				tile.coord.r,
				" — ",
				tile.type
			)
		else:
			var direction_index := tile_index - 1

			print(
				"Neighbour ",
				direction_index,
				" (",
				_get_position_name(direction_index),
				"): ",
				tile.coord.q,
				", ",
				tile.coord.r,
				" — ",
				tile.type
			)

		_print_tile_features(tile)


## Prints every generated Feature contained by the supplied Tile.
func _print_tile_features(tile: Tile) -> void:
	var has_features := false

	for sector in tile.sectors:
		if sector.is_empty():
			continue

		has_features = true

		print(
			"    Sector ",
			sector.index,
			" (",
			_get_position_name(sector.index),
			"): ",
			_get_feature_kind(sector.feature),
			" — ",
			sector.feature.type_id
		)

	if not has_features:
		print("    No features")


## Returns a temporary readable category for a Feature.
func _get_feature_kind(feature: Feature) -> String:
	if feature is Encounter:
		return "encounter"

	if feature is Place:
		return "place"

	return "feature"


## Converts a sector localization key into a temporary English name.
func _get_position_name(position_index: int) -> String:
	var position_id := Sector.POSITION_IDS[position_index]

	return position_id.trim_prefix(
		"sector."
	).capitalize()
