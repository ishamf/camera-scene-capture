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

@export var captured_objects_data = []


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


enum ShapeType {
	CONVEX,
	CONCAVE,
}

enum BodyType {
	RIGID,
	STATIC,
}


func intersect_new_body(body: Node3D):
	var body_mesh: MeshInstance3D = null
	var collision_body: CollisionObject3D = null

	var shape_type
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

		elif node is CollisionShape3D:
			if node.shape is ConvexPolygonShape3D:
				shape_type = ShapeType.CONVEX
			elif node.shape is ConcavePolygonShape3D:
				shape_type = ShapeType.CONCAVE
			else:
				print_debug("Unknown shape type.")
				return
			# We're recreating the collision object later
			node.queue_free()

	if not body_mesh or not collision_body:
		print_debug("No mesh or collision body found in the captured object.")
		return

	var csg_mesh = CSGMesh3D.new()

	csg_mesh.mesh = body_mesh.mesh.duplicate()

	if body != collision_body:
		csg_mesh.transform = body.transform * collision_body.transform
	else:
		csg_mesh.transform = body.transform

	var combiner = CSGCombiner3D.new()
	var intersector: CSGMesh3D = %CSGIntersector.duplicate()

	intersector.visible = true

	combiner.add_child(csg_mesh)
	combiner.add_child(intersector)

	combiner._update_shape()

	var mesh_tuple = combiner.get_meshes()

	var new_transform = mesh_tuple[0]
	var new_generated_mesh: Mesh = mesh_tuple[1].duplicate()

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = new_generated_mesh

	var new_item

	if body_type == BodyType.RIGID:
		var new_body = RigidBody3D.new()
		new_body.transform = new_transform
		new_body.add_child(mesh_instance)

		var shape = CollisionShape3D.new()

		new_body.add_child(shape)
		shape.make_convex_from_siblings()

		new_item = new_body

	else:
		if shape_type == ShapeType.CONVEX:
			mesh_instance.create_multiple_convex_collisions()
			new_item = mesh_instance
		else:
			var new_body = StaticBody3D.new()
			mesh_instance.add_child(new_body)

			var shape = CollisionShape3D.new()

			new_body.add_child(shape)
			shape.shape = mesh_instance.mesh.create_trimesh_shape()

			new_item = mesh_instance

	combiner.queue_free()

	new_item.set_meta("item_root", true)

	print("Done")
	return new_item


func _process(_delta):
	if Input.is_action_just_pressed("capture_photo"):
		for data in captured_objects_data:
			data["combiner"].queue_free()
		captured_objects_data.clear()

		var bodies = capture_field.get_overlapping_bodies()

		for coll in bodies:
			var body = coll

			while not body.get_scene_file_path() and not body.has_meta("item_root"):
				body = body.get_parent()

			var new_body = body.duplicate()
			body.add_sibling(new_body)
			new_body.reparent(%CapturedObjects)
			var intersected_body = intersect_new_body(new_body)
			new_body.queue_free()
			%CapturedObjects.add_child(intersected_body)
			intersected_body.set_process_mode(PROCESS_MODE_DISABLED)

		%CapturingFilter.visible = false
		%PhotoViewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
		%PhotoCamera.global_transform = %Camera.global_transform
		%CapturedPhoto.visible = true

	if Input.is_action_just_pressed("apply_photo"):
		for child in captured_objects.get_children():
			child.reparent(get_parent())
			child.set_process_mode(PROCESS_MODE_INHERIT)

		$ReenableFilterTimer.start()
		%CapturedPhoto.visible = false



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


func _on_reenable_filter_timer_timeout():
	%CapturingFilter.visible = true
