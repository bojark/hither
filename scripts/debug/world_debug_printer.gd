extends RefCounted
class_name WorldDebugPrinter

## Prints temporary debugging information about generated worlds.
##
## This class does not generate or modify the world. It only formats
## existing simulation data for the Godot output console.


## Prints the starting tile and its six neighbours.
static func print_starting_area(
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
static func _print_tile_features(tile: Tile) -> void:
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
static func _get_feature_kind(feature: Feature) -> String:
	if feature is Encounter:
		return "encounter"

	if feature is Place:
		return "place"

	return "feature"


## Converts a sector localization key into a temporary English name.
static func _get_position_name(position_index: int) -> String:
	var position_id := Sector.POSITION_IDS[position_index]

	return position_id.trim_prefix(
		"sector."
	).capitalize()
