class_name PickupIcons
extends RefCounted

## Общие иконки для ResourceNode в мире и PickupItem в инвентаре.

const ICONS := preload("res://assets/icons/32x32.png")
const MUSHROOM_SHEET := preload("res://assets/world/static/mushroom.png")
const LOG_TEX := preload("res://assets/drop_item/log.png")

static var _cache: Dictionary = {}


static func get_texture(item_id: String) -> Texture2D:
	if item_id.is_empty():
		return null
	if _cache.has(item_id):
		return _cache[item_id]
	var tex: Texture2D = null
	match item_id:
		"item:forest_berry":
			tex = _atlas(ICONS, Rect2(96, 864, 32, 32))
		"item:shadow_grass":
			tex = _atlas(ICONS, Rect2(160, 1920, 32, 32))
		"item:oak_root":
			tex = _atlas(ICONS, Rect2(384, 480, 32, 32))
		"item:elf_tear":
			tex = _atlas(ICONS, Rect2(64, 480, 32, 32))
		"item:mushroom":
			tex = _atlas(MUSHROOM_SHEET, Rect2(0, 0, 32, 32))
		"item:log":
			tex = LOG_TEX
	if tex != null:
		_cache[item_id] = tex
	return tex


static func apply_to_animated_sprite(sprite: AnimatedSprite2D, item_id: String) -> void:
	if sprite == null or item_id.is_empty():
		return
	var tex := get_texture(item_id)
	if tex == null:
		return
	var frames := SpriteFrames.new()
	frames.add_frame("default", tex)
	sprite.sprite_frames = frames
	sprite.play("default")


static func apply_to_item(item: BaseEntity, item_id: String = "") -> void:
	if item == null or item.texture != null:
		return
	var id := item_id if not item_id.is_empty() else str(item.id)
	var tex := get_texture(id)
	if tex != null:
		item.texture = tex


static func _atlas(atlas: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = atlas
	atlas_tex.region = region
	return atlas_tex
