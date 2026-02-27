extends CharacterBody3D
class_name Player

@onready var camera = %Camera
@export var subviewport_camera: Camera3D
@export var main_camera:Camera3D
@export var animation_tree: AnimationTree
@export var shaker : ShakerComponent3D
@export var cameraShake : CameraShake3DNode



var camera_rotation: Vector2 = Vector2(0.0,0.0)
var mouse_sensitivity = 0.001
var crouched: bool = false
var crouch_blocked: bool = false



@export_category("Crouch Parametres")
@export var enable_crouch: bool = true
@export var crouch_toggle: bool = false
@export var crouch_collision: ShapeCast3D
@export_range(0.0,3.0) var crouch_speed_reduction = 2.0
@export_range(0.0,0.50) var crouch_blend_speed = .2
enum {GROUND_CROUCH = -1, STANDING = 0, AIR_CROUCH = 1}



@export_category("Lean Parametres")
@export var enable_lean: bool = true
@export_range(0.0,1.0) var lean_speed: float = .2
@export var right_lean_collision: ShapeCast3D
@export var left_lean_collision: ShapeCast3D
var lean_tween
enum {LEFT = 1, CENTRE = 0, RIGHT = -1}



@export_category("speed Parameters")
@export var enable_sprint: bool = true
@export var sprint_timer: Timer
@export var sprint_cooldown_time: float = 3.0
@export var sprint_time: float = 1.0
@export var sprint_replenish_rate: float = 0.30
@export var acceleration: float = 120
@export_range(0.01,1.0) var air_acceleration_modifier: float = 0.1
var sprint_on_cooldown: bool = false
var sprint_time_remaining: float = sprint_time
@onready var sprint_bar: Range = $CanvasLayer/SprintBar


const NORMAL_speed = .3
@export_range(1.0,3.0) var sprint_speed: float = .7
@export_range(0.1,1.0) var walk_speed: float = 0.5
var speed_modifier: float = NORMAL_speed



#Powerup modifiers
var speed_multiplier = 1
var sprint_speed_multiplier = 1
var melee_damage_multiplier = 1
var gun_damage_multiplier = 1
var flashlight_energy_multiplier = 1#
var damage_in_air_multiplier = 1
var knockback_gotten_multiplier = 1
var melee_range_multiplier = 1
var melee_knockback_multiplier = 1
var gun_knockback_multiplier = 1
var jump_height_multiplier = 1
var gun_reload_time_multiplier = 1
var flashlight_color = null#
var flashlight_damage = 0#
var beserk_speed_is_on = false
var beserk_reload_is_on = false
var beserk_damage_is_on = false
var quiet_shot = false


@export_category("Jump Parameters")
@export var coyote_timer: Timer
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



var friction = 0.1
var is_dead = false
var knockback_velocity = Vector3.ZERO
var max_health = 30
var health = max_health

var is_player = true

@onready var flashlight : SpotLight3D = $Camera/LeanPivot/MainCamera/SpotLight3D
@onready var looking_collider : ShapeCast3D = $Camera/LeanPivot/MainCamera/LookingCollider

var breath_sfx : AudioStreamPlayer;
var current_breath: String= "breathe" ;

signal on_hit
# Configuration
@export var bob_freq := 2.0   # How fast the bob is
@export var bob_amp := 0.05   # How high/wide the bob is (Keep this small for 'subtle')
var t_bob := 0.0              # Tracks time for the sine wave

var footstep_timer = 0
var footstep_sounds = ["footstep", "footstep_2"]
var old_on_floor = true;

var played_scream = 0
var max_played_scream = 30

var starting_pos: Vector3

func check_footstep_sound(direction: Vector3, _delta):
	if direction.length() >= 0.9:
		footstep_timer += _delta
		#_speed = 
		if footstep_timer >= .5*min(2,base_speed/(_speed/walk_speed)):
			footstep_timer = 0
			play_footstep_sound()

func play_footstep_sound():
	var len = footstep_sounds.size()
	var i = randi_range(0, len-1)
	var p = AudioManager.play_attached_sfx(footstep_sounds[i], self, 0.7, 1.6)
	p.volume_db = -18
	
			
func is_looking_at(body : Node3D):
	print("Crawler checking")
	if looking_collider.is_colliding():
		print("crawler yes")
		var colliders = looking_collider.get_collision_count()
		for c in colliders:
			var Target = looking_collider.get_collider(c)
			print("crawler", Target, body)
			if Target == body:
				return true
	
	return false

