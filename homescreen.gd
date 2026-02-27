extends Control

@onready var play_scene = preload("res://play_screen.tscn")
@onready var title = $Panel/MarginContainer2/Label

func create_popup(prompt_text: String = "Enter your name:", button_text: String = "Done"):
	# 1. Create a CanvasLayer so it's always on top of the game world
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	
	
	# 2. Create a CenterContainer to force everything to the middle
	var center_node = CenterContainer.new()
	center_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) # Fill the whole screen
	canvas.add_child(center_node)
	
	# 3. Create the Main Panel
	var panel = PanelContainer.new()
	center_node.add_child(panel)
	
	# Styling: Black background, Red border
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color.BLACK
	stylebox.border_color = Color.RED
	stylebox.set_border_width_all(2)
	stylebox.set_content_margin_all(15)
	panel.add_theme_stylebox_override("panel", stylebox)
	
	# 4. Create the VBoxContainer
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# 5. UI Elements (Label, Input, Button)
	var label = Label.new()
	label.text = prompt_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme = load("res://button_theme.tres")
	vbox.add_child(label)
	
	var input = LineEdit.new()
	input.custom_minimum_size.x = 200
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.theme = load("res://button_theme.tres")
	vbox.add_child(input)
	
	var btn = Button.new()
	btn.text = button_text
	btn.theme = load("res://button_theme.tres")
	vbox.add_child(btn)
	
	# 6. Logic & Cleanup
	var on_submit = func():
		print("User entered: ", input.text)
		canvas.queue_free() # Deletes the canvas and everything inside it
		
	btn.pressed.connect(on_submit)
	input.text_submitted.connect(func(_text): on_submit.call())
	
	input.grab_focus()
# Called when the node enters the scene tree for the first time.
func create_styled_popup(title_text: String = "WARNING", descriptor: String = "Are you sure?", cancel_text: String = "Cancel"):
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)

	# 1. Create Panel & Center it immediately
	var panel = PanelContainer.new()
	canvas.add_child(panel) 
	
	var screen = get_viewport().get_visible_rect().size
	panel.custom_minimum_size = Vector2(screen.x * 0.5, screen.y * 0.6)
	
	# Reliable Godot 4 centering
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)

	# 2. Gritty Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.02)
	style.border_color = Color(0.7, 0.1, 0.1)
	style.set_border_width_all(8)
	style.skew = Vector2(0.02, 0)
	panel.add_theme_stylebox_override("panel", style)

	# 3. Layout
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_all", 30)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15) # Spacing between elements
	margin.add_child(vbox)

	# 4. TITLE (Slightly bigger)
	var title = Label.new()
	title.text = title_text
	title.theme = load("res://button_theme.tres")
	title.add_theme_font_size_override("font_size", 45) # Bigger title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# This adds the extra space specifically under the heading
	title.add_theme_constant_override("margin_bottom", 40)
	vbox.add_child(title)

	# 5. MAIN DESCRIPTOR (Smaller text)
	var label = Label.new()
	label.text = descriptor
	label.theme = load("res://button_theme.tres")
	label.add_theme_font_size_override("font_size", 28) # Reduced size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	# 6. Spacer (Pushes button to bottom)
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# 7. CANCEL BUTTON (Using Theme)
	var btn_cancel = Button.new()
	btn_cancel.text = cancel_text
	btn_cancel.theme = load("res://button_theme.tres") # Uses your theme now
	btn_cancel.custom_minimum_size = Vector2(260, 80)
	btn_cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_cancel)

	# 8. Start Effects
	# Pulse the Title and the Panel border
	Effects.pulse(title, 0.8) 
	Effects.pulse(panel, 1.2)

	btn_cancel.pressed.connect(func(): canvas.queue_free())
func _ready() -> void:
	Effects.pulse(title, 13)
	get_tree().create_timer(.5).timeout
	if not DataSaver.has_data("name	"):
		create_popup()
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_play_button_up() -> void:
	print("[HOMESCREEN] Changing to play button")
	MySceneManager.change_to_packed(play_scene)
	print("[HOMESCREEN] changed play button")
	#get_tree().change_scene_to_packed(play_scene)

	pass # Replace with function body.


