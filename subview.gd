extends Node3D
@onready var olight = $OmniLight3D

var chosen_option;

# Break the mesh when you press the SPACE key
func _input(event: InputEvent) -> void:
	# Check if the event is a key press
	var key_event = event as InputEventKey
	#print("9999999999hey9999999999999",key_event,KEY_SPACE)
	
	# Reference to the STM instance (ensure this matches the name in your scene tree)
	
	var stm_instance : STMCachedInstance3D = get_node("STMCachedInstance3D")

	# Return if STM instance or key event is invalid, or the key is not SPACE
	if !stm_instance or !key_event or key_event.keycode != KEY_ENTER:
		#print("99999999999nah")
		if key_event:
			pass#rint("999999999p  ",key_event.keycode)
		else:
			pass#rint("9999999999kol")
		return

func do_break():
	print("neeeeeee999999999999eeeeeee")
	var body : StaticBody3D = get_node("StaticBody3D")
	body.queue_free()
	
	var light = $OmniLight3D
	var light_tweener = get_tree().create_tween()
	light_tweener.tween_property(light, "light_energy", 0, .6)
	
	var stm_instance : STMCachedInstance3D = get_node("STMCachedInstance3D")

	# Break the mesh when SPACE is pressed
	if true :
		print("999999 doing")
		stm_instance.smash_the_mesh()
		print("999999900000000000000000000000")
		#get_node("crawler/Sketchfab_Scene2").queue_free()
	
	# Apply an "explode" impulse to each fragment/chunk when SPACE is released
	#elif key_event.is_released():
		

		# Define a callback to apply an impulse to a rigid body chunk
		var explode_callback = func(rb: RigidBody3D, _from):
			#rb.global_position.y += 45
			rb.scale = rb.scale#Vector3(3, 3, 3)
			#rb.apply_impulse(-rb.global_position.normalized() * Vector3(1, -1, 1) * 5.0)
		
		# Apply the callback to each chunk of the mesh
		stm_instance.chunks_iterate(explode_callback)


func Hit_Successful(damage, _dir, _pos, attacker = null, knockback_arg = null):
	print("Heyyyyyyyyyyyyyyyyyyyyyyyyyyyyy")
	if attacker:
		print("yedssssssssssssss",attacker, GlobalGame.player)
		if attacker == GlobalGame.player and chosen_option:
			var knockback_dir = (global_position - attacker.global_position).normalized()
			knockback_dir.y = -0.5
			print(knockback_dir,"yedssss")
			attacker.knockback_velocity = attacker.knockback_velocity + knockback_dir * 20
			
			var collider : StaticBody3D = get_node("StaticBody3D")
			collider.set_collision_layer_value(1, false)
			collider.set_collision_layer_value(3, true)
			
			$SubViewport/UpgradePanel.apply_powerup(attacker, chosen_option.powerup)

			do_break()
	else:
		print("nullllllllllllllllll")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	olight.light_energy = 0
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var max_energy = 2
	var max_distance = 5
	var min_distance = 3
	var dis: float = global_position.distance_to(GlobalGame.player.global_position)
	
	# smoothstep returns a value between 0 and 1 with a nice S-curve
	var t = smoothstep(max_distance, min_distance, dis)
	
	olight.light_energy = t * max_energy


func deselectOption(option):
	var rect : CanvasItem = option.get_node("Glow")
	var m : ShaderMaterial = rect.get_material()
	
	var tweener = get_tree().create_tween()
	var light: Light3D = $Light1
	if option == $SubViewport/UpgradePanel/MainMargin/VBoxContainer/ButtonsHBox/UpgradeButton2:
		light = $Light2
	tweener.tween_property(light, "light_energy", 0, .7)
	
	#m.set_shader_parameter("neon_color", Color(1,1,0))

func selectOption(option):
	var rect : CanvasItem = option.get_node("Glow")
	var m : ShaderMaterial = rect.get_material()
	
	var tweener = get_tree().create_tween()
	var light: Light3D = $Light1
	if option == $SubViewport/UpgradePanel/MainMargin/VBoxContainer/ButtonsHBox/UpgradeButton2:
		light = $Light2
	tweener.tween_property(light, "light_energy", 1, .7)
	
	#m.set_shader_parameter("neon_color", Color(1,0,0))
	
	


func _on_option_2_body_entered(body: Node3D) -> void:
	print("eeeeeeeeeee888888888")
	if body != GlobalGame.player:
		return
		
	if chosen_option:
		deselectOption(chosen_option)
	chosen_option = $SubViewport/UpgradePanel/MainMargin/VBoxContainer/ButtonsHBox/UpgradeButton2
	selectOption(chosen_option)


func _on_option_1_body_entered(body: Node3D) -> void:
	print("dddd8888888888888888")
	if body != GlobalGame.player:
		return
	print("8888888888888888")
	
	if false:
		var o = $SubViewport/UpgradePanel/MainMargin/VBoxContainer/ButtonsHBox/UpgradeButton2
		selectOption(o)
		return
		
	if chosen_option:
		deselectOption(chosen_option)
	chosen_option = $SubViewport/UpgradePanel/MainMargin/VBoxContainer/ButtonsHBox/UpgradeButton1
	selectOption(chosen_option)


func _on_option_2_body_exited(body: Node3D) -> void:
	if body != GlobalGame.player:
		return
	
	if false:
		var o = $SubViewport/UpgradePanel/MainMargin/VBoxContainer/ButtonsHBox/UpgradeButton1
		selectOption(o)
		return
		
	var option = $SubViewport/UpgradePanel/MainMargin/VBoxContainer/ButtonsHBox/UpgradeButton2
	
	if chosen_option == option:
		deselectOption(chosen_option)


func _on_option_1_body_exited(body: Node3D) -> void:
	if body != GlobalGame.player or true:
		return
	
	var option = $SubViewport/UpgradePanel/MainMargin/VBoxContainer/ButtonsHBox/UpgradeButton1
	
	if chosen_option == option:
		deselectOption(chosen_option)
