extends Node3D # or whatever the crawler root is

# This function is what the Animation track will call
func trigger_melee():
	# This sends the command up to the Monster script
	if true:
		owner.trigger_melee_check()
		
