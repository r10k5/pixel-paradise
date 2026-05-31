extends ResourceNode

const MUSHROOM_SHEET := preload("res://assets/world/static/mushroom.png")


func _ready() -> void:
	resource_id = "mushroom"
	item_id = "item:mushroom"
	respawn_seconds = 180.0
	var atlas1 := AtlasTexture.new()
	atlas1.atlas = MUSHROOM_SHEET
	atlas1.region = Rect2(0, 0, 32, 32)
	var frames := SpriteFrames.new()
	frames.add_frame("default", atlas1)
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	sprite.sprite_frames = frames
	sprite.play("default")
	super._ready()
