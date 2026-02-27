extends CharacterBody3D

@export var health = 100.0
@export var speed = 1.0
@export var run_speed = 3.0
@export var rotation_speed = 2.0 
@export var friction = 0.1


@export_category("speed Parameters")
@export var enable_sprint: bool = true
@export var sprint_timer: Timer
@export var sprint_cooldown_time: float = 3.0
@export var sprint_time: float = 1.0
@export var sprint_replenish_rate: float = 0.30
@export var acceleration: float = 120
@export_range(0.01,1.0) var air_acceleration_modifier: float = 1
var sprint_on_cooldown: bool = false
var sprint_time_remaining: float = sprint_time
@onready var sprint_bar: Range = $CanvasLayer/SprintBar

@export var jump_peak_time: float = .5
@export var jump_fall_time: float = .5
@export var jump_height: float = 2.0
@export var jump_distance: float = 4.0
@export var coyote_time: float = .1
@export var jump_buffer_time: float = .2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var jump_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var fall_gravity: float
var jump_velocity: float
var base_speed: float 
var _speed: float 
var jump_available: bool = true
var jump_buffer: bool = false


@onready var nav_agent = $NavigationAgent3D
@onready var anim : AnimationPlayer = $crawler/body/AnimationPlayer
@onready var melee_box : ShapeCast3D = $crawler/MeleeBox # Ensure this name matches your scene tree

var chasing = false
var target_enemy : CharacterBody3D = null
var is_dead = false

var knockback_velocity = Vector3.ZERO
var time_stuck = 0.0
var last_pos = Vector3.ZERO

var possibleEnemy : Node3D
var looked_at_time : float = 0

func calculate_movement_parameters() -> void:
	jump_gravity = (2*jump_height)/pow(jump_peak_time,2)
	fall_gravity = 100
	jump_velocity = jump_gravity * jump_peak_time
	base_speed = jump_distance/(jump_peak_time+jump_fall_time)
	_speed = base_speed
	
func _ready():
	add_to_group("Enemy", true)
	
	
	
	print(fall_gravity, "is fall gravity")
	calculate_movement_parameters()
	pick_random_city_spot()

func _physics_process(delta: float):
			   

	# 1. Decay Knockback
	knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, friction * delta * 60)
	if not (knockback_velocity.x == 0 and knockback_velocity.y == 0 and knockback_velocity.z == 0):
		pass#print(knockback_velocity)
	if is_dead:
		move_and_slide()
		return
	
	# 2. Vision/Proximity Check
	check_for_enemies()

	# 3. Target Logic
	if chasing and is_instance_valid(target_enemy):# Calculate distance to player
		var dist = global_position.distance_to(target_enemy.global_position)
		
		# Only update path if we are outside the "Comfort Zone"
		if dist > 1.5:
			nav_agent.target_position = target_enemy.global_position
			if dist > 10:
				chasing = false
				target_enemy = null
		else:
			# If too close, tell the agent to stop moving
			nav_agent.target_position = global_position
		
		if target_enemy:
			if global_position.distance_to(target_enemy.global_position) < 2.0:
				attack()
	
	if nav_agent.is_navigation_finished():
		if not chasing:
			pick_random_city_spot()
		return

	# 4. Movement Calculation
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = (next_path_pos - global_position).normalized()
	direction.y = 0
	
	if direction.length() > 0.1:
		var target_basis = Basis.looking_at(-direction) 
		global_basis = global_basis.slerp(target_basis, rotation_speed * delta).orthonormalized()
		rotation.x = 0
		rotation.z = 0

	var current_speed = run_speed if chasing else speed
	var move_velocity = direction * current_speed
	if not is_moving():
		move_velocity = Vector3.ZERO
		
	velocity.x = move_velocity.x + knockback_velocity.x
	velocity.z = move_velocity.z + knockback_velocity.z
	velocity.y = velocity.y + knockback_velocity.y
	
	# Add the gravity.
	var _acceleration
	if not is_on_floor():
		_acceleration = acceleration*air_acceleration_modifier
		#
		#if coyote_timer.is_stopped():
			#coyote_timer.start(coyote_time)
	
		if true:
			velocity.y -= fall_gravity * delta
	else:
		_acceleration = acceleration
		jump_available = true
		#coyote_timer.stop()
		#_speed = (base_speed / max((float(crouched)*crouch_speed_reduction),1)) * speed_modifier
		if jump_buffer:
			#jump()
			jump_buffer = false
			
	move_and_slide()
	
	# 5. Animation Controller Logic
	update_animations()

	# 6. Stuck Detection
	handle_stuck_logic(delta)

func update_animations():
	var current = anim.current_animation
	var is_busy = (current == "death" or current == "attack" or current == "scream") and anim.is_playing()
	
	if is_busy:
		return
	
	if velocity.length() < 0.2:
		play_animation("idle")
	else:
		if chasing:
			play_animation("run")
		else:
			play_animation("walk")

