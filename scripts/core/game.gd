extends Node

const DEFAULT_WORLD_SEED: int = 12345
const SEED_ARGUMENT_PREFIX: String = "--seed="

var world: World


func _get_startup_message() -> String:
	var project_name := str(
		ProjectSettings.get_setting("application/config/name", "Hither")
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


func _get_world_seed() -> int:
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with(
			SEED_ARGUMENT_PREFIX
		):
			continue

		var seed_text := argument.trim_prefix(
			SEED_ARGUMENT_PREFIX
		).strip_edges()

		if seed_text.is_empty():
			return DEFAULT_WORLD_SEED

		if seed_text.is_valid_int():
			return seed_text.to_int()

		push_warning(
			"Invalid world seed '%s'. Using default seed %d."
			% [seed_text, DEFAULT_WORLD_SEED]
		)

		return DEFAULT_WORLD_SEED

	return DEFAULT_WORLD_SEED


func _ready() -> void:
	print(_get_startup_message())

	var world_seed := _get_world_seed()

	world = World.new(world_seed)

	var starting_tiles := world.generate_starting_area()

	_print_starting_area(starting_tiles)

	## Give the editor time to receive the debug output.
	await get_tree().create_timer(0.5).timeout

	get_tree().quit()


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


func _get_feature_kind(feature: Feature) -> String:
	if feature is Encounter:
		return "encounter"

	if feature is Place:
		return "place"

	return "feature"


func _get_position_name(position_index: int) -> String:
	var position_id := Sector.POSITION_IDS[position_index]

	return position_id.trim_prefix(
		"sector."
	).capitalize()
