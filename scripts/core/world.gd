extends RefCounted
class_name World

const START_COORD: Vector2i = Vector2i(0, 0)

const TILE_Q_SEED_FACTOR: int = 73856093
const TILE_R_SEED_FACTOR: int = 19349663
const SECTOR_SEED_FACTOR: int = 83492791
const WATCH_HILL_SEED_OFFSET: int = 104729

## Seed used to reproduce the same generated world.
var generation_seed: int

## Generated tiles, indexed by their axial coordinates.
var tiles: Dictionary[Vector2i, Tile] = {}


func _init(seed_value: int) -> void:
	generation_seed = seed_value

	print("World created with seed: ", generation_seed)


## Generates the starting tile and its six neighbours.
## Returns them in this order: center, then directions 0–5.
func generate_starting_area() -> Array[Tile]:
	var starting_tiles: Array[Tile] = []
	var start_tile := get_start_tile()

	starting_tiles.append(start_tile)

	for direction_index in range(
		HexCoord.NEIGHBOR_DIRECTIONS.size()
	):
		var neighbour_coord := start_tile.coord.get_neighbor(
			direction_index
		)
		var neighbour := get_tile(neighbour_coord)

		starting_tiles.append(neighbour)

	_place_watch_hill(starting_tiles)

	return starting_tiles


## Returns the starting tile.
func get_start_tile() -> Tile:
	var coord := HexCoord.new(
		START_COORD.x,
		START_COORD.y
	)

	return get_tile(coord)


## Returns the tile at the given coordinates.
## If the tile does not exist yet, it is generated first.
func get_tile(coord: HexCoord) -> Tile:
	var key := Vector2i(coord.q, coord.r)

	if not tiles.has(key):
		tiles[key] = _generate_tile(coord)

	return tiles[key]


func _generate_tile(coord: HexCoord) -> Tile:
	var key := Vector2i(coord.q, coord.r)
	var tile: Tile

	if key == START_COORD:
		tile = ClearingTile.new()
	else:
		var tile_random := RandomNumberGenerator.new()
		tile_random.seed = _get_tile_seed(coord)

		if tile_random.randi_range(0, 1) == 0:
			tile = ForestTile.new()
		else:
			tile = ClearingTile.new()

	tile.coord = coord

	if key == START_COORD:
		tile.get_sector(6).set_feature(BaseCamp.new())
	else:
		_populate_tile(tile)

	return tile

## Generates content for the six outer sectors of a tile.
func _populate_tile(tile: Tile) -> void:
	for sector_index in range(
		HexCoord.NEIGHBOR_DIRECTIONS.size()
	):
		var sector_random := RandomNumberGenerator.new()
		sector_random.seed = _get_sector_seed(
			tile.coord,
			sector_index
		)

		var content_roll := sector_random.randi_range(0, 99)
		var generated_feature: Feature = null

		if content_roll < 70:
			continue
		elif content_roll < 80:
			generated_feature = Feature.new("marsh")
		elif content_roll < 90:
			generated_feature = Encounter.new("gnat_swarm")
		else:
			generated_feature = NiceSpot.new()

		tile.get_sector(sector_index).set_feature(
			generated_feature
		)


## Places the unique Watch Hill in one neighbouring tile.
func _place_watch_hill(
	starting_tiles: Array[Tile]
) -> void:
	var location_random := RandomNumberGenerator.new()
	location_random.seed = (
		generation_seed
		+ WATCH_HILL_SEED_OFFSET
	)

	## Index 0 is the starting tile, so select from 1–6.
	var tile_index := location_random.randi_range(
		1,
		starting_tiles.size() - 1
	)
	var target_tile := starting_tiles[tile_index]
	var target_sector := target_tile.get_sector(6)

	if target_sector.is_empty():
		target_sector.set_feature(WatchHill.new())
	else:
		assert(
			target_sector.feature is WatchHill,
			"Watch Hill sector contains another Feature."
		)


## Produces an individual seed for one coordinate.
func _get_tile_seed(coord: HexCoord) -> int:
	return (
		generation_seed
		+ coord.q * TILE_Q_SEED_FACTOR
		+ coord.r * TILE_R_SEED_FACTOR
	)


## Produces an individual seed for one sector.
func _get_sector_seed(
	coord: HexCoord,
	sector_index: int
) -> int:
	return (
		_get_tile_seed(coord)
		+ (sector_index + 1) * SECTOR_SEED_FACTOR
	)
