extends VehicleBody3D

@onready var cg: Marker3D = %CG
@onready var back_left_wheel: VehicleWheel3D = %back_left_wheel
@onready var back_right_wheel: VehicleWheel3D = %back_right_wheel

@onready var top_chase_camera: Camera3D = %TopChaseCamera
@onready var cock_pit_camera: Camera3D = %CockPitCamera
@onready var front_camera: Camera3D = %FrontCamera
@onready var rear_camera: Camera3D = %RearCamera


const STEERING_RATE = 0.4
const BRAKE_FORCE = 2
const MAX_RPM = 500
const MAX_TORQUE = 200
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

	center_of_mass.x = cg.position.x
	center_of_mass.y = cg.position.y
	center_of_mass.z = cg.position.z
	
func braking():
	brake = 0
	if Input.is_action_pressed("handbrake"):
		brake = BRAKE_FORCE

func change_cameras():
	if Input.is_action_just_pressed("change_camera"):
		active_camera_index += 1
		if active_camera_index > cameras.size()-1:
			active_camera_index = 0
		
		cameras[active_camera_index].current = true
