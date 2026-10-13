extends Node3D
class_name FeatureView

## Visual representation of one Feature on the world map.
##
## FeatureView reads presentation settings from a FeatureVisual resource.
## It does not own or modify the underlying Feature.

const FEATURE_VISUALS: Dictionary[String, FeatureVisual] = {
	"marsh": preload(
		"res://assets/visuals/features/marsh_visual.tres"
	),
	"gnat_swarm": preload(
		"res://assets/visuals/features/gnat_swarm_visual.tres"
	),
	"base_camp": preload(
		"res://assets/visuals/features/base_camp_visual.tres"
	),
	"nice_spot": preload(
		"res://assets/visuals/features/nice_spot_visual.tres"
	),
	"watch_hill": preload(
		"res://assets/visuals/features/watch_hill_visual.tres"
	)
}

## Feature currently represented by this view.
var feature: Feature

@onready var icon: Sprite3D = $Icon


func _ready() -> void:
	if feature != null:
		_apply_feature_visual()


## Assigns the Feature whose state should be displayed.
##
## This method may be called before or after FeatureView enters the scene tree.
func setup(feature_data: Feature) -> void:
	assert(
		feature_data != null,
		"FeatureView cannot display an empty Feature."
	)

	feature = feature_data

	if is_node_ready():
		_apply_feature_visual()


## Applies the visual configuration associated with the current Feature type.
func _apply_feature_visual() -> void:
	assert(
		FEATURE_VISUALS.has(feature.type_id),
		"No FeatureVisual is registered for Feature type '%s'."
		% feature.type_id
	)

	var visual: FeatureVisual = FEATURE_VISUALS[feature.type_id]

	assert(
		visual.texture != null,
		"FeatureVisual for type '%s' has no texture."
		% feature.type_id
	)

	icon.texture = visual.texture
	icon.modulate = visual.tint
	icon.pixel_size = visual.pixel_size
	icon.position.y = visual.vertical_offset
