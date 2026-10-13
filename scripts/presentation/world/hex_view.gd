extends Node3D
class_name HexView

## Visual representation of one generated Tile on the world map.
##
## HexView does not own or modify simulation data. It reads a Tile,
## selects its terrain material, and displays Features in its sectors.

const TERRAIN_SURFACE_MATERIALS: Dictionary[String, Material] = {
	"clearing": preload(
		"res://assets/materials/terrain/clearing_surface_material.tres"
	),
	"forest": preload(
		"res://assets/materials/terrain/forest_surface_material.tres"
	)
}

const FEATURE_VIEW_SCENE: PackedScene = preload(
	"res://scenes/world/feature_view.tscn"
)

## Tile currently represented by this view.
var tile: Tile

@onready var surface: MeshInstance3D = $Surface
@onready var sector_anchors: Node3D = $SectorAnchors


func _ready() -> void:
	if tile != null:
		_refresh_view()


## Assigns the Tile whose state should be displayed.
##
## This method may be called before or after HexView enters the scene tree.
func setup(tile_data: Tile) -> void:
	assert(
		tile_data != null,
		"HexView cannot display an empty Tile."
	)

	tile = tile_data

	if is_node_ready():
		_refresh_view()


## Refreshes the terrain material and all displayed Features.
func _refresh_view() -> void:
	_apply_tile_material()
	_display_features()


## Selects the surface material associated with the current terrain type.
func _apply_tile_material() -> void:
	assert(
		TERRAIN_SURFACE_MATERIALS.has(tile.type),
		"No surface material is registered for Tile type '%s'."
		% tile.type
	)

	var terrain_material: Material = (
		TERRAIN_SURFACE_MATERIALS[tile.type]
	)

	surface.set_surface_override_material(
		0,
		terrain_material
	)


## Creates a FeatureView for every occupied sector.
func _display_features() -> void:
	_clear_feature_views()

	for sector in tile.sectors:
		if sector.is_empty():
			continue

		var anchor := sector_anchors.get_node_or_null(
			"Sector%d" % sector.index
		) as Marker3D

		assert(
			anchor != null,
			"HexView is missing an anchor for Sector %d."
			% sector.index
		)

		var feature_view := (
			FEATURE_VIEW_SCENE.instantiate() as FeatureView
		)

		assert(
			feature_view != null,
			"FEATURE_VIEW_SCENE must create a FeatureView."
		)

		feature_view.setup(sector.feature)
		anchor.add_child(feature_view)


## Removes previously created FeatureView instances.
func _clear_feature_views() -> void:
	for anchor in sector_anchors.get_children():
		for child in anchor.get_children():
			if child is FeatureView:
				anchor.remove_child(child)
				child.queue_free()
