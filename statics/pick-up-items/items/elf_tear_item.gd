extends PickupItem

const ICONS := preload("res://assets/icons/32x32.png")


func _init() -> void:
	_configure("item:elf_tear", "Слеза эльфа", 5, 0.1)


func _ready() -> void:
	texture = _make_atlas_texture(Rect2(64, 480, 32, 32))
	super._ready()


func _make_atlas_texture(region: Rect2) -> AtlasTexture:
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = ICONS
	atlas_tex.region = region
	return atlas_tex
