extends "res://core/entity/entity.gd"

@export var damage_amount: float = 30.0

func _ready() -> void:
	super._ready()
	id = "passive-entity:bomb"
	max_health = 30
	health = max_health
	animations = {
		"default": "default",
	}
	var area := $Area2D as Area2D
	if area != null:
		area.collision_mask = PhysicsLayers.MASK_EXPLOSION
	play_animation("default")

func _on_animated_sprite_2d_animation_finished() -> void:
	_apply_explosion_damage()
	die()
	queue_free()

func _apply_explosion_damage() -> void:
	var area := $Area2D as Area2D
	if area == null:
		return
	var seen: Dictionary = {}
	for body in area.get_overlapping_bodies():
		_try_damage_body(body, seen)
	for area_node in area.get_overlapping_areas():
		var parent := area_node.get_parent()
		if parent != null:
			_try_damage_body(parent, seen)

func _try_damage_body(body: Node, seen: Dictionary) -> void:
	if body == null or seen.has(body.get_instance_id()):
		return
	if body is Player:
		seen[body.get_instance_id()] = true
		DamageAuthority.apply_damage(body as Player, damage_amount, "bomb")
		return
	if body is BaseEntity:
		var entity := body as BaseEntity
		if not entity.can_be_destroyed or entity.health <= 0:
			return
		seen[body.get_instance_id()] = true
		DamageAuthority.apply_damage(entity, damage_amount, "bomb")
