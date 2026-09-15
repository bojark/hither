extends Tile
class_name ForestTile

func _init():
	super("forest")
	
	visibility = TileEnums.Visibility.HIGH
	outlook = TileEnums.Outlook.CLOSED