func _ready() -> void:

	update_camera_rotation()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	calculate_movement_parameters()
	shaker.play_shake()
	camera_look(Vector2(0,0))
	
	
	breath_sfx = AudioManager.play_looping_sfx("breathe")
	var amb = AudioManager.play_ambience("amb2", preload("res://audio/Mp3/Ambience_Hell_01.mp3"))
	
	get_tree().create_timer(.5).timeout
	starting_pos = global_position
	
func update_breath_sfx():
	if current_breath == "none" and played_scream <= max_played_scream:
		return
	
	
	if is_dead and played_scream <= max_played_scream:
		AudioManager.stop_looping_sfx(breath_sfx, 0.5)
		breath_sfx.stop()
		var p = AudioManager.play_sfx("player_scream")
		current_breath = "none"
		#play scream a few times so it sounds more echo-y/strange
		played_scream += 1
		
		if p:
			p.volume_db -= 30*(played_scream/max_played_scream)
		
	var old_breath = current_breath
	var perc = (health/max_health)*100
	if perc<20:
		current_breath = "fast_breathe"
	elif perc<40:
		current_breath = "breath_tired"
	else:
		current_breath = "breathe"
	
	if old_breath != current_breath:
		breath_sfx.stop()
		breath_sfx = AudioManager.play_looping_sfx(current_breath)
		
func update_camera_rotation() -> void:
	var current_rotation = get_rotation()
	camera_rotation.x = current_rotation.y
	camera_rotation.y = current_rotation.x
	
	
func _input(event: InputEvent) -> void:
	if is_dead:
		return
		
	shaker.play_shake()
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if event is InputEventMouseMotion:
		var MouseEvent = event.relative * mouse_sensitivity
		camera_look(MouseEvent)
	
	if enable_crouch:
		if event.is_action_pressed("crouch"):
			crouch()
		if event.is_action_released("crouch"):
			if !crouch_toggle and crouched:
				crouch()
	
	if enable_lean:
		if Input.is_action_just_released("lean_left") or Input.is_action_just_released("lean_right"):
			if !(Input.is_action_pressed("lean_right") or Input.is_action_pressed("lean_left")):
				lean(CENTRE)
		if Input.is_action_just_pressed("lean_left"):
			lean(LEFT)
		if Input.is_action_just_pressed("lean_right"):
			lean(RIGHT)
		
	if enable_sprint:
		if Input.is_action_just_released("sprint") or Input.is_action_just_released("walk"):
			if !(Input.is_action_pressed("walk") or Input.is_action_pressed("sprint")):
				speed_modifier = NORMAL_speed
				exit_sprint()

		if Input.is_action_just_pressed("sprint") and !crouched:
			if !sprint_on_cooldown:
				speed_modifier = sprint_speed*sprint_speed_multiplier
				sprint_timer.start(sprint_time_remaining)

		if Input.is_action_just_pressed("walk") and !crouched:
			speed_modifier = walk_speed

func calculate_movement_parameters() -> void:
	jump_gravity = (2*jump_height)/pow(jump_peak_time,2)
	fall_gravity = (2*jump_height)/pow(jump_fall_time,2)
	jump_velocity = jump_gravity * jump_peak_time
	base_speed = jump_distance/(jump_peak_time+jump_fall_time)
	_speed = base_speed

func lean(blend_amount: int) -> void:
	if is_on_floor():
		if lean_tween:
			lean_tween.kill()
		
		lean_tween = get_tree().create_tween()
		lean_tween.tween_property(animation_tree,"parameters/lean_blend/blend_amount", blend_amount, lean_speed)

func lean_collision() -> void:
	animation_tree["parameters/left_collision_blend/blend_amount"] = lerp(
		float(animation_tree["parameters/left_collision_blend/blend_amount"]),float(left_lean_collision.is_colliding()),lean_speed
	)
	animation_tree["parameters/right_collision_blend/blend_amount"] = lerp(
		float(animation_tree["parameters/right_collision_blend/blend_amount"]),float(right_lean_collision.is_colliding()),lean_speed
	)

func crouch() -> void:
	var Blend
	if !crouch_collision.is_colliding():
		if crouched:
			Blend = STANDING
		else:
			speed_modifier = NORMAL_speed
			exit_sprint()
			
			if is_on_floor():
				Blend = GROUND_CROUCH
			else:
				Blend = AIR_CROUCH
		var blend_tween = get_tree().create_tween()
		blend_tween.tween_property(animation_tree,"parameters/Crouch_Blend/blend_amount",Blend,crouch_blend_speed)
		crouched = !crouched
	else:
		crouch_blocked = true

