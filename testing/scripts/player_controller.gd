extends CharacterBody3D

var curr_speed = 0.125
var walk_speed = 3.25
var sprint_speed = 6.5
const JUMP_VELOCITY = 8.5

# Onready variables
@onready var model = $Model

# Camera onready variables
@onready var head = $Head
@onready var hand = $Head/Hand
@onready var fp_camera = $Head/Camera
@onready var tp_marker = $TP_Marker
@onready var tp_springpivot = $SpringPivot
@onready var tp_springarm = $SpringPivot/SpringArm3D
@onready var tp_camera = $SpringPivot/SpringArm3D/Camera

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# First and third person perspective switch variables
var view = 1

func _ready():
	view_change()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hand.set_as_top_level(true)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * 0.004)
		fp_camera.rotate_x(-event.relative.y * 0.004)
		fp_camera.global_rotation.x = clamp(fp_camera.global_rotation.x, deg_to_rad(-75), deg_to_rad(60))
		#tp_springpivot.rotate_y(-event.relative.x * 0.004)
		tp_springarm.rotate_x(-event.relative.y * 0.004)
		tp_springarm.global_rotation.x = clamp(tp_springarm.global_rotation.x, deg_to_rad(-75), deg_to_rad(60))

func _process(delta):
	if Input.is_action_just_pressed("switch"):
		view_change()
	if Input.is_action_pressed("sprint"):
		curr_speed = sprint_speed
	else:
		curr_speed = walk_speed

func _physics_process(delta):
	# Add the gravity.
	velocity.y -= gravity * delta
	
	# First-person hand movement
	hand.global_position = head.global_position
	hand.global_rotation.x = lerp_angle(hand.global_rotation.x, fp_camera.global_rotation.x, 15.0 * delta)
	hand.global_rotation.y = lerp_angle(hand.global_rotation.y, fp_camera.global_rotation.y, 15.0 * delta)
	
	# Third-person camera movement
	#tp_springarm.global_position = tp_marker.global_position
	#tp_springpivot.global_rotation.y = lerp_angle(tp_springpivot.global_rotation.y, head.global_rotation.y, 15.0 * delta)
	tp_springpivot.global_rotation.y = head.global_rotation.y
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump") && is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	model.global_rotation.y = lerp_angle(model.global_rotation.y, head.global_rotation.y, 12.5 * delta)
	
	if direction:
		velocity.x = lerp(velocity.x, direction.x * curr_speed, 15 * delta)
		velocity.z = lerp(velocity.z, direction.z * curr_speed, 15 * delta)
	else:
		if is_on_floor():
			velocity.x = lerp(velocity.x, 0.0, 7.5 * delta)
			velocity.z = lerp(velocity.z, 0.0, 7.5 * delta)
		else:
			velocity.x = lerp(velocity.x, 0.0, 3.5 * delta)
			velocity.z = lerp(velocity.z, 0.0, 3.5 * delta)

	move_and_slide()

func view_change():
	if view == 0:
		view = 1
		third_person()
	else:
		view = 0
		first_person()

func first_person():
	tp_camera.current = false
	fp_camera.current = true

func third_person():
	tp_camera.current = true
	fp_camera.current = false
