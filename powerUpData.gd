extends Resource
class_name PowerUp  # This makes it show up in Godot's menus

@export var name: String
@export var description: String;
@export var icon: Texture2D
@export var set_key : String
@export var set_value : bool
@export var add_key: String
@export var add_value: float

func applyEffect(target):	
	pass


#I want car themed power ups (3 ideas each) for these powerups:
#quicker reload time, higher knockback from gun, melee deals more damage, gun deals more damage, faster sprint speed, faster movement, jump higher, flashlight deals more damage, brighter flashlight, deal more damage if in air, melee deals more knockbakc, increase melee range, move faster when health is low, deal more damage when health is low, more health , ammo drop rate up, can run and shoot, silent shotgun
