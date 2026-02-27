extends Node3D

# Drag the AnimationPlayer from the tree into the script while holding Ctrl
@onready var anim_player: AnimationPlayer = $AnimationPlayer 

func _ready():
	# Play by name (the name is the same as it was in Blender)
	var anim = $AnimationPlayer.get_animation("Slow Mvt")
	anim.loop_mode = Animation.LOOP_LINEAR
	anim_player.play("Slow Mvt") 
