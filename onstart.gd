extends Node3D # Or whatever your Main Node is
@onready var FallThreshold = $FallThreshold

func _ready() -> void:
	# Find the player node (adjust the path to where your player is)
	var player_node = $Player_Character
	
	# Store it in the Global singleton
	GlobalGame.player = player_node
	print("player ", player_node.get("sprint_speed"))
	
	print("Player registered to Global system: ", GlobalGame.player)
	Optimizer.optimize_scene(self)
	
	get_tree().create_timer(.4).timeout
	GlobalGame.starting_point = player_node.global_position

func _process(delta: float) -> void:
	var pl = GlobalGame.player
	if pl and FallThreshold:
		if pl.global_position.y < FallThreshold.global_position.y:
			print("Collision mask nulled.")
			#pl.collison_mask = 9
			pl.get_hit(pl.health*2)
