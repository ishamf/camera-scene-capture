extends Node

@export var mouse_captured = false

signal input_mode_changed

func update_input_states(target: bool):
	var changed = mouse_captured != target
	if not target:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		mouse_captured = false

	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_captured = true

	if changed: input_mode_changed.emit()



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("restart_game"):
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("disable_mouse_controls"):
		update_input_states(false)
