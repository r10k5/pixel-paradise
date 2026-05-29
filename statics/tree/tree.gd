extends BaseEntity

const LOG = preload("res://statics/drop/log.tscn")

const SHAKE_STRENGTH := 3.0
const SHAKE_STEP := 0.04

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hp_bar: ProgressBar = $HealthBar/ProgressBar

var _sprite_base_offset: Vector2
var _shake_tween: Tween

func _ready() -> void:
	add_to_group("choppable")
	depth_sort_feet_bias = 52.0
	fade_when_player_behind = true
	super._ready()
	id = "passive-entity:tree"
	max_health = 10
	health = max_health
	drops = [LOG.instantiate()]
	animations = {}
	_sprite_base_offset = _sprite.position
	_setup_hp_bar()
	health_changed.connect(_on_health_changed)
	_on_health_changed(health)

func _setup_hp_bar() -> void:
	_hp_bar.max_value = max_health
	_hp_bar.value = health
	_hp_bar.step = 1.0

func _on_health_changed(value: int) -> void:
	_hp_bar.value = value

func take_damage(amount: int) -> void:
	if not can_be_destroyed:
		return
	super.take_damage(amount)
	_play_shake()

func _play_shake() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_sprite.position = _sprite_base_offset
	_shake_tween = create_tween()
	for _i in 4:
		var offset := Vector2(
			randf_range(-SHAKE_STRENGTH, SHAKE_STRENGTH),
			randf_range(-SHAKE_STRENGTH, SHAKE_STRENGTH)
		)
		_shake_tween.tween_property(_sprite, "position", _sprite_base_offset + offset, SHAKE_STEP)
	_shake_tween.tween_property(_sprite, "position", _sprite_base_offset, SHAKE_STEP)

func die() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	super.die()
	queue_free()

func interact() -> void:
	super.interact()
	take_damage(5)
