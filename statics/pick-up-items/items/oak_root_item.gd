extends PickupItem

const ICONS := preload("res://assets/icons/32x32.png")


func _init() -> void:
	_configure("item:oak_root", "Корень дуба", 10, 0.5)


func _ready() -> void:
	texture = _make_atlas_texture(Rect2(384, 480, 32, 32))
	super._ready()


func _make_atlas_texture(region: Rect2) -> AtlasTexture:
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = ICONS
	atlas_tex.region = region
	return atlas_tex
