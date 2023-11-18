extends Control


func trigger_action(action_name: StringName):
	var event = InputEventAction.new()
	event.action = action_name
	event.pressed = true
	Input.parse_input_event(event)

	var rel_event = InputEventAction.new()
	rel_event.action = action_name
	rel_event.pressed = false
	Input.parse_input_event(rel_event)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_apply_pressed():
	trigger_action("apply_photo")


func _on_capture_pressed():
	trigger_action("capture_photo")


func _on_reset_pos_pressed():
	trigger_action("reset_position")


func _on_reset_scene_pressed():
	trigger_action("restart_game")


func _on_jump_pressed():
	trigger_action("game_jump")
