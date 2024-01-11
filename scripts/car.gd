extends VehicleBody3D
class_name Vehicle

@export var car_body: MeshInstance3D

@onready var front_left_wheel: VehicleWheel3D = %front_left_wheel
@onready var front_right_wheel: VehicleWheel3D = %front_right_wheel
@onready var back_left_wheel: VehicleWheel3D = %back_left_wheel
@onready var back_right_wheel: VehicleWheel3D = %back_right_wheel

@export var front_left_wheel_mesh: MeshInstance3D
@export var front_right_wheel_mesh: MeshInstance3D
@export var back_left_wheel_mesh: MeshInstance3D
@export var back_right_wheel_mesh: MeshInstance3D

@onready var bl_marker: Marker3D = %bl_marker
@onready var fr_marker: Marker3D = %fr_marker
@onready var fl_marker: Marker3D = %fl_marker
@onready var br_marker: Marker3D = %br_marker

@onready var top_chase_camera: Camera3D = %TopChaseCamera
@onready var cock_pit_camera: Camera3D = %CockPitCamera
@onready var front_camera: Camera3D = %FrontCamera
@onready var rear_camera: Camera3D = %RearCamera

@onready var speed_display: ProgressBar = %speed_display
@onready var boost_display: ProgressBar = %boost_display
@onready var current_speed: Label = %current_speed

@onready var flipped_ray: RayCast3D = %flipped_ray
@onready var terrain_ray: RayCast3D = %terrain_ray

@export var cg: Marker3D
@export var debugging: bool = false
@export var torque_curve: Curve
@export var drive: DRIVE
@export var max_speed:int = 160
@export var boost_torque:int = 400

@export_subgroup("Meshes")
@export var wheel_mesh: MeshInstance3D
@export var car_body_mesh: MeshInstance3D

@export_subgroup("Steering")
@export var steering_rate:float = 0.5

@export_subgroup("Braking")
@export var brake_force_front:float = 1
@export var brake_force_rear:float = 2

@export_subgroup("Wheel Front")
@export var front_roll_influence:float = 0.1
@export var front_radius:float = 0.4
@export var front_rest_length:float = 0.25
@export var front_friction_slip:float = 1
@export var front_slip_clamp:float = 0.06

@export_subgroup("Wheel Rear")
@export var rear_roll_influence:float = 0.1
@export var rear_radius:float = 0.4
@export var rear_rest_length:float = 0.25
@export var rear_friction_slip:float = .7
@export var rear_wheel_slip_cutoff:float = 0.3

@export_subgroup("Suspension Front")
@export var suspension_front_travel: float = 0.4
@export var suspension_front_stiffness: int = 100
@export var suspension_front_max_force: float = 3000
@export var suspension_front_dampening_compression: float = 1.9
@export var suspension_front_dampening_relaxation: float = 2

@export_subgroup("Suspension Rear")
@export var suspension_rear_travel: float = 0.4
@export var suspension_rear_stiffness: int = 100
@export var suspension_rear_max_force: float = 3000
@export var suspension_rear_dampening_compression: float = 1.9
@export var suspension_rear_dampening_relaxation: float = 2

enum DRIVE {
	FRONT_WHEEL_DRIVE,
	REAR_WHEEL_DRIVE,
	ALL_WHEEL_DRIVE,
}

const MINI_CUBE = preload("res://scenes/mini_cube.tscn")

var cameras: Array[Camera3D]
var wheels: Array[VehicleWheel3D]
var rear_wheels: Array[VehicleWheel3D]
var front_wheels: Array[VehicleWheel3D]
var wheel_markers: Array[Marker3D]
var wheel_meshes: Array[MeshInstance3D]
var wheel_slip_cutoff: Array[float]
var active_camera_index: int = 0
var boost_active: bool = false
var boost_amount: int = 500

func _ready() -> void:
	active_camera_index = 0
	cameras = [top_chase_camera, cock_pit_camera, front_camera, rear_camera]
	
	wheels = [front_left_wheel, front_right_wheel, back_left_wheel, back_right_wheel]
	front_wheels = [front_left_wheel, front_right_wheel]
	rear_wheels = [back_left_wheel, back_right_wheel]
	wheel_meshes = [front_left_wheel_mesh, front_right_wheel_mesh, back_left_wheel_mesh, back_right_wheel_mesh]
	wheel_markers = [fl_marker, fr_marker, bl_marker, br_marker]
	wheel_slip_cutoff = [front_slip_clamp, front_slip_clamp, rear_wheel_slip_cutoff, rear_wheel_slip_cutoff]
	
	boost_display.max_value = boost_amount
	boost_display.value = 0
	
	speed_display.max_value = max_speed + 30
	speed_display.value = 0
	
	_set_wheel_drive_mode()
	_set_suspension()
	_set_wheel_defaults()
	_set_meshes()
	
	center_of_mass.x = cg.position.x
	center_of_mass.y = cg.position.y
	center_of_mass.z = cg.position.z
	
