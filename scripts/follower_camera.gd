extends Camera3D

# Follower script that can let a camera dynamically adjust its rotation and position/offset adjacent to its target.
# Maybe in the future add the ability to let the player rotate the camera slightly (within limits), when input released it snaps back (SMOOTHLY!!) to its set configuration

@export var follow_target : Node3D
@export var follow_offset : Vector3
@export var follow_smooth : float = 1

func _process(delta):
	position = lerp(position, follow_target.position + follow_offset, follow_smooth * delta)

func set_follow_target(new_target : Node3D):
	follow_target = new_target

func set_follow_offset(new_offset : Vector3):
	follow_offset = new_offset
