extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func Hit_Successful(dmg, dir, pos, hitter, knockback):
	print("boxxs")
	if hitter == GlobalGame.player:
		var parent : Node3D = get_parent()
		parent.get_collected(hitter)
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