func _set_meshes() -> void:
	if wheel_mesh != null:
		for i in range(0, wheel_meshes.size()):
			wheel_meshes[i].mesh = wheel_mesh.mesh
	
	if car_body_mesh != null:
		car_body.mesh = car_body_mesh.mesh
	
func _set_wheel_drive_mode() -> void:
	for i in range(0, wheels.size()):
		wheels[i].use_as_traction = false
	
	if drive == DRIVE.FRONT_WHEEL_DRIVE || drive == DRIVE.ALL_WHEEL_DRIVE:
		for i in range(0, front_wheels.size()):
			front_wheels[i].use_as_traction = true
		
	if drive == DRIVE.REAR_WHEEL_DRIVE || drive == DRIVE.ALL_WHEEL_DRIVE:
		for i in range(0, rear_wheels.size()):
			rear_wheels[i].use_as_traction = true

func _set_wheel_defaults() -> void:
	for i in range(0, front_wheels.size()):
		front_wheels[i].wheel_roll_influence = front_roll_influence
		front_wheels[i].wheel_radius = front_radius
		front_wheels[i].wheel_rest_length = front_rest_length
		front_wheels[i].wheel_friction_slip = front_friction_slip
		
	for i in range(0, rear_wheels.size()):
		rear_wheels[i].wheel_roll_influence = rear_roll_influence
		rear_wheels[i].wheel_radius = rear_radius
		rear_wheels[i].wheel_rest_length = rear_rest_length
		rear_wheels[i].wheel_friction_slip = rear_friction_slip

func _set_suspension() -> void:
	for i in range(0, front_wheels.size()):
		front_wheels[i].suspension_max_force = suspension_front_max_force
		front_wheels[i].suspension_stiffness = suspension_front_stiffness
		front_wheels[i].suspension_travel = suspension_front_travel
		front_wheels[i].damping_relaxation = suspension_front_dampening_relaxation
		front_wheels[i].damping_compression = suspension_front_dampening_compression
	
	for i in range(0, rear_wheels.size()):
		rear_wheels[i].suspension_max_force = suspension_rear_max_force
		rear_wheels[i].suspension_stiffness = suspension_rear_stiffness
		rear_wheels[i].suspension_travel = suspension_rear_travel
		rear_wheels[i].damping_relaxation = suspension_rear_dampening_relaxation
		rear_wheels[i].damping_compression = suspension_rear_dampening_compression
	
func kmph() -> float:
	return linear_velocity.length() * 3.6

func _physics_process(delta: float) -> void:
	steering = lerp(steering, Input.get_axis("right", "left") * steering_rate, 5 * delta)
	var accelleration = Input.get_axis("backward", "forward")
	
	var speed = kmph()
	current_speed.text = "%.02f" % speed
	speed_display.value = speed
	var speed_percentile = clampf(speed / max_speed, 0.0, 1.0)
	var effective_torque = torque_curve.sample(speed_percentile)
	if boost_active:
		effective_torque += boost_torque
		
	engine_force = accelleration * effective_torque
	if debugging:
		print("BOOST: ", boost_active, ", SPEED %: ", speed_percentile, ", ENGINE_FORCE: ", engine_force, ", EFFECTIVE_TORQUE: ", effective_torque)
	
	braking()
	boosting()
	change_cameras()
	trails()
	_upside_down()
	
func trails():
	if !terrain_ray.is_colliding():
		return
		
	for i in range(0, wheels.size()):
		var traction = wheels[i].get_skidinfo()
		if debugging:
			print(i, " > ", wheel_slip_cutoff[i], " : ", traction)
		if traction > wheel_slip_cutoff[i]:
			continue 
		
		var cube = MINI_CUBE.instantiate()
		get_tree().root.add_child(cube)
		cube.global_position = wheel_markers[i].global_position
		cube.position.y = 0.2
		cube.rotation.z = rotation.z

func boosting():
	boost_display.value = 0
	boost_active = false
	boost_active = Input.is_action_pressed("boost")
	if boost_active:
		boost_display.value = boost_amount
	
func braking():
	front_left_wheel.brake = 0
	front_right_wheel.brake = 0
	back_left_wheel.brake = 0
	back_right_wheel.brake = 0
	
	if Input.is_action_pressed("handbrake"):
		front_left_wheel.brake = brake_force_front
		front_right_wheel.brake = brake_force_front
		back_left_wheel.brake = brake_force_rear
		back_right_wheel.brake = brake_force_rear

func change_cameras():
	if Input.is_action_just_pressed("change_camera"):
		active_camera_index += 1
		if active_camera_index > cameras.size()-1:
			active_camera_index = 0
		
		cameras[active_camera_index].current = true

func reset_car():
	linear_velocity = Vector3()
	position.y += 3
	rotation.z = 0
	print("reset car")

func _upside_down():
	if flipped_ray.is_colliding():
		reset_car()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_car"):
		reset_car()

