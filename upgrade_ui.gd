extends Control
signal upgrade_selected(slot : int)

@onready var buttons_hbox = $MainMargin/VBoxContainer/ButtonsHBox
@export var powerups: EffectLibrary

func _ready():
	var lis = EffectLibrary.new().effect_list.duplicate()
	var power1: String
	var power2: String
	
	var pos1 = randi_range(0, lis.size()-1)
	power1 = lis[pos1]
	lis.remove_at(pos1)
	power2 = lis[randi_range(0, lis.size()-1)]
		
	buttons_hbox.get_child(0).pressed.connect(func(): upgrade_selected.emit(1))
	buttons_hbox.get_child(1).pressed.connect(func(): upgrade_selected.emit(2))
	#buttons_hbox.get_child(2).pressed.connect(func(): upgrade_selected.emit(3))
	set_upgrade_info(buttons_hbox.get_child(1), load(power1)) 
	set_upgrade_info(buttons_hbox.get_child(0), load(power2)) 
	#{
		#"name": "Infra Red Torch",
		#"description": "Turns your torch infrared"
	#})

func set_upgrade_info(button : Button, upgrade : Resource):
	
	var name : Label = button.get_node("Glow/Name")
	var desc : Label = button.get_node("Glow/Description")
	var icon : TextureRect = button.get_node("Glow/Icon")
	
	name.text = upgrade.get("name")
	desc.text = upgrade.get("description")
	icon.texture = upgrade.get("icon")
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	
	button.powerup = upgrade
	
	
func apply_powerup(user: Player, upgrade: PowerUp):
	print("upgrade name: ,", upgrade.name)
	if upgrade.set_key != null:
		print("upgrade set ", upgrade.set_key)
		user.set(upgrade.set_key, upgrade.set_value)
	
	if upgrade.add_key != null and upgrade.add_value != 0:
		print("upgrade, adding ", upgrade.add_key, upgrade.add_value)
		user.set(upgrade.add_key, user.get(upgrade.add_key)+upgrade.add_value)
	
	var upgradeContainer =  GlobalGame.player.get_node("CanvasLayer/StatsMarginContainer/VBoxContainer/UpgradesHBoxContainer")
	var tex: TextureRect = TextureRect.new()
	assert(tex)
	
	tex.texture = upgrade.icon
	tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	upgradeContainer.add_child(tex)
	
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
