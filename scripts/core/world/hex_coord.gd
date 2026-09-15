## Axial coordinates of a hexagonal tile.
extends RefCounted
class_name HexCoord

## Directions correspond to outer sector indices:
## 0 — north, 1 — north-east, 2 — south-east,
## 3 — south, 4 — south-west, 5 — north-west.
const NEIGHBOR_DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0)
]

var q: int
var r: int


func _init(q_value: int, r_value: int) -> void:
	q = q_value
	r = r_value


## Returns the coordinates of a neighbouring hex.
func get_neighbor(direction_index: int) -> HexCoord:
	assert(
		direction_index >= 0
		and direction_index < NEIGHBOR_DIRECTIONS.size(),
		"Direction index must be between 0 and %d."
		% (NEIGHBOR_DIRECTIONS.size() - 1)
	)

	var direction := NEIGHBOR_DIRECTIONS[direction_index]

	return HexCoord.new(
		q + direction.x,
		r + direction.y
	)
