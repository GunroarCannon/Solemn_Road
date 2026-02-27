extends RigidBody3D

@onready var light : Light3D = $OmniLight3D
@onready var label3D : Label3D = $Label3D

@export var weapon: WeaponSlotP
@export_enum("Weapon","Ammo") var TYPE = "Weapon"



var Pick_Up_Ready: bool = false

func _ready() -> void:
	scale *= 3
	await get_tree().create_timer(2.0).timeout
	Pick_Up_Ready = true
	

func get_collected(collector):
	collector.shakeCamera()
	var light_tween = create_tween()
	light_tween.tween_property(light, "light_energy", 0, .4)
	light_tween.tween_callback(get_destroyed)


# Break the mesh when you press the SPACE key
func do_break(stm_instance : STMCachedInstance3D):
	
	assert(stm_instance, "None")
	
	var vel = linear_velocity
	label3D.hide()
	
	if true:
		stm_instance.smash_the_mesh()
		
		var explode_callback = func(rb: RigidBody3D, _from):
			#rb.global_position.y += 45
			GlobalGame.player.global_position = rb.global_position 
			rb.linear_velocity = vel
			
			rb.scale = rb.scale*3#Vector3(3, 3, 3)
			print("boxer")
			rb.apply_impulse(-rb.global_position.normalized() * Vector3(1, -1, 1) * 1.5)
		
		stm_instance.chunks_iterate(explode_callback)
		print("boxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx broe")

func get_destroyed():
	#do_break($STMMesh1)
	do_break($STMMesh2)
	
	AudioManager.play_sfx("point")
	AudioManager.play_sfx("click")
	
	var user = GlobalGame.player
	user.get_node("Camera/LeanPivot/MainCamera/Weapons_Manager").pickup_ammo(weapon)
	
	print("ammo picked")
	
		
	#queue_free()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if label3D:
		label3D.rotation.y += .5*delta
	pass
