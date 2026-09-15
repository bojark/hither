extends Tile
class_name ClearingTile


func _init() -> void:
	super("clearing")

	visibility = TileEnums.Visibility.VISIBLE
	outlook = TileEnums.Outlook.OPEN
