extends BaseBody

class_name Player

const STEPS_SOUND := preload("res://sound/steps.wav")
const MIN_STEP_SPEED := 20.0
const JUMP_Z_OFFSET := 1
const TILE_SIZE := 16
const MAP_SCALE := 1.5

@export var jump_tiles: float = 3.5
@export var jump_arc_tiles: float = 1.0
@export var jump_animation_speed_scale: float = 2.5

enum HandToolKind { NONE, AXE, PICKAXE }

const AXE_ITEM_ID := "item:axe"
const PICKAXE_ITEM_ID := "item:pickaxe"
const HOTBAR_SLOT_COUNT := 7

signal hotbar_slot_changed(slot: int)

@onready var inventory: InventoryComponent = $InventoryComponent
@onready var survival: SurvivalStats = $SurvivalStats
var selected_hotbar_slot: int = 0
var is_dead: bool = false
var _steps_player: AudioStreamPlayer
var _was_moving: bool = false
var _is_jumping: bool = false

func _ready() -> void:
	super._ready()
	process_physics_priority = 0
	add_to_group("player")
	collision_layer = PhysicsLayers.PLAYER
	collision_mask = PhysicsLayers.MASK_NORMAL
	animations = {
		"idle_right": "idle_right",
		"idle_up": "idle_up",
		"idle_down": "idle_down",
		"walk_up": "walk_up",
		"walk_right": "walk_right",
		"walk_down": "walk_down",
		"jump_up": "jump_up",
		"jump_right": "jump_right",
		"jump_down": "jump_down",
		"death_right": "death_right",
		"death_up": "death_up",
		"death_down": "death_down",
		"axe_up": "axe_up",
		"axe_down": "axe_down",
		"axe_right": "axe_right",
		"pickaxe_up": "pickaxe_up",
		"pickaxe_down": "pickaxe_down",
		"pickaxe_right": "pickaxe_right",
	}
	_setup_steps_player()
	var hand_tool_hit_area := find_child("HandToolHitArea", true, false) as Area2D
	if hand_tool_hit_area:
		hand_tool_hit_area.collision_mask = PhysicsLayers.MASK_NORMAL

func begin_jump() -> void:
	_is_jumping = true
	collision_mask = PhysicsLayers.MASK_JUMPING
	z_index += JUMP_Z_OFFSET
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	if sprite:
		sprite.speed_scale = jump_animation_speed_scale

func end_jump() -> void:
	_is_jumping = false
	collision_mask = PhysicsLayers.MASK_NORMAL
	z_index -= JUMP_Z_OFFSET
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	if sprite:
		sprite.speed_scale = 1.0

static func jump_state_for(state_name: String) -> String:
	match state_name:
		"idle_up", "walk_up":
			return "jump_up"
		"idle_down", "walk_down":
			return "jump_down"
		_:
			return "jump_side"

func get_selected_hand_tool() -> HandToolKind:
	var slot_item := inventory.get_item(selected_hotbar_slot)
	if slot_item == null or slot_item.is_empty():
		return HandToolKind.NONE
	match slot_item.item.id:
		AXE_ITEM_ID:
			return HandToolKind.AXE
		PICKAXE_ITEM_ID:
			return HandToolKind.PICKAXE
		_:
			return HandToolKind.NONE

func select_hotbar_slot(slot: int) -> void:
	slot = clampi(slot, 0, HOTBAR_SLOT_COUNT - 1)
	if slot == selected_hotbar_slot:
		return
	selected_hotbar_slot = slot
	hotbar_slot_changed.emit(selected_hotbar_slot)

func scroll_hotbar(direction: int) -> void:
	if direction == 0:
		return
	var next := (selected_hotbar_slot + direction) % HOTBAR_SLOT_COUNT
	if next < 0:
		next += HOTBAR_SLOT_COUNT
	select_hotbar_slot(next)

