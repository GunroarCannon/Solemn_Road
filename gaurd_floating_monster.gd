extends CharacterBody3D

@export_group("Floating Parameters")
@export var float_height: float = 3    
@export var wave_amplitude: float = 1.6    
@export var wave_frequency: float = 2.0    
@export var swing_amplitude: float = 0.8   
@export var swing_frequency: float = 1.5   

@export_group("Contact Damage")
@export var contact_damage: float = 15.0   # Damage dealt on touch
@export var damage_interval: float = 1.0   # Seconds between hits
var last_damage_time: float = 0.0          # Tracks cooldown

@export_group("Monster Stats")
@export var health = 100.0
@export var speed = 1.5
@export var run_speed = 3.5
@export var rotation_speed = 3.0 
@export var friction = 5.0 

@export_category("Jump/Physics") 
@export var jump_height: float = 2.0
@export var jump_fall_time: float = 0.5
var fall_gravity: float

# Internal Variables
var time_passed: float = 0.0
var chasing = false
var target_enemy : CharacterBody3D = null
var is_dead = false
var knockback_velocity = Vector3.ZERO
var time_stuck = 0.0
var last_pos = Vector3.ZERO

@onready var nav_agent = $NavigationAgent3D
@onready var anim : AnimationPlayer = $crawler/body/AnimationPlayer

func calculate_movement_parameters() -> void:
	fall_gravity = (2 * jump_height) / pow(jump_fall_time, 2)

func _ready():
	velocity.y = 1
	calculate_movement_parameters()
	pick_random_city_spot()

func _physics_process(delta: float):
	# 1. Decay Knockback
	knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, friction * delta)
	
	if is_dead:
		velocity.y -= fall_gravity * delta
		move_and_slide()
		return

	time_passed += delta
	
	# 2. Vision/Targeting
	check_for_enemies()

	if chasing and is_instance_valid(target_enemy):
		print("Chasinnnnnnnnnnng")
		var target_ground = target_enemy.global_position
		nav_agent.target_position = target_ground
	
	if nav_agent.is_navigation_finished() and not chasing:
		pick_random_city_spot()

	# 3. Floating & Sine Wave Math
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = (next_path_pos - global_position).normalized()
	#direction.y = 0
	
	var vertical_bob = sin(time_passed * wave_frequency) * wave_amplitude
	var horizontal_swing = global_transform.basis.x * sin(time_passed * swing_frequency) * swing_amplitude
	
	var desired_y = 0.0
	if chasing and is_instance_valid(target_enemy):
		desired_y = target_enemy.global_position.y + float_height + vertical_bob
	else:
		desired_y = float_height + vertical_bob

	var y_vel = (desired_y - global_position.y) * 4.0
	
	# 4. Apply Velocity
	var current_speed = run_speed if chasing else speed
	var move_velocity = (direction * current_speed) + horizontal_swing
	
	if chasing:
		var dis = global_position.distance_to(target_enemy.global_position)
		if dis > 4:
			move_velocity.y = y_vel
			
	velocity.x = move_velocity.x + knockback_velocity.x
	velocity.z = move_velocity.z + knockback_velocity.z
	velocity.y = move_velocity.y + knockback_velocity.y
	
	# 5. EXECUTE MOVEMENT
	move_and_slide()

	# 6. CONTACT DAMAGE LOGIC
	# We check every collision that happened during move_and_slide()
	check_contact_damage()

	# 7. Rotation & Animations
	if direction.length() > 0.1:
		var target_basis = Basis.looking_at(-direction) 
		global_basis = global_basis.slerp(target_basis, rotation_speed * delta).orthonormalized()
		rotation.x = 0
		rotation.z = 0

	update_animations()
	handle_stuck_logic(delta)

# --- NEW CONTACT DAMAGE FUNCTION ---

func check_for_enemies():
	if chasing: return # Already chasing
	
	## Simple proximity check (You could also use a RayCast or Area3D here)
	## For this example, we'll check for a "Player" group
	#var players = get_tree().get_nodes_in_group("Player")
	#for p in players:
		#if p is CharacterBody3D and global_position.distance_to(p.global_position) < 15.0:
			#aggro(p)
			#break
	
	
func check_contact_damage():
	# Don't hit if dead or if the cooldown hasn't finished
	if is_dead or Time.get_ticks_msec() < last_damage_time + (damage_interval * 1000):
		return
		
			# Play an animation or sound to indicate the hit
	if anim.has_animation("attack"): 
		anim.play("attack") 

func trigger_melee_check():
	# Iterate through all objects the monster is currently touching
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if the object hit is a CharacterBody3D (like the Player)
		if collider is CharacterBody3D and collider.has_method("Hit_Successful"):
			# Deal Damage
			var knock_dir = (collider.global_position - global_position).normalized()
			collider.Hit_Successful(contact_damage, knock_dir, collider.global_position, self)
			
			# Set cooldown timestamp
			last_damage_time = Time.get_ticks_msec()
			
			break 

# --- REMAINING LOGIC ---

func update_animations():
	var current = anim.current_animation
	if (current == "death" or current == "attack") and anim.is_playing(): return
	
	if velocity.length() < 0.2:
		play_animation("idle")
	else:
		play_animation("run" if chasing else "walk")

func get_hit(damage, bullet = null, knockback_force = 15.0, enemy = null):
	if is_dead: return
	health -= damage
	if health <= 0:
		die()
	else:
		if not chasing and enemy: aggro(enemy)
		# Standard knockback application
		var knock_dir = (global_position - enemy.global_position).normalized() if enemy else Vector3.UP
		knockback_velocity = knock_dir * knockback_force

func die():
	is_dead = true
	collision_layer = 0
	collision_mask = 1 # Only collide with floor
	play_animation("death")

func aggro(enemy):
	if enemy == self or is_dead: return
	target_enemy = enemy
	chasing = true

func handle_stuck_logic(delta):
	if global_position.distance_to(last_pos) < 0.05:
		time_stuck += delta
		if time_stuck > 1.0: pick_random_city_spot()
	else:
		time_stuck = 0.0
	last_pos = global_position

func pick_random_city_spot():
	if chasing or is_dead: return
	nav_agent.target_position = global_position + Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))

func play_animation(name : String):
	if anim.current_animation == name: return
	anim.play(name)

func Hit_Successful(damage, _dir, _pos, attacker = null):
	get_hit(damage, null, damage * 2.0, attacker)
