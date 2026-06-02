extends CanvasLayer
class_name DyingOverlay

signal surrender_pressed

@onready var backdrop: ColorRect = $Backdrop
@onready var countdown_label: Label = $CenterContainer/VBoxContainer/CountdownLabel
@onready var surrender_button: Button = $CenterContainer/VBoxContainer/SurrenderButton


func _ready() -> void:
	visible = false
	if surrender_button != null:
		surrender_button.pressed.connect(_on_surrender_pressed)


func show_overlay() -> void:
	visible = true


func hide_overlay() -> void:
	visible = false


func set_seconds_left(sec: int) -> void:
	if countdown_label != null:
		countdown_label.text = "Возрождение через: %d" % maxi(0, sec)


func _on_surrender_pressed() -> void:
	surrender_pressed.emit()
