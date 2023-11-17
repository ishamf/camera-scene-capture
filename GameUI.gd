extends Control

@export var player: Player = null


# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if player.mouse_captured:
		%InfoText.text = ("\n".join(
			[
				"Left click to release",
				"Items to be captured: %s" % player.capture_field.get_overlapping_bodies().size(),
				"Captured items: %s" % player.captured_objects.get_child_count(),
			]
		))
	else:
		%InfoText.text = "Left click to capture"