# Inside your GameUI.gd or Player.gd
func _on_join_pressed(amount_sol: float):
	# Reach down through the singleton to find your specific program node
	var anchor = SolanaService.get_node("WalletService/SessionKeyManager/AnchorProgram")
	
	var lamports = int(amount_sol * 1_000_000_000)
	var state_pda = anchor.get_pda(["state"])
	var vault_pda = anchor.get_pda(["vault"])
	
	var accounts = {
		"player": SolanaService.wallet.get_pubkey(),
		"state": state_pda,
		"vault": vault_pda,
		"system_program": "11111111111111111111111111111111"
	}
	
	# Execute the on-chain move!
	anchor.rpc("join_game", [lamports], accounts)
func setup_game_on_chain():
	# 1. Get your program node
	var anchor = SolanaService.get_node("WalletService/SessionKeyManager/AnchorProgram")
	var pid_string = anchor.get_pid()
	var pid_pubkey = Pubkey.new_from_string(pid_string)

	# 2. Derive the 'state' PDA
	# In Godot SDK, we use Pubkey.new_pda_bytes([seeds], program_id)
	# The seeds must be PackedByteArrays
	var state_seeds = [ "state".to_utf8_buffer() ]
	var state_pda = Pubkey.new_pda_bytes(state_seeds, pid_pubkey)

	# 3. Define the accounts
	var accounts = {
		"state": state_pda,
		"treasurer": SolanaService.wallet.get_pubkey(),
		"system_program": Pubkey.new_from_string("11111111111111111111111111111111")
	}
	
	# 4. Call the RPC (The first argument is function name, second is arguments, third is accounts)
	anchor.rpc("initialize", [10], accounts)
	print("Initialize transaction sent for PDA: ", state_pda.to_string())
func _on_connect_wallet_button_up() -> void:# Defensive check: if SolanaService is Nil, it means it's not in Autoloads
	# 1. Get a reference to the WalletService node
	# Adjust this path if your SolanaService setup is different!
	var wallet_service = SolanaService.wallet
		
	if wallet_service == null:
		printerr("CRITICAL: WalletService not found in SolanaService autoload!")
		return


	# 3. Listen for the result
	if true:#not wallet_service.on_login_finish.is_connected(_on_login_finished):
		print("log connect")
		wallet_service.done_wallet = self
		wallet_service.on_login_success.connect(_on_login_finished)
		
	# 2. Detect Platform and Choose Login Method
	if OS.get_name() == "Windows" or OS.has_feature("editor"):
		print("PC detected: Using Generated Wallet for stability.")
		
		# Force the service to use generated mode
		wallet_service.use_generated = true
		
		# Call the internal function to create/load the local keypair
		wallet_service.login_game_wallet()
		#	setup_game_on_chain()
		
	elif OS.get_name() == "Android":
		print("Android detected: Launching Mobile Wallet Adapter.")
		
		# Ensure generated mode is OFF so it looks for a real wallet
		wallet_service.use_generated = false
		
		# This spawns the UI for the player to select Phantom/Solflare
		wallet_service.pop_adapter()
		
	else:
		# Fallback for Web/other platforms
		wallet_service.pop_adapter()

func done_wallet(s):
	return await _on_login_finished(s)
	
func _on_login_finished(success: bool):
	print("logged in ?", success)
	if success:
		var pubkey = SolanaService.get_node("WalletService").get_pubkey().to_string()
		print("Login Successful! Address: ", pubkey)
		var signature;# = await SolanaService.wallet.request_airdrop()
		
		if signature != "":
			print("airdrop successful!")
		else:
			print("Airdrop failed. Try again in a minute.")
		# Proceed to LootLocker or Game Scene
	else:
		print("Login failed or cancelled.")

func _on_about_button_up() -> void:
	create_styled_popup("This is about the stuff fir the stuff", "okay")


func _on_leaderboard_button_up() -> void:
	load("res://leaderboard.tscn")
	pass # Replace with function body.


func _on_exit_button_up() -> void:
	pass # Replace with function body.
