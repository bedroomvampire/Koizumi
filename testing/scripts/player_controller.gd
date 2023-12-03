extends CharacterBody3D

var curr_speed = 0.125
var walk_speed = 3.25
var sprint_speed = 6.5
var crouch_speed = 1.625
const JUMP_VELOCITY = 8.5

# Variables
@onready var model = $Model

# Weapon variables
@export var weapons: Array[Node]
@export var curr_idx: int
var curr_weapon: Node

# Weapon holder variables
@onready var weapon_holder = $Head/Hand/WeaponHolder
var def_weapon_holder_pos : Vector3
var mouse_input : Vector2
var bob_amount : float = 0.02
var bob_freq : float = 0.01
const walk_freq = 0.0125
const sprint_freq = 0.02
const walk_amount = 0.025
const sprint_amount = 0.05

# Camera variables
@onready var head = $Head
@onready var hand = $Head/Hand
@onready var headbob = $Head/Headbob
@onready var fp_camera = $Head/Headbob/Camera
@onready var tp_springpivot = $SpringPivot
@onready var tp_springarm = $SpringPivot/SpringArm3D
@onready var tp_camera = $SpringPivot/SpringArm3D/Camera
@export var rot_amount : float = 0.0375

# Stand/Crouch variables
var crouching = false
@onready var stand_collision = $StandCollision
@onready var crouch_collision = $CrouchCollision
@onready var stand_marker = $StandMarker
@onready var crouch_marker = $CrouchMarker
@onready var crouch_detect = $CrouchDetect

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# First and third person perspective switch variables
var view = 1

func _ready():
	view_change()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hand.set_as_top_level(true)
	#curr_weapon = weapons[curr_idx]

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * 0.004)
		#head.global_rotation.y = clamp(head.global_rotation.y, deg_to_rad(-180), deg_to_rad(180))
		fp_camera.rotate_x(-event.relative.y * 0.004)
		fp_camera.rotation.x = clamp(fp_camera.rotation.x, deg_to_rad(-75), deg_to_rad(60))
		#tp_springpivot.rotate_y(-event.relative.x * 0.004)
		tp_springarm.rotate_x(-event.relative.y * 0.004)
		tp_springarm.rotation.x = clamp(tp_springarm.rotation.x, deg_to_rad(-75), deg_to_rad(60))
		mouse_input = event.relative

func _process(_delta):
	# Switch perspectives
	if Input.is_action_just_pressed("switch"):
		view_change()
	
	# Sprinting
	if Input.is_action_pressed("sprint") && !crouching:
		curr_speed = sprint_speed
	elif !crouching:
		curr_speed = walk_speed
	
	# Crouching
	if Input.is_action_pressed("crouch"):
		crouch()
	elif !crouch_detect.is_colliding():
		stand()
	
	if velocity.length() > 4:
		bob_freq = sprint_freq
		bob_amount = sprint_amount
	else:
		bob_freq = walk_freq
		bob_amount = walk_amount
	
	if Input.is_action_just_pressed("1"):
		if curr_idx != 1:
			switch_weapon(1)
		else:
			switch_weapon(0)
	if Input.is_action_just_pressed("2"):
		if curr_idx != 2:
			switch_weapon(2)
		else:
			switch_weapon(0)

func _physics_process(delta):
	# Add the gravity.
	velocity.y -= gravity * delta
	
	# First-person hand movement
	hand.global_position = head.global_position
	hand.global_rotation.x = lerp_angle(hand.global_rotation.x, fp_camera.global_rotation.x, 25.0 * delta)
	hand.global_rotation.y = lerp_angle(hand.global_rotation.y, fp_camera.global_rotation.y, 25.0 * delta)
	
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
	cam_tilt(velocity.length(), input_dir.x, delta)
	weapon_bob(velocity.length(),delta)
	
	if crouching:
		head.global_position = lerp(head.global_position, crouch_marker.global_position, 7.5 * delta)
		tp_springpivot.global_position = lerp(tp_springpivot.global_position, crouch_marker.global_position, 7.5 * delta)
	else:
		head.global_position = lerp(head.global_position, stand_marker.global_position, 7.5 * delta)
		tp_springpivot.global_position = lerp(tp_springpivot.global_position, stand_marker.global_position, 7.5 * delta)

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

func cam_tilt(vel, input_x, delta):
	if vel > 2:
		fp_camera.rotation.z = lerp(fp_camera.rotation.z, -input_x * rot_amount, 5 * delta)
		weapon_holder.rotation.z = lerp(weapon_holder.rotation.z, -input_x * rot_amount, 5 * delta)
	else:
		fp_camera.rotation.z = lerp(fp_camera.rotation.z, 0.0, 5 * delta)
		weapon_holder.rotation.z = lerp(weapon_holder.rotation.z, 0.0, 5 * delta)

func weapon_bob(vel : float, delta):
	if vel > 2 and is_on_floor():
		weapon_holder.position.y = lerp(weapon_holder.position.y, def_weapon_holder_pos.y + sin(Time.get_ticks_msec() * bob_freq) * bob_amount * 2.25, 10 * delta)
		weapon_holder.position.x = lerp(weapon_holder.position.x, def_weapon_holder_pos.x + sin(Time.get_ticks_msec() * bob_freq * 0.5) * bob_amount * 2.25, 10 * delta)
		headbob.position.y = lerp(headbob.position.y, def_weapon_holder_pos.y + sin(Time.get_ticks_msec() * bob_freq) * bob_amount * 2, 10 * delta)
		headbob.position.x = lerp(headbob.position.x, def_weapon_holder_pos.x + sin(Time.get_ticks_msec() * bob_freq * 0.5) * bob_amount * 2, 10 * delta)
	else:
		weapon_holder.position.y = lerp(weapon_holder.position.y, def_weapon_holder_pos.y, 10 * delta)
		weapon_holder.position.x = lerp(weapon_holder.position.x, def_weapon_holder_pos.x, 10 * delta)
		headbob.position.y = lerp(headbob.position.y, def_weapon_holder_pos.y, 10 * delta)
		headbob.position.x = lerp(headbob.position.x, def_weapon_holder_pos.x, 10 * delta)

func stand():
	crouching = false
	stand_collision.disabled = false
	crouch_collision.disabled = true

func crouch():
	crouching = true
	stand_collision.disabled = true
	crouch_collision.disabled = false
	curr_speed = crouch_speed

func switch_weapon(weapon):
	curr_idx = weapon
	#curr_weapon = weapons[curr_idx]