func get_tool_attack_state(state_name: String) -> String:
	var prefix := ""
	match get_selected_hand_tool():
		HandToolKind.AXE:
			prefix = "axe"
		HandToolKind.PICKAXE:
			prefix = "pickaxe"
		_:
			return ""
	match state_name:
		"idle_up", "walk_up":
			return prefix + "_up"
		"idle_down", "walk_down":
			return prefix + "_down"
		_:
			return prefix + "_side"

func get_jump_distance() -> float:
	return jump_tiles * TILE_SIZE * MAP_SCALE

func get_jump_arc_height() -> float:
	return jump_arc_tiles * TILE_SIZE * MAP_SCALE

func get_jump_duration(animation_name: String) -> float:
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	return _animation_duration(sprite, animation_name)

func compute_jump_speed(animation_name: String) -> float:
	var duration := get_jump_duration(animation_name)
	if duration <= 0.0:
		return speed
	return get_jump_distance() / duration

func _animation_duration(sprite: AnimatedSprite2D, animation_name: String) -> float:
	if sprite == null or sprite.sprite_frames == null:
		return 0.0
	var frames := sprite.sprite_frames
	if not frames.has_animation(animation_name):
		return 0.0
	var total := 0.0
	for i in frames.get_frame_count(animation_name):
		total += frames.get_frame_duration(animation_name, i)
	var anim_speed := frames.get_animation_speed(animation_name)
	if anim_speed <= 0.0:
		return 0.0
	var duration := total / anim_speed
	if sprite.speed_scale > 0.0:
		duration /= sprite.speed_scale
	return duration

func take_damage(amount: int) -> void:
	if is_dead:
		return
	DamageAuthority.apply_damage(self, float(amount), "legacy")

func die() -> void:
	if is_dead:
		return
	is_dead = true
	if survival != null:
		survival.save()
	death.emit()

func use() -> void:
	if is_dead:
		return
	if Input.is_action_just_pressed("use"):
		ConsumableEffects.try_use_selected(self)

func compute_walk_speed(direction_active: bool) -> float:
	var mult := 1.0
	if survival != null:
		mult *= survival.get_move_speed_multiplier()
		survival.is_sprinting = false
		if direction_active and Input.is_action_pressed("sprint") and survival.can_sprint():
			survival.is_sprinting = true
			mult *= 1.6
	return speed * mult

func try_begin_jump() -> bool:
	if survival == null:
		return true
	return survival.spend_stamina(SurvivalStats.JUMP_COST)

func has_movement_input() -> bool:
	return (
		Input.is_action_pressed("move_up")
		or Input.is_action_pressed("move_down")
		or absf(Input.get_axis(&"move_left", &"move_right")) > 0.0
	)

func _apply_movement_stop_guard() -> void:
	if _is_jumping:
		return
	if survival != null and survival.is_in_hand_tool:
		return
	if has_movement_input():
		return
	velocity = Vector2.ZERO
	if survival != null:
		survival.is_sprinting = false

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if survival != null:
		if not survival.is_in_hand_tool:
			survival.is_working = false
		if survival.is_sprinting:
			survival.spend_stamina_flat(survival.sprint_stamina_drain_per_sec * delta)
		if inventory.get_total_weight() > survival.heavy_weight_threshold:
			survival.spend_stamina_flat(survival.heavy_stamina_drain_per_sec * delta)
	_apply_movement_stop_guard()
	use()
	move_and_slide()
	_process_steps(delta)

func _setup_steps_player() -> void:
	_steps_player = AudioStreamPlayer.new()
	_steps_player.name = "StepsAudio"
	_steps_player.stream = STEPS_SOUND
	_steps_player.bus = "Master"
	_steps_player.volume_db = -10.0
	add_child(_steps_player)

func _process_steps(delta: float) -> void:
	if _steps_player == null or _is_jumping:
		return
	var _unused := delta
	var is_moving := velocity.length() >= MIN_STEP_SPEED

	if is_moving and not _was_moving:
		_steps_player.pitch_scale = randf_range(0.95, 1.08)
		_steps_player.play()
	elif not is_moving and _was_moving:
		_steps_player.stop()

	_was_moving = is_moving