func is_moving():
	var current = anim.current_animation
	var is_busy = (current == "death" or current == "attack" or current == "scream") and anim.is_playing()
	
	return not is_busy
	
func check_for_enemies():
	if chasing: return # Already chasing
	
	if possibleEnemy:
		var body = possibleEnemy
		if body.flashlight.light_energy > .5 and body.is_looking_at(self):
			looked_at_time += get_process_delta_time()
			if looked_at_time>.5:
				aggro(body)
	else:
		looked_at_time = 0
	
	## Simple proximity check (You could also use a RayCast or Area3D here)
	## For this example, we'll check for a "Player" group
	#var players = get_tree().get_nodes_in_group("Player")
	#for p in players:
		#if p is CharacterBody3D and global_position.distance_to(p.global_position) < 15.0:
			#aggro(p)
			#break
		
func aggro(enemy : CharacterBody3D):
	if enemy == self:
		return
	
	if enemy != GlobalGame.player:
		return
	
	target_enemy = enemy
	
	if chasing or is_dead: return
	
	target_enemy = enemy
	chasing = true
	play_animation("scream")
	var f = AudioManager.play_attached_sfx("loud_scream", self, 1.4, 1.8)
	f.volume_db = -20
	print("Monster Aggroed!")

func pacify():
	chasing = false
	target_enemy = null
	pick_random_city_spot()

func attack():
	if anim.current_animation == "attack": return
	
	play_animation("attack")

func trigger_melee_check():
	# Check MeleeBox for hits
	melee_box.force_shapecast_update()
	if melee_box.is_colliding():
		for i in melee_box.get_collision_count():
			var collider : Node = melee_box.get_collider(i)
			print(collider)
			if not collider.is_in_group("Enemy") and collider.has_method("Hit_Successful") and collider != self:
				var knockback_dir = (global_position - collider.global_position).normalized()
				knockback_dir.y = 0
				knockback_velocity = knockback_dir * 10
				collider.Hit_Successful(10.0, global_position.direction_to(collider.global_position), collider.global_position, self)

func get_hit(damage, bullet = null, knockback_force = 15.0, enemy = null):
	if is_dead: return
	
	health -= damage
	print("Monster health: ", health)
	
	if health <= 0:
		die()
		return
	else:
		play_animation("scream")
		var p = AudioManager.play_attached_sfx("pain", self, 0.5, 0.7)
		p.volume_db = -13
		
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

func die():
	velocity = Vector3.ZERO
	play_animation("death")
	AudioManager.play_sfx_3d("death", global_position)
	collision_layer = 0 # Stop interacting with world
	print("Monster died.")
	
	is_dead = true
	#anim.stop()
	
	# 2. Tell the skeleton to start simulating physics
	# This "activates" the PhysicalBone3D nodes
	#$crawler/body/Skeleton3D.physical_bones_start_simulation()
	
	# 3. Disable the main CharacterBody3D collision
	# We do this so the "invisible box" doesn't block the ragdoll
	collision_layer = 0
	collision_mask = 0
	
	# 4. Optional: Apply a small impulse to make it "pop"
	# You can pick a specific bone to kick
	# $crawler/body/Skeleton3D/PhysicalBoneHips.apply_central_impulse(Vector3.UP * 5)
	
	print("Monster is now a ragdoll.")

func Hit_Successful(damage, _dir, _pos, attacker = null, knockback_arg = null):
	var knock = min(15, damage) * 5
	if knockback_arg:
		knock = knockback_arg
	get_hit(damage, null, knock, attacker)

func handle_stuck_logic(delta):
	if global_position.distance_to(last_pos) < 0.02:
		time_stuck += delta
		if time_stuck > 0.8:
			pick_random_city_spot()
	else:
		time_stuck = 0.0
	last_pos = global_position

func pick_random_city_spot():
	if chasing or is_dead: return
	time_stuck = 0.0
	var random_target = global_position + Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
	nav_agent.target_position = random_target

func play_animation(name : String):
	if is_dead: return
	
	if anim.current_animation == name: return
	anim.play(name)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if is_dead: return
	# This will aggro on ANY CharacterBody3D that enters the circle
	if body is CharacterBody3D and body == GlobalGame.player and body != self:
		#aggro only let's player be the one to aggro, will work
		#if player is pointing light at this body
		print("crawler", body.flashlight.light_energy)
		possibleEnemy = body
		check_for_enemies()



func _on_area_3d_body_exited(body: Node3D) -> void:
	if is_dead: return
	# This will aggro on ANY CharacterBody3D that enters the circle
	if body == possibleEnemy:
		possibleEnemy = null
