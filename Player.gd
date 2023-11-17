extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var captured = false

var mouse_sens = 0.3

var current_angle = 0


func _input(event):
	if event is InputEventMouseButton:
		if not event.is_released():
			return
		if captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			captured = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			captured = true

	elif event is InputEventMouseMotion and captured:
		var changeh = -event.relative.x * mouse_sens
		var changev = -event.relative.y * mouse_sens

		rotate_y(deg_to_rad(changeh))

		if current_angle + changev < 90 and current_angle + changev > -90:
		
			current_angle += changev
			$Camera.rotate_x(deg_to_rad(changev))


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
