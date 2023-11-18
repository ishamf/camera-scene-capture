extends Control

@export var player: Player = null

@onready var info_text = %InfoText

var is_touchscreen_available = DisplayServer.is_touchscreen_available()


# Called when the node enters the scene tree for the first time.
func _ready():
	update_input_states(false)



func update_input_states(target: bool):
	if not target:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		player.mouse_captured = false

		$TouchInput.visible = is_touchscreen_available
		info_text.text = "Press M to use mouse and keyboard"

		$GamepadPanel.visible = true
		$MnKPanel.visible = false

	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		player.mouse_captured = true

		$TouchInput.visible = false

		$GamepadPanel.visible = false
		$MnKPanel.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("restart_game"):
		if player.mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			player.mouse_captured = false
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("toggle_mouse_controls"):
		update_input_states(not player.mouse_captured)

	info_text.text = (
			"\n"
			. join(
				[
					"M to release mouse",
					"C to capture, V to apply",
					"Space to jump, Z to reset position",
					(
						"Items in field of view: %s"
						% player.capture_field.get_overlapping_bodies().size()
					),
					"Captured items: %s" % player.captured_objects_data.size(),
				]
			)
		)


func _on_enable_mouse_pressed():
	update_input_states(true)
