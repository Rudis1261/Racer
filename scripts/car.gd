extends VehicleBody3D

@onready var cg: Marker3D = %CG
@onready var back_left_wheel: VehicleWheel3D = %back_left_wheel
@onready var back_right_wheel: VehicleWheel3D = %back_right_wheel
@onready var top_chase_camera: Camera3D = %TopChaseCamera
@onready var cock_pit_camera: Camera3D = %CockPitCamera
@onready var front_camera: Camera3D = %FrontCamera
@onready var rear_camera: Camera3D = %RearCamera
@onready var bl_marker: Marker3D = $bl_marker
#@onready var terrain_ray: RayCast3D = %terrain_ray

const MINI_CUBE = preload("res://scenes/mini_cube.tscn")
const STEERING_RATE = 0.5
const BRAKE_FORCE = 2
const MAX_RPM = 500
const MAX_TORQUE = 200
const MAX_SKID_LENGTH = 100
var cameras: Array[Camera3D]
var active_camera_index: int = 0

func _ready() -> void:
	active_camera_index = 0
	cameras = [top_chase_camera, cock_pit_camera, front_camera, rear_camera]

func _physics_process(delta: float) -> void:
	steering = lerp(steering, Input.get_axis("right", "left") * STEERING_RATE, 5 * delta)
	var accelleration = Input.get_axis("backward", "forward")
	
	var rpm = back_left_wheel.get_rpm()
	back_left_wheel.engine_force = accelleration * MAX_TORQUE * (1 - rpm / MAX_RPM)
	
	rpm = back_right_wheel.get_rpm()
	back_right_wheel.engine_force = accelleration * MAX_TORQUE * (1 - rpm / MAX_RPM)
	
	braking()
	change_cameras()
	drifting()

	center_of_mass.x = cg.position.x
	center_of_mass.y = cg.position.y
	center_of_mass.z = cg.position.z
	
func drifting():
	var traction = back_left_wheel.get_skidinfo()
	if traction > 0.5:
		return 
	
	print(traction)
	var cube = MINI_CUBE.instantiate()
	cube.global_position = bl_marker.global_position - global_position
	cube.top_level = true
	add_child(cube)	
	
func braking():
	back_left_wheel.brake = 0
	back_right_wheel.brake = 0
	
	if Input.is_action_pressed("handbrake"):
		back_left_wheel.brake = BRAKE_FORCE
		back_right_wheel.brake = BRAKE_FORCE

func change_cameras():
	if Input.is_action_just_pressed("change_camera"):
		active_camera_index += 1
		if active_camera_index > cameras.size()-1:
			active_camera_index = 0
		
		cameras[active_camera_index].current = true
