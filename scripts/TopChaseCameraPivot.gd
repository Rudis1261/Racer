extends Node3D

var direction = Vector3.FORWARD
@export_range(0, 100, 0.25) var camera_smooth_speed: float = 20

func _physics_process(delta: float) -> void:
	var current_velocity = get_parent().get_parent().linear_velocity
	current_velocity.y = 0
	
	if current_velocity.length_squared() < 1:
		return
		
	direction = lerp(direction, -current_velocity.normalized(), camera_smooth_speed * delta)
	
	# Set the rotation of the camera_pivot
	global_transform.basis = get_rotation_from_direction(direction)
	
# https://www.youtube.com/watch?v=6A6tp-rKy3Y
func get_rotation_from_direction(look_direction: Vector3) -> Basis:
	look_direction = look_direction.normalized()
	var x_axis = look_direction.cross(Vector3.UP)
	return Basis(x_axis, Vector3.UP, -look_direction)
