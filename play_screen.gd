extends Control

var play_activated = false
@onready var normal_button := $Panel/MarginContainer/PlayContainer/HBoxContainer/MarginContainer3/NormalButton
@onready var hardcore_button := $Panel/MarginContainer/PlayContainer/HBoxContainer/MarginContainer2/StakeButton
@onready var play_button := $Panel/MarginContainer/PlayContainer/MarginContainer2/PlayButton
@onready var description := $Panel/MarginContainer/PlayContainer/MarginContainer/DescriptionLabel

var main_game = preload("res://node_3d.tscn")

var normal_text := """Test your skills, and your luck.
See how far down the road
you can make it..."""

var hardcore_text = """STAKE Solana and win the pool if you're in
the top 3 by the end of the day.
Risky but addictive."""
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	description.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	description.text = "Choose a mode of play\n..."
	
	_on_normal_button_button_down()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func activate_play():
	play_activated = true
	GlobalGame.play_type = GlobalGame.PlayType.CLASSIC
	play_button.add_theme_color_override("font_color", Color(210, 7, 89, 200))
	
	Effects.shake(description, 15, .4)
	
	

func _on_play_button_button_up() -> void:
	if not play_activated:
		return
	
	if GlobalGame.play_type == GlobalGame.PlayType.HARDCORE:
		description.set_text("Still in BETA, coming soon. \nNot enough players for pool.")
		#_on_join_button_pressed()
		return
		
	MySceneManager.change_to_packed(main_game)
	
	
	pass # Replace with function body.


func _on_stake_button_button_down() -> void:
	activate_play()
	description.text = hardcore_text
	GlobalGame.play_type = GlobalGame.PlayType.HARDCORE

	play_button.add_theme_color_override("font_color", Color("41090f"))
	pass # Replace with function body.
	
func _on_join_button_pressed():
	var bet_amount = 0.1 # Or get from a LineEdit: float($AmountInput.text)
	
	# 1. UI Feedback
	var button: Button = play_button
	var info: Label = description
	
	button.disabled = true
	info.text = "Confirming in Wallet..."
	
	# 2. Call the Global Manager and WAIT
	var result = await GlobalGame.join_game_on_chain(bet_amount)
	
	# 3. Handle the response
	if result != null and result.is_successful():
		info.text = "Success! Transaction: " + result.get_signature().left(8) + "..."
		print("Player joined successfully. Signature: ", result.get_signature())
		# Proceed to start the game level here
	else:
		# 4. Handle Errors
		var error_msg = "Transaction Failed"
		if result:
			error_msg = result.get_error_message()
		
		info.text = "Error: " + error_msg
		button.disabled = false # Re-enable so they can try again


func _on_normal_button_button_down() -> void:
	activate_play()
	description.text =  normal_text
	pass # Replace with function body.
