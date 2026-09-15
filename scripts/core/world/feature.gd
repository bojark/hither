extends RefCounted
class_name Feature

## Stable internal identifier of the feature type.
## Examples: "marsh", "gnat_swarm", "watch_hill".
var type_id: String

## Localization key used to obtain the feature's displayed name.
var name_id: String


func _init(feature_type_id: String) -> void:
	assert(
		not feature_type_id.is_empty(),
		"Feature type ID must not be empty."
	)

	type_id = feature_type_id
	name_id = "feature.%s.name" % type_id
