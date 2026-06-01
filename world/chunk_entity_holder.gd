class_name ChunkEntityHolder
extends ScreenCullRegion
## Контейнер сущностей чанка под Actors (y_sort) с тем же frustum culling.

var chunk_coords: Vector2i = Vector2i.ZERO


func _ready() -> void:
	child_entered_tree.connect(_on_child_entered)
	for child in get_children():
		_on_child_entered(child)
	super._ready()


func configure(chunk: Vector2i, size_tiles: int, grass_template_root: Node2D) -> void:
	chunk_coords = chunk
	var tile_px := BiomeLayerConfig.tile_pixel_size(grass_template_root)
	position = Vector2(chunk.x * size_tiles, chunk.y * size_tiles) * tile_px
	set_cull_rect(Rect2(Vector2.ZERO, Vector2(size_tiles, size_tiles) * tile_px))


func _on_child_entered(node: Node) -> void:
	if node == _notifier:
		return
	register_content(node)
	if not is_region_on_screen():
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		if disable_process_when_culled and node is Node:
			(node as Node).process_mode = Node.PROCESS_MODE_DISABLED
