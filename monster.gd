extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var target_position
var patrolTime = 0;
var in_same_pos = 0;
var old_pos : Vector3 = Vector3(0,0,0);

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	patrolTime -= delta
	if not target_position and patrolTime<=0:
		patrolTime = 2
		patrol()

	# Handle jump.
	if false and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if target_position:
		var direction := (transform.basis * Vector3(target_position.x-global_position.x, 0, target_position.z-global_position.z)).normalized()
	
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		if global_position.is_equal_approx(old_pos):
			in_same_pos = in_same_pos + delta
		else:
			in_same_pos = 0
		
		var same_pos =  in_same_pos>1
		if abs(velocity.x)+abs(velocity.z)<=0.2 or patrolTime<=-3 or same_pos:
			target_position = null
			print("terminated", abs(velocity.x)+abs(velocity.z)<=0.2 ,self.patrolTime,same_pos)
			rotate_self(same_pos)
		#velocity.x = move_toward(direction.x, 0, SPEED)
		#velocity.z = move_toward(direction.z, 0, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	old_pos = global_position
	move_and_slide()

func patrol():
	var ray : RayCast3D = $PatrolRaycast
	var destination
	ray.force_raycast_update()
	if ray.is_colliding():
		var body = ray.get_collider()
		destination = body.global_position
		print("gotten")
	else:
		print("Non nothing for patrol raycast")
		pass
	
	if destination:
		target_position = destination;
	else:
		rotate_self()

func rotate_self(r180=false):
		var tween = get_tree().create_tween()
		var deg = r180 && 180 || randf_range(-70,70)
		tween.tween_property(self, "rotation", Vector3(rotation.x, rotation.y+deg_to_rad(deg), rotation.z), 1).set_trans(Tween.TRANS_SINE)
		print("rotate")

func get_hit(user, attack, bullet):
	pass
	

		
