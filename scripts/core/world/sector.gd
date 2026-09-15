extends RefCounted
class_name Sector

## Stable localization keys for sector positions.
## Array index corresponds to the sector index.
const POSITION_IDS: Array[String] = [
	"sector.north",
	"sector.north_east",
	"sector.south_east",
	"sector.south",
	"sector.south_west",
	"sector.north_west",
	"sector.center"
]

## Local position inside a hex: outer sectors are 0–5,
## while 6 is the central sector.
var index: int

## The feature occupying this sector.
## An empty sector contains null.
var feature: Feature = null


func _init(sector_index: int) -> void:
	assert(
		sector_index >= 0 and sector_index < POSITION_IDS.size(),
		"Sector index must be between 0 and %d." % (POSITION_IDS.size() - 1)
	)

	index = sector_index


## Returns a stable localization key for this sector's position.
func get_position_id() -> String:
	return POSITION_IDS[index]


## Returns true when the sector has no feature.
func is_empty() -> bool:
	return feature == null


## Places a feature into an empty sector.
func set_feature(new_feature: Feature) -> void:
	assert(
		new_feature != null,
		"Cannot place an empty Feature into a Sector."
	)
	assert(
		is_empty(),
		"This Sector already contains a Feature."
	)

	feature = new_feature


## Removes the current feature from the sector.
func clear_feature() -> void:
	feature = null
