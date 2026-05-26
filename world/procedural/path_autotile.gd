class_name PathAutotile
extends RefCounted

enum Style {
	PLAZA,
	VERTICAL,
	HORIZONTAL,
}

# Маска соседей: N=1, E=2, S=4, W=8 (клетка — PATH).
# Тайлы подобраны под зоны атласа из layout (cols 0–4 / 5–7 / 8–13).

const PLAZA: Array[Vector2i] = [
	Vector2i(2, 10), Vector2i(2, 11), Vector2i(4, 9), Vector2i(4, 10),
	Vector2i(2, 7), Vector2i(1, 9), Vector2i(3, 8), Vector2i(3, 7),
	Vector2i(0, 9), Vector2i(0, 10), Vector2i(4, 8), Vector2i(4, 7),
	Vector2i(0, 8), Vector2i(0, 7), Vector2i(2, 8), Vector2i(2, 9),
]

const VERTICAL: Array[Vector2i] = [
	Vector2i(6, 10), Vector2i(6, 6), Vector2i(7, 9), Vector2i(7, 10),
	Vector2i(6, 12), Vector2i(6, 9), Vector2i(7, 8), Vector2i(7, 7),
	Vector2i(5, 9), Vector2i(5, 10), Vector2i(7, 9), Vector2i(7, 6),
	Vector2i(5, 8), Vector2i(5, 7), Vector2i(6, 8), Vector2i(6, 9),
]

const HORIZONTAL: Array[Vector2i] = [
	Vector2i(11, 7), Vector2i(11, 6), Vector2i(12, 7), Vector2i(13, 7),
	Vector2i(11, 8), Vector2i(10, 7), Vector2i(12, 8), Vector2i(13, 8),
	Vector2i(10, 7), Vector2i(10, 6), Vector2i(12, 7), Vector2i(13, 6),
	Vector2i(9, 7), Vector2i(9, 6), Vector2i(11, 7), Vector2i(11, 7),
]

# Обломки камня рядом с дорогой (rows 10–15, разброс).
const SCATTER_STONE: Array[Vector2i] = [
	Vector2i(8, 11), Vector2i(9, 12), Vector2i(10, 13), Vector2i(11, 14),
	Vector2i(12, 11), Vector2i(13, 12), Vector2i(14, 13), Vector2i(15, 11),
	Vector2i(8, 14), Vector2i(9, 15), Vector2i(14, 15),
]

static func resolve(cell: Vector2i, world_map: WorldMap, style: int) -> Vector2i:
	var mask := _neighbor_mask(cell, world_map)
	match style:
		Style.VERTICAL:
			return VERTICAL[mask]
		Style.HORIZONTAL:
			return HORIZONTAL[mask]
		_:
			return PLAZA[mask]

static func pick_scatter_stone(rng: RandomNumberGenerator) -> Vector2i:
	return SCATTER_STONE[rng.randi_range(0, SCATTER_STONE.size() - 1)]

static func _neighbor_mask(cell: Vector2i, world_map: WorldMap) -> int:
	var mask := 0
	if world_map.is_path(cell + Vector2i(0, -1)):
		mask |= 1
	if world_map.is_path(cell + Vector2i(1, 0)):
		mask |= 2
	if world_map.is_path(cell + Vector2i(0, 1)):
		mask |= 4
	if world_map.is_path(cell + Vector2i(-1, 0)):
		mask |= 8
	return mask
