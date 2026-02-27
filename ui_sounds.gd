extends Node

# Load your gritty sound effect here
var click_sound = preload("res://audio/RPGSounds_Kenney/metalClick.ogg")
var shotgun_sound =  preload("res://audio/mike_koenig-shotgun/Pump Shotgun-SoundBible.com-1653268682.wav")
var reload_sound = preload("res://audio/ShotgunSounds/Rack.mp3")

func _ready():
	# This listens for any new node entering the game
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
	# If the new node is a Button (or BaseButton like TextureButton)
	if node is BaseButton:
		node.pressed.connect(_on_button_pressed.bind(node))

func _on_button_pressed(button: BaseButton):
	# 1. Play the sound
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.stream = click_sound
	audio_player.play()
	
	# Clean up the audio player when done
	audio_player.finished.connect(audio_player.queue_free)

	# 2. Run your "certain function"
	_global_button_logic(button)

func _global_button_logic(button: BaseButton):
	# Subtle screen shake or button wobble
	button.rotation_degrees = randf_range(-2, 2)
	# Reset it after a split second
	get_tree().create_timer(0.1).timeout.connect(func(): button.rotation_degrees = 0)
	
	print("Gritty Logic Triggered for: ", button.name)
	# You can add a small "kick" or "punch" effect here
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.05)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.05)