func camera_look(Movement: Vector2) -> void:
	camera_rotation += Movement
	
	transform.basis = Basis()
	camera.transform.basis = Basis()
	
	rotate_object_local(Vector3(0,1,0),-camera_rotation.x) # first rotate in Y
	camera.rotate_object_local(Vector3(1,0,0), -camera_rotation.y) # then rotate in X
	camera_rotation.y = clamp(camera_rotation.y,-1.5,1.2)
	
func exit_sprint() -> void:
	if !sprint_timer.is_stopped():
		sprint_time_remaining = sprint_timer.time_left
		sprint_timer.stop()

func sprint_replenish(delta) -> void:
	var sprint_bar_Value

	if !sprint_on_cooldown and (speed_modifier != sprint_speed):
		
		if is_on_floor():
			sprint_time_remaining = move_toward(sprint_time_remaining, sprint_time, delta*sprint_replenish_rate)
			
		sprint_bar_Value= (sprint_time_remaining/sprint_time)*100
		
	else:
		sprint_bar_Value = (sprint_timer.time_left/sprint_time)*100
	
	#sprint_bar_Value = ((int(Sprint)*sprint_time_remaining)+(int(!Sprint)*sprint_timer.time_left)/sprint_time)*100
	sprint_bar.value = sprint_bar_Value
	
	if sprint_bar_Value == 100:
		sprint_bar.hide()
	else:
		sprint_bar.show()

var last_bob_value = 0.0
func do_bop(_delta: float):
	var main_camera = $Camera/LeanPivot/MainCamera# Attach this to your Player script (the one that has 'velocity')
	var speed = Vector2(velocity.x, velocity.z).length()
	
	if is_on_floor(): #and speed > 0.1:
		t_bob += _delta * max(1,speed) * bob_freq 
		
		var current_bob_value = sin(t_bob)
		if last_bob_value < -0.95 and current_bob_value > last_bob_value:
			# TRIGGER FOOTSTEP
			pass
			 
		last_bob_value = current_bob_value
		
		# Apply to camera
		var pos = Vector3.ZERO
		var amp = 1.5
		if speed > 0.1:
			amp = 1
		pos.y = current_bob_value * bob_amp * amp
		pos.x = cos(t_bob * 0.5) * bob_amp * amp
		main_camera.position = pos
	else:
		t_bob = 0.0
		main_camera.position = main_camera.position.lerp(Vector3.ZERO, _delta * 10.0)
		
func _process(_delta: float) -> void:
	if subviewport_camera:
		subviewport_camera.global_transform = main_camera.global_transform
	
	var cam : Camera3D = $Camera3D
	#cam.current = true
	
	update_breath_sfx()
	
func _physics_process(_delta: float) -> void:

	sprint_replenish(_delta)
	lean_collision()
	
	var old_velocity_y = velocity.y
	
	if crouched and crouch_blocked:
		if !crouch_collision.is_colliding():
			crouch_blocked = false
			if !Input.is_action_pressed("crouch") and !crouch_toggle:
				crouch()
				
	# Add the gravity.
	var _acceleration
	if not is_on_floor():
		_acceleration = acceleration*air_acceleration_modifier
		
		if coyote_timer.is_stopped():
			coyote_timer.start(coyote_time)
	
		if velocity.y>0:
			velocity.y -= jump_gravity * _delta
		else:
			velocity.y -= fall_gravity * _delta
	else:
		_acceleration = acceleration
		jump_available = true
		coyote_timer.stop()
		_speed = (base_speed / max((float(crouched)*crouch_speed_reduction),1)) * speed_modifier
		if jump_buffer:
			jump()
			jump_buffer = false
	
	if is_dead:
		if not is_on_floor():
			velocity.y -= fall_gravity * _delta
		move_and_slide()
		return
		
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept"):
		if jump_available:
			if crouched:
				crouch()
			else:
				lean(CENTRE)
				jump()
		else:
			jump_buffer = true
			get_tree().create_timer(jump_buffer_time).timeout.connect(on_jump_buffer_timeout)

	#knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, friction * _delta * 60)
	if not (knockback_velocity.x == 0 and knockback_velocity.y == 0 and knockback_velocity.z == 0):
		pass#print(knockback_velocity)
	# Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir = Input.get_vector("left", "right", "up", "down")
	#var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#
	## Calculate movement velocity
	#var target_vel_x = direction.x * _speed
	#var target_vel_z = direction.z * _speed
	#
	#velocity.x = move_toward(velocity.x, target_vel_x, _acceleration * _delta)
	#velocity.z = move_toward(velocity.z, target_vel_z, _acceleration * _delta)
	#
	## APPLY KNOCKBACK DECAY
	## Increase friction to 5.0 or 10.0 in your variables for a better feel
	#knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, friction * _delta * 60)
	#
	## Add knockback to velocity right before moving
	#var total_velocity = velocity + knockback_velocity
	#
	## Use move_and_slide with the combined velocity
	#velocity = total_velocity 
	#move_and_slide()
	#
	## Important: Remove the knockback from the permanent velocity 
	## so move_toward doesn't "fight" it next frame
	#velocity -= knockback_velocity
		# 1. Get input
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 2. Assign velocity DIRECTLY (No more move_toward smoothing)
	if direction:
		var speedy = speed_multiplier
		
		if beserk_speed_is_on and health_is_low():
			speedy += 1
			
		velocity.x = direction.x * _speed * speedy
		velocity.z = direction.z * _speed * speedy
	else:
		velocity.x = 0
		velocity.z = 0
	
	check_footstep_sound(direction, _delta)
	# 3. Handle Gravity (Keep this separate)
	if not is_on_floor():
		velocity.y -= fall_gravity * _delta

	# 4. Add Knockback right at the end
	# Note: Use a higher friction (like 10.0) so the knockback doesn't last forever
	knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, friction * _delta * 60)

	velocity += knockback_velocity

	do_bop(_delta)
	move_and_slide()
	
	if velocity.y == 0 and floor(10*old_velocity_y) != floor(10*velocity.y):
		print("pll ",old_velocity_y, " to ", velocity.y, " to ", old_velocity_y==velocity.y)
		play_footstep_sound()

	# 5. Clean up for next frame
	velocity -= knockback_velocity

