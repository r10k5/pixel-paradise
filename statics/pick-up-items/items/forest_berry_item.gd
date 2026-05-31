extends PickupItem

const ICONS := preload("res://assets/icons/32x32.png")


func _init() -> void:
	_configure("item:forest_berry", "Лесная ягода", 20, 0.2)


func _ready() -> void:
	texture = _make_atlas_texture(Rect2(96, 864, 32, 32))
	super._ready()


func _make_atlas_texture(region: Rect2) -> AtlasTexture:
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = ICONS
	atlas_tex.region = region
	return atlas_tex
