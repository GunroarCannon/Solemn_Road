extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func Hit_Successful(damage, _dir, _pos, attacker = null, knockback_arg = null):
	print("hey")
	return get_parent_node_3d().Hit_Successful(damage, _dir, _pos, attacker, knockback_arg)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
