extends Resource
class_name FeatureVisual

## Visual configuration of one Feature type on the world map.
##
## Stores presentation data separately from Feature simulation data.

## Texture displayed by FeatureView.
@export var texture: Texture2D

## Color multiplied with the texture.
@export var tint: Color = Color.WHITE

## Size of one texture pixel in three-dimensional world units.
@export_range(0.0001, 0.02, 0.0001)
var pixel_size: float = 0.004

## Vertical position of the sprite relative to its sector anchor.
@export var vertical_offset: float = 0.25
