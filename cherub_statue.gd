extends CharacterBody3D

@export_group("Floating Parameters")
@export var float_height: float = 3.0
@export var wave_amplitude: float = 0.5
@export var float_spring_strength: float = 5.0

@export_group("Movement Stats")
@export var patrol_speed: float = 4.0
@export var chase_speed: float = 2.2
@export var acceleration: float = 1.2	
@export var friction: float = 2.0
@export var rotation_speed: float = 4.0
var fall_gravity


@export_group("Detection")
@export var detection_range: float = 20.0

@export_group("Stats")
@export var health: float = 100.0
@export var speed: float = 5.0
@export var contact_damage: float = 10.0
@export var damage_cooldown: float = 1.0

var is_dead = false;
var is_visible = false;


# State Variables
var target_pos: Vector3 = Vector3.ZERO
var is_scanning: bool = false
var scan_timer: float = 0.0
var time_passed: float = 0.0
var chasing: bool = false
var target_enemy: CharacterBody3D = null
var knockback_velocity: Vector3 = Vector3.ZERO

@onready var ray: RayCast3D = $PatrolRaycast # Make sure this is in your scene!
@onready var anim: AnimationPlayer = $crawler/body/AnimationPlayer

@onready var light : OmniLight3D = $Light

@onready var melee_box : ShapeCast3D = $crawler/MeleeBox

var max_light_energy = 10
var light_energy_increase_speed = 2

func _ready():
	fall_gravity = 100
	target_pos = global_position
	light.light_energy = 0;
	# Configure Raycast for searching space
	ray.enabled = false # We will manually fire it

func _physics_process(delta: float):
	time_passed += delta
	
	knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, friction * delta * 60)
	if not (knockback_velocity.x == 0 and knockback_velocity.y == 0 and knockback_velocity.z == 0):
		pass#print(knockback_velocity)
		
	# 1. Perception Logic
	search_for_targets()
	
	# 2. State Machine Logic
	if chasing and is_instance_valid(target_enemy):
		target_pos = target_enemy.global_position
		move_logic(delta, chase_speed)
	elif is_scanning:
		update_scanning(delta)
	else:
		move_logic(delta, patrol_speed)
	
	if is_visible:
		light.light_energy = min(10, light.light_energy+light_energy_increase_speed*delta)
	else:
		light.light_energy = max(0, light.light_energy-light_energy_increase_speed*delta*2)
		
		
	velocity += knockback_velocity
	
	velocity.y -= fall_gravity * delta
	
	move_and_slide()


### Core Behavior Functions

func move_logic(delta: float, current_speed: float):
	if true:
		return
	
	if not is_visible:
		return
	
	var distance = global_position.distance_to(target_pos)
	if distance < 1.5:
		if target_enemy and is_visible and light.light_energy>(max_light_energy/3):
			do_attack(target_enemy, 10)
		else:
			pass#print("no")
		return
		
	# The "Overshoot" happens here: we accelerate toward the target
	# rather than snapping to it.
	var dir = (target_pos - global_position).normalized()
	
	# Horizontal movement
	
	var desired_velocity = dir * current_speed
	velocity.x = lerp(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = lerp(velocity.z, desired_velocity.z, acceleration * delta)
	
	# Look Direction
	if velocity.length() > 0.5:
		var look_target = global_position + velocity
		look_target.y = global_position.y # Keep upright
		var target_basis = Basis.looking_at(global_position - look_target)
		global_basis = global_basis.slerp(target_basis, rotation_speed * delta).orthonormalized()

func apply_float_logic(delta: float):
	var bob = sin(time_passed * 2.0) * wave_amplitude
	var target_y = target_pos.y + float_height + bob
	
	# Spring-like vertical movement
	var y_diff = target_y - global_position.y
	velocity.y = lerp(velocity.y, y_diff * float_spring_strength, delta * 5.0)

func do_attack(enemy, att):
	
	melee_box.force_shapecast_update()
	if melee_box.is_colliding():
		for i in melee_box.get_collision_count():
			var collider = melee_box.get_collider(i)
			print(collider)
			if collider.has_method("Hit_Successful") and collider != self and is_visible:
				var knockback_dir = (global_position - collider.global_position).normalized()
				knockback_dir.y = 0
				knockback_velocity = knockback_dir * 5
				collider.Hit_Successful(att, global_position.direction_to(collider.global_position),
					collider.global_position, self, 15)

func search_for_targets():
	# Check for player (GlobalGame.player) or creatures
	var player = GlobalGame.player
	var potential_target = null
	
	if player:
		potential_target = player
	
	if potential_target:
		var dist = global_position.distance_to(potential_target.global_position)
		if dist < detection_range:
			aggro(potential_target)
		elif dist > detection_range + 5.0:
			chasing = false
			target_enemy = null

func start_scanning():
	is_scanning = true
	scan_timer = randf_range(1.5, 3.0)
	velocity = velocity * 0.5 # Slow down while looking around

func update_scanning(delta: float):
	scan_timer -= delta
	# Random twitchy rotation
	rotation.y += sin(time_passed * 10.0) * 0.1
	
	if scan_timer <= 0:
		is_scanning = false
		pick_next_random_pos()

func pick_next_random_pos():
	# Use Raycast to find a valid spot in the air
	var random_dir = Vector3(randf_range(-1, 1), randf_range(-0.5, 0.5), randf_range(-1, 1)).normalized()
	ray.target_position = random_dir * 10.0
	ray.force_raycast_update()
	
	if ray.is_colliding():
		# Move to just before the wall
		target_pos = ray.get_collision_point() - (random_dir * 2.0)
	else:
		target_pos = global_position + (random_dir * 10.0)

func aggro(enemy):
	if is_dead: return
	target_enemy = enemy
	chasing = true
	is_scanning = false

func get_hit(damage, attacker = null):
	health -= damage
	if attacker:
		aggro(attacker)


func on_visible():
	is_visible = true
	print("visible")

func on_not_visible():
	is_visible = false
	velocity.x = 0
	velocity.z = 0
	knockback_velocity = Vector3.ZERO
	print("not visible")
