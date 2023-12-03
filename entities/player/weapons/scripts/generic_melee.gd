extends Node3D

# General variables
@onready var player = $"../../../.."
@onready var raycast = $Raycast
@onready var attack_sfx = $Attack_SFX
@onready var hit_sfx = $Hit_SFX

# Weapon variables
@export var wpn_name = "Generic"
@export var wpn_number = 1
@export var wpn_force = 2.5
@export var wpn_damage = 25.0
var selected : bool = true
var can_shoot : bool
var fire_rate = 0.5
var fire_rate_timer = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(_delta):
	if player.curr_idx != wpn_number:
		selected = false
	else:
		selected = true
	
	if selected:
		visible = true
	else:
		visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Shoots
	if can_shoot:
		if Input.is_action_pressed("leftclick"):
			if fire_rate_timer > fire_rate:
				shoot()
	
	if !selected:
		can_shoot = false
	else:
		can_shoot = true
	
	fire_rate_timer += delta

func shoot():
	fire_rate_timer = 0.0
	attack_sfx.play()
	force()

func force():
	if raycast.get_collider() != null:
		hit_sfx.play()
	if raycast.get_collider() is RigidBody3D:
		var ray = raycast.get_collision_point()
		var body = raycast.get_collider()
		if body:
			var direction = (ray - global_transform.origin).normalized()
			body.apply_impulse(Vector3(direction.x, direction.y, direction.z) * wpn_damage)
