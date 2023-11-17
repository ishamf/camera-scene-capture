extends CharacterBody3D

class_name Player

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var capture_field: Area3D = null
@export var captured_objects: Node3D = null

@export var mouse_captured = false

var mouse_sens = 0.3

var current_angle = 0


func _input(event):
	if event is InputEventMouseButton:
		if not event.is_released() or event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_captured = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_captured = true

	elif event is InputEventMouseMotion and mouse_captured:
		var changeh = -event.relative.x * mouse_sens
		var changev = -event.relative.y * mouse_sens

		rotate_y(deg_to_rad(changeh))

		if current_angle + changev < 90 and current_angle + changev > -90:
			current_angle += changev
			$Camera.rotate_x(deg_to_rad(changev))


func _process(_delta):
	if Input.is_action_just_pressed("capture_photo"):
		for child in %CapturedObjects.get_children():
			child.queue_free()

		var bodies = capture_field.get_overlapping_bodies()

		for coll in bodies:
			var body = coll

			while not body.get_scene_file_path():
				body = body.get_parent()

			var new_body = body.duplicate()
			body.add_sibling(new_body)
			new_body.reparent(%CapturedObjects)
			new_body.set_process_mode(PROCESS_MODE_DISABLED)

	if Input.is_action_just_pressed("apply_photo"):
		for child in %CapturedObjects.get_children():
			child.reparent(get_parent())
			child.set_process_mode(PROCESS_MODE_INHERIT)


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("game_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("game_left", "game_right", "game_up", "game_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
