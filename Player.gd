extends CharacterBody3D

class_name Player

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var capture_field: Area3D = null
@export var captured_objects: Node3D = null

@export var initial_player_position: Node3D = null

@onready var input_manager = get_node("/root/InputManager")

var mouse_sens = 0.3

var current_angle = 0

@export var captured_objects_data = []


func _input(event):
	if event is InputEventMouseMotion and input_manager.mouse_captured:
		var changeh = -event.relative.x * mouse_sens
		var changev = -event.relative.y * mouse_sens

		apply_look(Vector2(changeh, changev))


enum ShapeType {
	CONVEX,
	CONCAVE,
}

enum BodyType {
	RIGID,
	STATIC,
}


func apply_look(vec: Vector2):
	rotate_y(deg_to_rad(vec.x))

	if current_angle + vec.y < 90 and current_angle + vec.y > -90:
		current_angle += vec.y
		$Camera.rotate_x(deg_to_rad(vec.y))


func create_intersected_body(body: Node3D, is_subtract: bool = false):
	var body_mesh: MeshInstance3D = null
	var collision_body: CollisionObject3D = null
	var body_parent = body.get_parent()

	# var shape_type
	var body_type

	var nodes_to_check = [body]
	nodes_to_check.append_array(body.find_children("*", "", true, false))

	for node in nodes_to_check:
		print(node)
		if node is MeshInstance3D:
			body_mesh = node

		elif node is RigidBody3D:
			collision_body = node
			body_type = BodyType.RIGID

		elif node is StaticBody3D:
			collision_body = node
			body_type = BodyType.STATIC

		# elif node is CollisionShape3D:
		# 	if node.shape is ConvexPolygonShape3D:
		# 		shape_type = ShapeType.CONVEX
		# 	elif node.shape is ConcavePolygonShape3D:
		# 		shape_type = ShapeType.CONCAVE
		# 	else:
		# 		print_debug("Unknown shape type.")
		# 		return

	if not body_mesh or not collision_body:
		print_debug("No mesh or collision body found in the captured object.")
		return

	var csg_mesh = CSGMesh3D.new()

	csg_mesh.mesh = body_mesh.mesh.duplicate()

	var combiner = CSGCombiner3D.new()
	var intersector: CSGMesh3D = %CSGIntersector.duplicate()

	intersector.visible = true

	if is_subtract:
		intersector.operation = CSGShape3D.OPERATION_SUBTRACTION

	combiner.add_child(csg_mesh)
	combiner.add_child(intersector)

	body_parent.add_child(combiner)

	combiner.global_transform = body_mesh.global_transform
	intersector.global_transform = %CSGIntersector.global_transform

	combiner._update_shape()

	var mesh_tuple = combiner.get_meshes()

	var new_mesh_transform = mesh_tuple[0]
	var new_generated_mesh: Mesh = mesh_tuple[1].duplicate()

	var new_global_transform = combiner.global_transform * new_mesh_transform

	var is_empty_mesh = new_generated_mesh.get_surface_count() == 0

	if is_empty_mesh:
		print_debug("Empty mesh generated.")
		combiner.queue_free()
		return null

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = new_generated_mesh

	var new_item

	if body_type == BodyType.RIGID:
		var new_body = RigidBody3D.new()
		new_body.add_child(mesh_instance)

		var shape = CollisionShape3D.new()

		new_body.add_child(shape)
		shape.make_convex_from_siblings()

		new_item = new_body

	else:
		var new_body = StaticBody3D.new()
		mesh_instance.add_child(new_body)

		var shape = CollisionShape3D.new()

		new_body.add_child(shape)
		shape.shape = mesh_instance.mesh.create_trimesh_shape()

		new_item = mesh_instance

	combiner.queue_free()

	new_item.set_meta("item_root", true)
	body_parent.add_child(new_item)
	new_item.global_transform = new_global_transform

	print("Done")
	return new_item


func get_current_captured_bodies():
	var bodies = []

	var raw_bodies = capture_field.get_overlapping_bodies()

	for rb in raw_bodies:
		var body = rb

		while not body.get_scene_file_path() and not body.has_meta("item_root"):
			body = body.get_parent()

		bodies.append(body)

	return bodies


func _process(_delta):
	if Input.is_action_just_pressed("capture_photo"):
		for data in captured_objects_data:
			data["combiner"].queue_free()
		captured_objects_data.clear()

		var bodies = get_current_captured_bodies()

		for body in bodies:
			var intersected_body = create_intersected_body(body)

			intersected_body.reparent(%CapturedObjects)

			intersected_body.set_process_mode(PROCESS_MODE_DISABLED)

		%CapturingFilter.visible = false

		# Since the viewport is not a Node3D, it doesn't pass the global transform to its children, we need to transfer it manually
		%PhotoCamera.global_transform = %Camera.global_transform
		%PhotoViewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE

		%CapturedPhoto.visible = true

	if Input.is_action_just_pressed("apply_photo"):
		var bodies = get_current_captured_bodies()

		for body in bodies:
			create_intersected_body(body, true)

			body.queue_free()

		for child in captured_objects.get_children():
			child.reparent(get_parent())
			child.set_process_mode(PROCESS_MODE_INHERIT)

		$ReenableFilterTimer.start()
		%CapturedPhoto.visible = false

	if Input.is_action_just_pressed("reset_position"):
		global_transform = initial_player_position.global_transform
		velocity = Vector3(0, 0, 0)


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

	var look_dir = (
		Input.get_vector("look_left", "look_right", "look_up", "look_down") * Vector2(-2, -2)
	)

	apply_look(look_dir)

	move_and_slide()


func _on_reenable_filter_timer_timeout():
	%CapturingFilter.visible = true
