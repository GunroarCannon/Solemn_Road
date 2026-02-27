extends CharacterBody3D

@export_group("Floating Parameters")
@export var float_height: float = 3.0
@export var wave_amplitude: float = 0.5
@export var float_spring_strength: float = 5.0

@export_group("Movement Stats")
@export var patrol_speed: float = 4.0
@export var chase_speed: float = 8.0
@export var acceleration: float = 10.0
@export var friction: float = 1.0
@export var rotation_speed: float = 4.0

@export_group("Detection")
@export var detection_range: float = 20.0

@export_group("Stats")
@export var health: float = 50.0
@export var speed: float = 5.0
@export var contact_damage: float = 10.0
@export var damage_cooldown: float = 1.0

var is_dead = false;


# State Variables
var target_pos: Vector3 = Vector3.ZERO
var is_scanning: bool = false
var scan_timer: float = 0.0
var time_passed: float = 0.0
var chasing: bool = false
var target_enemy: CharacterBody3D = null
var knockback_velocity: Vector3 = Vector3.ZERO

@onready var ray: RayCast3D = $PatrolRaycast # Make sure this is in your scene!
@onready var anim: AnimationPlayer = $crawler/model/AnimationPlayer
@onready var light = $Light

@onready var melee_box = $crawler/MeleeBox

var been_moving = 0
var last_found_target = 0

var origional_pos

var random_rotation : Vector3 = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
	


func _ready():
	add_to_group("Enemy", true)
	
	anim.play("Armature_001|Armature_002Action_002")
	anim.get_animation("Armature_001|Armature_002Action_002").loop_mode = Animation.LOOP_LINEAR
	target_pos = global_position
	# Configure Raycast for searching space
	ray.enabled = false # We will manually fire it
	
	origional_pos = global_position

func _physics_process(delta: float):
	time_passed += delta
	last_found_target += delta
	
	rotation += random_rotation * delta * 1
	
	# 1. Perception Logic
	search_for_targets()
	
	# 2. State Machine Logic
	if chasing and is_instance_valid(target_enemy):
		target_pos = target_enemy.global_position
		move_logic(delta, chase_speed)
		chasing = false
		#light.light_energy = 10
		
		
	elif is_scanning:
		update_scanning(delta)
	else:
		#light.light_energy = 10
		move_logic(delta, patrol_speed)
		been_moving += delta*2
		
		# If we reach near the target, start scanning
		if been_moving>5 or global_position.distance_to(target_pos) < .5:
			start_scanning()
			been_moving = 0
	

	# 3. Floating (Always active)
	apply_float_logic(delta)
	
	# 4. Apply Final Velocity
	knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 60 * friction)
	velocity += knockback_velocity
	
	move_and_slide()
	do_attack(3)


func do_attack(att):
	if melee_box.is_colliding():
		for i in melee_box.get_collision_count():
			var collider = melee_box.get_collider(i)
			print(collider)
			if not collider.is_in_group("Enemy") and collider.has_method("Hit_Successful") and collider != self and is_visible:
				var knockback_dir = (global_position - collider.global_position).normalized()
				#knockback_dir.y = 0
				knockback_velocity = knockback_dir * 10
				collider.Hit_Successful(att, global_position.direction_to(collider.global_position),
					collider.global_position, self, 15)

### Core Behavior Functions3\

func distance_from_spawn(pos : Vector3):
	if not pos:
		pos = global_position
		
	return pos.distance_to(origional_pos)

func move_logic(delta: float, current_speed: float):
	# The "Overshoot" happens here: we accelerate toward the target
	# rather than snapping to it.
	
	if knockback_velocity.length() > 2:
		return
	
	var dir = (target_pos - global_position).normalized()
	
	# Horizontal movement
	var desired_velocity = dir * current_speed
	velocity.x = lerp(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = lerp(velocity.z, desired_velocity.z, acceleration * delta)
	velocity.y = lerp(velocity.y, desired_velocity.y, acceleration * delta)
	
	# Look Direction
	if velocity.length() > 0.5:
		var look_target = global_position + velocity
		look_target.y = global_position.y # Keep upright
		var target_basis = Basis.looking_at(global_position - look_target)
		#global_basis = global_basis.slerp(target_basis, rotation_speed * delta).orthonormalized()

func apply_float_logic(delta: float):
	var bob = sin(time_passed * 2.0) * wave_amplitude
	var target_y = target_pos.y + float_height + bob
	
	# Spring-like vertical movement
	var y_diff = target_y - global_position.y
	velocity.y = lerp(velocity.y, y_diff * float_spring_strength, delta * 5.0)

func search_for_targets():
	# Check for player (GlobalGame.player) or creatures
	var player = get_node_or_null("/root/Global") # Adjust based on your Global autoload
	var potential_target = null
	
	if player and player.get("player"):
		potential_target = player.player
	
	if potential_target:
		var dist = global_position.distance_to(potential_target.global_position)
		if dist < detection_range and last_found_target>5:
			aggro(potential_target)
		elif dist > detection_range + 2.0:
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
	
	var max_distance_from_spawn = 10
	
	if global_position.y-origional_pos.y > max_distance_from_spawn:
		random_dir.y = -1
		
	if global_position.y-origional_pos.y < -max_distance_from_spawn:
		random_dir.y = 1
	
	if global_position.z-origional_pos.z > max_distance_from_spawn:
		random_dir.z = -1
		
	if global_position.z-origional_pos.z < -max_distance_from_spawn:
		random_dir.z = 1
		
	if global_position.x-origional_pos.x > max_distance_from_spawn:
		random_dir.x = -1
		
	if global_position.x-origional_pos.x < -max_distance_from_spawn:
		random_dir.x = 1
		
	if distance_from_spawn(global_position+random_dir*10) > 10:
		pass
		
	if ray.is_colliding() and false:
		# Move to just before the wall
		target_pos = ray.get_collision_point() - (random_dir * 2.0)
	else:
		target_pos = global_position + (random_dir * 10.0)
		print("Set random pos")

func aggro(enemy):
	last_found_target = 0
	if is_dead: return
	if not chasing:
		is_scanning = false
	target_enemy = enemy
	chasing = true


func get_hit(damage, bullet = null, knockback_force = 15.0, enemy = null):
	if is_dead: return
	
	health -= damage
	print("Monster health: ", health)
	
	if health <= 0:
		die()
		return
	else:
		pass
		
	if not chasing and enemy:
		aggro(enemy)

	# Knockback Logic
	var knockback_dir = Vector3.ZERO
	if bullet and is_instance_valid(bullet):
		knockback_dir = -bullet.global_transform.basis.z.normalized()
		print("bullet")
	elif enemy:
		print("enemy")
		knockback_dir = (global_position - enemy.global_position).normalized()
	else:
		print("None enemy or bullet")
	
	knockback_dir.y = 0.1
	
	global_position += knockback_dir * 0.05
	
	knockback_velocity = knockback_dir * knockback_force
	print("Knockback vel is",knockback_velocity, knockback_force,knockback_dir)


func Hit_Successful(damage, _dir, _pos, attacker = null, knockback_arg = null):
	get_hit(damage, null, damage * 5.0, attacker)

func die():
	var Expo = preload("res://explosion_1.tscn")
	var expo : Node3D = Expo.instantiate()
	print("expo banana",expo.global_position)
	expo.scale *= .5
	
	add_child(expo)
	expo.lifetime =1.4
	expo.global_position = global_position
	
	queue_free()
	return
