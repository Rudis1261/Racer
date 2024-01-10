extends VehicleBody3D

@onready var cg: Marker3D = %CG

@onready var front_left_wheel: VehicleWheel3D = %front_left_wheel
@onready var front_right_wheel: VehicleWheel3D = %front_right_wheel
@onready var back_left_wheel: VehicleWheel3D = %back_left_wheel
@onready var back_right_wheel: VehicleWheel3D = %back_right_wheel

@onready var bl_marker: Marker3D = %bl_marker
@onready var fr_marker: Marker3D = %fr_marker
@onready var fl_marker: Marker3D = %fl_marker
@onready var br_marker: Marker3D = %br_marker

@onready var top_chase_camera: Camera3D = %TopChaseCamera
@onready var cock_pit_camera: Camera3D = %CockPitCamera
@onready var front_camera: Camera3D = %FrontCamera
@onready var rear_camera: Camera3D = %RearCamera

@onready var rpm_display: ProgressBar = %rpm_display
@onready var boost_display: ProgressBar = %boost_display

const MINI_CUBE = preload("res://scenes/mini_cube.tscn")
const STEERING_RATE = 0.5
const BRAKE_FORCE = 5
const MAX_RPM = 500
const MAX_TORQUE = 500
const BOOST_TORQUE = 300
const MAX_SKID_LENGTH = 100

var cameras: Array[Camera3D]
var wheels: Array[VehicleWheel3D]
var wheel_markers: Array[Marker3D]
var wheel_slip_cutoff: Array[float]
var active_camera_index: int = 0
var boost_active: bool = false
var boost_amount: int = 500

func _ready() -> void:
	active_camera_index = 0
	cameras = [top_chase_camera, cock_pit_camera, front_camera, rear_camera]
	
	wheels = [front_left_wheel, front_right_wheel, back_left_wheel, back_right_wheel]
	wheel_markers = [fl_marker, fr_marker, bl_marker, br_marker]
	wheel_slip_cutoff = [.06, .06, .3, .3]
	
	boost_display.max_value = boost_amount
	boost_display.value = 0
	
	rpm_display.max_value = MAX_RPM
	rpm_display.value = 0

func _physics_process(delta: float) -> void:
	steering = lerp(steering, Input.get_axis("right", "left") * STEERING_RATE, 5 * delta)
	var accelleration = Input.get_axis("backward", "forward")
	var applied_torque = MAX_TORQUE
	if boosting:
		applied_torque = MAX_TORQUE + BOOST_TORQUE
	
	var left_rpm = back_left_wheel.get_rpm()	
	back_left_wheel.engine_force = accelleration * applied_torque * (1 - left_rpm / MAX_RPM)
	
	var right_rpm = back_right_wheel.get_rpm()
	back_right_wheel.engine_force = accelleration * applied_torque * (1 - right_rpm / MAX_RPM)
	
	rpm_display.value = (left_rpm + right_rpm) / 2
	
	braking()
	boosting()
	change_cameras()
	trails()

	center_of_mass.x = cg.position.x
	center_of_mass.y = cg.position.y
	center_of_mass.z = cg.position.z
	
func trails():
	for i in range(0, wheels.size()):
		var traction = wheels[i].get_skidinfo()
		print(i, " > ", wheel_slip_cutoff[i], " : ", traction)
		if traction > wheel_slip_cutoff[i]:
			continue 
		
		var cube = MINI_CUBE.instantiate()
		cube.global_position = wheel_markers[i].global_position
		cube.top_level = true
		get_tree().root.add_child(cube)

func boosting():
	boost_display.value = 0
	boost_active = Input.is_action_pressed("boost")
	if boost_active:
		boost_display.value = boost_amount
	
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
