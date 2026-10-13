extends Node3D
class_name WorldView

## Displays generated Tiles as a three-dimensional hexagonal world map.
##
## WorldView does not generate or modify the world. It receives existing
## Tile objects and creates one HexView for each of them.

const HEX_VIEW_SCENE: PackedScene = preload(
	"res://scenes/world/hex_view.tscn"
)

## Horizontal distance between the centers of adjacent flat-top hexes.
const HEX_X_SPACING: float = 1.5

## Vertical distance between the centers of adjacent flat-top hexes.
const HEX_Z_SPACING: float = 1.7320508

@onready var tiles_container: Node3D = $Tiles


## Replaces the currently displayed map with the supplied Tiles.
func display_tiles(tiles: Array[Tile]) -> void:
	_clear_tiles()

	for tile in tiles:
		var hex_view := (
			HEX_VIEW_SCENE.instantiate() as HexView
		)

		assert(
			hex_view != null,
			"HEX_VIEW_SCENE must create a HexView."
		)

		hex_view.position = _hex_to_world(tile.coord)
		hex_view.setup(tile)

		tiles_container.add_child(hex_view)


## Converts axial hex coordinates to a position on the XZ world plane.
func _hex_to_world(coord: HexCoord) -> Vector3:
	return Vector3(
		coord.q * HEX_X_SPACING,
		0.0,
		(coord.r + coord.q * 0.5) * HEX_Z_SPACING
	)


## Removes all previously created HexView instances.
func _clear_tiles() -> void:
	for child in tiles_container.get_children():
		child.queue_free()