func health_is_low()->bool:
	return health <= 20

func jump()->void:
	velocity.y = jump_velocity * jump_height_multiplier
	jump_available = false

func _on_sprint_timer_timeout() -> void:
	sprint_on_cooldown = true
	get_tree().create_timer(sprint_cooldown_time).timeout.connect(_on_sprint_cooldown_timeout)
	speed_modifier = NORMAL_speed
	sprint_time_remaining = 0

func _on_sprint_cooldown_timeout():
	sprint_on_cooldown = false

func _on_coyote_timer_timeout() -> void:
	jump_available = false

func on_jump_buffer_timeout()->void:
	jump_buffer = false


func shakeCamera(decay=3, mag=.2):
	cameraShake._custom_shake(3.5,.2)
	
func die():
	if is_dead:
		return
		
	is_dead = true
	
	update_breath_sfx()
	
	velocity = Vector3.ZERO
	#collision_layer = 0 # Stop interacting with world
	#print("Player died.")
	
	#is_dead = true
	#anim.stop()
	
	# 2. Tell the skeleton to start simulating physics
	# This "activates" the PhysicalBone3D nodes
	#$crawler/body/Skeleton3D.physical_bones_start_simulation()
	
	# 3. Disable the main CharacterBody3D collision
	# We do this so the "invisible box" doesn't block the ragdoll
	#collision_layer = 0
	#collision_mask = 0
	
	# 4. Optional: Apply a small impulse to make it "pop"
	# You can pick a specific bone to kick
	# $crawler/body/Skeleton3D/PhysicalBoneHips.apply_central_impulse(Vector3.UP * 5)
	
	print("Player is now a ragdoll.")

func get_hit(damage, bullet = null, knockback_force = 15.0, enemy = null):
	if is_dead: return
	
	var bdamage = $BloodScreen
	health -= damage
	
	if bdamage:
		
		bdamage.update_health(health, max_health)
	else:
		print("nanh has no bdamage")
		
	print("Monster health: ", health)
	
		
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
	
	knockback_dir.y = 0
	knockback_velocity = knockback_velocity + knockback_dir * knockback_force
	#self.velocity += knockback_dir * knockback_force
	print("Player Knockback vel is",knockback_velocity, knockback_force,knockback_dir)
	
	on_hit.emit(health)
	
	shakeCamera()
	
	if health <= 0:
		die()
		return
	else:
		pass

func Hit_Successful(damage, _dir, _pos, attacker = null, knockback_arg = null):
	print("getting hit ",is_dead)
	
	var knock = damage * 5.0
	if knockback_arg:
		knock = knockback_arg
		
	get_hit(damage, null, knock, attacker)

func on_shoot(type=null):
	# Knockback Logic
	var knockback_dir = global_transform.basis.z
	var knockback_force = 3
	
	knockback_dir.y = 0
	knockback_velocity = knockback_velocity + knockback_dir * knockback_force
	#self.velocity += knockback_dir * knockback_force
	print("Player Knockback vel is",knockback_velocity, knockback_force,knockback_dir)
	
	
	
