extends RefCounted
class_name Tile

const SECTOR_COUNT: int = 7

## Stable internal identifier of the terrain type.
var type: String

## Axial position of this tile in the world.
var coord: HexCoord

var visibility: TileEnums.Visibility
var outlook: TileEnums.Outlook

## Seven internal sectors numbered from 0 to 6.
var sectors: Array[Sector] = []


func _init(type_id: String) -> void:
	assert(
		not type_id.is_empty(),
		"Tile type ID must not be empty."
	)

	type = type_id

	for sector_index in range(SECTOR_COUNT):
		sectors.append(Sector.new(sector_index))


## Returns a sector by its local index.
func get_sector(sector_index: int) -> Sector:
	assert(
		sector_index >= 0
		and sector_index < SECTOR_COUNT,
		"Sector index must be between 0 and %d."
		% (SECTOR_COUNT - 1)
	)

	return sectors[sector_index]
