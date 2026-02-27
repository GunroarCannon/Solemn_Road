extends GPUParticles3D

var time = 0;

func remove_light():
	var tween = get_tree().create_tween()
	tween.tween_property($Light, "light_energy", 0, lifetime*.5)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var tween = get_tree().create_tween()
	tween.tween_property($Light, "light_energy", 1, lifetime*.5)
	tween.tween_callback(remove_light)
	print("banana",lifetime)
	global_basis


	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta;
	if time >= lifetime:
		print("banana died",global_position)
		queue_free()
	pass
