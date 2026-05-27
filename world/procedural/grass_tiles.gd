class_name GrassTiles
extends RefCounted

# TX Tileset Grass — сетка 16×16, тайл 16 px.
# Верх (строки 0–5): трава; низ: каменные дороги по зонам из layout.

const FLOWER_CHANCE := 0.12

const GRASS_PLAIN: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
	Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0), Vector2i(9, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
	Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(8, 1), Vector2i(9, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
	Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2),
	Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3),
	Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3), Vector2i(9, 3),
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4),
	Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4),
	Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5),
	Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5),
	# Правая часть верхнего ряда — тоже трава без цветов
	Vector2i(10, 4), Vector2i(11, 4), Vector2i(12, 4), Vector2i(13, 4),
	Vector2i(14, 4), Vector2i(15, 4), Vector2i(15, 5),
]

const GRASS_FLOWERS: Array[Vector2i] = [
	Vector2i(10, 0), Vector2i(11, 0), Vector2i(12, 0), Vector2i(13, 0),
	Vector2i(14, 0), Vector2i(15, 0), Vector2i(10, 1), Vector2i(11, 1),
	Vector2i(12, 1), Vector2i(13, 1), Vector2i(14, 1), Vector2i(15, 1),
	Vector2i(10, 2), Vector2i(11, 2), Vector2i(12, 2), Vector2i(13, 2),
	Vector2i(14, 2), Vector2i(15, 2), Vector2i(10, 3), Vector2i(11, 3),
	Vector2i(12, 3), Vector2i(13, 3), Vector2i(14, 3), Vector2i(15, 3),
	Vector2i(9, 4),
]

## Нижние ряды тайлсета — более тёмная трава (лес).
const GRASS_FOREST_DARK: Array[Vector2i] = [
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4),
	Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4),
	Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5),
	Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5),
	Vector2i(10, 4), Vector2i(11, 4), Vector2i(12, 4), Vector2i(13, 4),
	Vector2i(14, 4), Vector2i(15, 4), Vector2i(15, 5),
]

const GRASS_UNDER_WATER: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
]

static func pick_grass(rng: RandomNumberGenerator) -> Vector2i:
	if rng.randf() < FLOWER_CHANCE:
		return GRASS_FLOWERS[rng.randi_range(0, GRASS_FLOWERS.size() - 1)]
	return GRASS_PLAIN[rng.randi_range(0, GRASS_PLAIN.size() - 1)]

static func pick_grass_under_water(rng: RandomNumberGenerator) -> Vector2i:
	return GRASS_UNDER_WATER[rng.randi_range(0, GRASS_UNDER_WATER.size() - 1)]

static func pick_forest_grass(tile: Vector2i) -> Vector2i:
	return GRASS_FOREST_DARK[abs(int(tile.x * 29 + tile.y * 37)) % GRASS_FOREST_DARK.size()]
