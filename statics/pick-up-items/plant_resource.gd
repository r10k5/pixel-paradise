class_name PlantResource
extends ResourceNode

const ICONS := preload("res://assets/icons/32x32.png")


func _apply_atlas_icon(region: Rect2) -> void:
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = ICONS
	atlas_tex.region = region
	var frames := SpriteFrames.new()
	frames.add_frame("default", atlas_tex)
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	sprite.sprite_frames = frames
	sprite.play("default")
