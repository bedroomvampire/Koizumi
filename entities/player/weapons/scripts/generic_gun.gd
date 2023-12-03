extends Node3D

# General variables
@onready var player = $"../../../.."
@export var curr_ammo = 18
@export var max_ammo = 18
@export var remaining_ammo = 144
@onready var raycast = $Raycast
@onready var counter = $Control/Label
@onready var flashlight = $Torso/Node3D2/ArmBox2/ArmBox2/ArmBox4/ArmBox5/SpotLight3D
@onready var attack_sfx = $Torso/Node3D2/ArmBox2/ArmBox2/ArmBox4/ArmBox5/AudioStreamPlayer3D

# Weapon variables
@export var wpn_name = "Generic"
@export var wpn_number = 2
@export var wpn_force = 5
@export var wpn_damage = 37.5
var selected : bool = true
var torch_on = false
var can_shoot : bool
var fire_rate = 0.25
var fire_rate_timer = 0.25

# hello
@export var recoil_strength = 0.15
@export var return_speed = 11.5
@export var recoil_snappiness = 30
var new_rot : Vector3
var curr_rot : Vector3
var new_pos : Vector3
var curr_pos : Vector3

# Crosshair variables
@onready var crosshair = $Crosshair
@onready var fallback_pos = $FallbackPos

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(_delta):
	# Counts ammo
	counter.text = str(curr_ammo) + " / " + str(remaining_ammo)
	crosshair.set_as_top_level(true)
	
	if player.curr_idx != wpn_number:
		selected = false
	else:
		selected = true
	
	if selected:
		visible = true
		counter.visible = true
	else:
		visible = false
		counter.visible = false
	
	if Input.is_action_just_pressed("flashlight") && selected:
		if !torch_on:
			torch_on = true
			lighton()
		else:
			torch_on = false
			lighton()
	
	if !selected:
		torch_on = false
		lighton()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Crosshair position
	if raycast.is_colliding():
		crosshair.global_position = lerp(crosshair.global_position, raycast.get_collision_point(), 17.5 * delta)
	else:
		crosshair.global_position = lerp(crosshair.global_position, fallback_pos.global_position, 17.5 * delta)
	
	# Shoots
	if can_shoot:
		if Input.is_action_pressed("leftclick"):
			if fire_rate_timer > fire_rate:
				shoot()
	if selected:
		if Input.is_action_just_pressed("leftclick") && curr_ammo <= 1:
			if fire_rate_timer > fire_rate:
				reload()
		if Input.is_action_just_pressed("reload"):
			reload()
	
	if curr_ammo == 0 || !selected:
		can_shoot = false
	else:
		can_shoot = true
	
	fire_rate_timer += delta
	
	new_rot = lerp(new_rot, Vector3.ZERO, delta * return_speed)
	curr_rot = lerp(curr_rot, new_rot, delta * recoil_snappiness)
	new_pos = lerp(new_pos, Vector3.ZERO, delta * return_speed)
	curr_pos = lerp(curr_pos, new_pos, delta * recoil_snappiness * 1.5)
	rotation = curr_rot
	position = curr_pos

func shoot():
	#fire_rate_timer = 0.0
	if curr_ammo >= 0:
		curr_ammo -= 1
		fire_rate_timer = 0.0
		attack_sfx.play()
		force()
		recoil()

func force():
	if raycast.get_collider() is RigidBody3D:
		var ray = raycast.get_collision_point()
		var body = raycast.get_collider()
		if body:
			var direction = (ray - global_transform.origin).normalized()
			body.apply_impulse(Vector3(direction.x, direction.y, direction.z) * wpn_damage)

func recoil():
	new_rot += Vector3(recoil_strength * 1.5, randf_range(-recoil_strength, recoil_strength) / 2, 0)
	new_pos += Vector3(0, 0, recoil_strength * 2)

func reload():
	fire_rate_timer = 0.0
	curr_ammo = max_ammo

func lighton():
	if torch_on:
		flashlight.visible = true
	else:
		flashlight.visible = false
