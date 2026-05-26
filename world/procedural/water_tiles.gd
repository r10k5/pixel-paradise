class_name WaterTiles
extends RefCounted

enum TileType {
	Center,
	Top,
	Bottom,
	Left,
	Right,
	LeftTopCorner,
	RightTopCorner,
	LeftBottomCorner,
	RightBottomCorner,
	VerticalTopCorner,
	VerticalBottomCorner,
	VerticalCenter,
	HorizontalLeftCorner,
	HorizontalRightCorner,
	HorizontalCenter,
	Puddle,
}

static func get_tile(height_map: Array, x: int, y: int, water_level: float):
	var current_height: float = height_map[y][x]
	if current_height >= water_level:
		return null

	var map_height: int = height_map.size()
	var map_width: int = height_map[y].size()
	var left: bool = x > 0 and float(height_map[y][x - 1]) < water_level
	var right: bool = x < map_width - 1 and float(height_map[y][x + 1]) < water_level
	var top: bool = y > 0 and float(height_map[y - 1][x]) < water_level
	var bottom: bool = y < map_height - 1 and float(height_map[y + 1][x]) < water_level

	if left and right and top and bottom:
		return TileType.Center
	if not left and not right and not top and not bottom:
		return TileType.Puddle
	if bottom and not left and not right and not top:
		return TileType.VerticalTopCorner
	if bottom and top and not left and not right:
		return TileType.VerticalCenter
	if top and not left and not right and not bottom:
		return TileType.VerticalBottomCorner
	if left and not right and not top and not bottom:
		return TileType.HorizontalRightCorner
	if right and not left and not top and not bottom:
		return TileType.HorizontalLeftCorner
	if left and right and not top and not bottom:
		return TileType.HorizontalCenter
	if left and right and bottom:
		return TileType.Top
	if left and right and top:
		return TileType.Bottom
	if right and top and bottom:
		return TileType.Left
	if left and top and bottom:
		return TileType.Right
	if left and top:
		return TileType.RightBottomCorner
	if right and top:
		return TileType.LeftBottomCorner
	if left and bottom:
		return TileType.RightTopCorner
	if right and bottom:
		return TileType.LeftTopCorner
	if left and right or top and bottom:
		return TileType.Center
	return TileType.Center

static func get_tile_from_world_map(world_map: WorldMap, tile: Vector2i, water_level: float):
	if world_map.height_at(tile) >= water_level:
		return null

	var left: bool = world_map.height_at(tile + Vector2i(-1, 0)) < water_level
	var right: bool = world_map.height_at(tile + Vector2i(1, 0)) < water_level
	var top: bool = world_map.height_at(tile + Vector2i(0, -1)) < water_level
	var bottom: bool = world_map.height_at(tile + Vector2i(0, 1)) < water_level

	if left and right and top and bottom:
		return TileType.Center
	if not left and not right and not top and not bottom:
		return TileType.Puddle
	if bottom and not left and not right and not top:
		return TileType.VerticalTopCorner
	if bottom and top and not left and not right:
		return TileType.VerticalCenter
	if top and not left and not right and not bottom:
		return TileType.VerticalBottomCorner
	if left and not right and not top and not bottom:
		return TileType.HorizontalRightCorner
	if right and not left and not top and not bottom:
		return TileType.HorizontalLeftCorner
	if left and right and not top and not bottom:
		return TileType.HorizontalCenter
	if left and right and bottom:
		return TileType.Top
	if left and right and top:
		return TileType.Bottom
	if right and top and bottom:
		return TileType.Left
	if left and top and bottom:
		return TileType.Right
	if left and top:
		return TileType.RightBottomCorner
	if right and top:
		return TileType.LeftBottomCorner
	if left and bottom:
		return TileType.RightTopCorner
	if right and bottom:
		return TileType.LeftTopCorner
	if left and right or top and bottom:
		return TileType.Center
	return TileType.Center

static func tile_type_to_atlas(tile_type: TileType) -> Vector2i:
	match tile_type:
		TileType.Center:
			return Vector2i(10, 1)
		TileType.Left:
			return Vector2i(6, 6)
		TileType.Top:
			return Vector2i(7, 8)
		TileType.Right:
			return Vector2i(10, 6)
		TileType.Bottom:
			return Vector2i(7, 12)
		TileType.LeftTopCorner:
			return Vector2i(6, 5)
		TileType.RightTopCorner:
			return Vector2i(10, 5)
		TileType.LeftBottomCorner:
			return Vector2i(6, 7)
		TileType.RightBottomCorner:
			return Vector2i(10, 7)
		TileType.VerticalTopCorner:
			return Vector2i(5, 8)
		TileType.VerticalBottomCorner:
			return Vector2i(5, 10)
		TileType.VerticalCenter:
			return Vector2i(5, 9)
		TileType.HorizontalLeftCorner:
			return Vector2i(3, 11)
		TileType.HorizontalRightCorner:
			return Vector2i(5, 11)
		TileType.HorizontalCenter:
			return Vector2i(4, 11)
		TileType.Puddle:
			return Vector2i(4, 13)
	return Vector2i(10, 1)
