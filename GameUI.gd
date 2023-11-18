extends Control

@export var player: Player = null

@onready var info_text = %InfoText
@onready var input_manager = get_node("/root/InputManager")

var is_touchscreen_available = DisplayServer.is_touchscreen_available()


# Called when the node enters the scene tree for the first time.
func _ready():
	update_input_states(input_manager.mouse_captured)
	input_manager.input_mode_changed.connect(_on_input_changed)


func update_input_states(target: bool):
	if not target:
		$TouchInput.visible = is_touchscreen_available

		$GamepadPanel.visible = true
		$MnKPanel.visible = false

	else:
		$TouchInput.visible = false

		$GamepadPanel.visible = false
		$MnKPanel.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	info_text.text = ("\n".join(
		[
			"ESC to release mouse",
			"C to capture, V to apply",
			"Space to jump, Z to reset position",
			"Items in field of view: %s" % player.capture_field.get_overlapping_bodies().size(),
			"Captured items: %s" % player.captured_objects.get_child_count()
		]
	))


func _on_input_changed():
	update_input_states(input_manager.mouse_captured)


func _on_enable_mouse_pressed():
	input_manager.update_input_states(true)
