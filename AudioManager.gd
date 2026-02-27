extends Node

signal loud_sound
# --- Configuration ---
@export var sfx_library: Dictionary = {
	"pain": preload("res://audio/pains.wav"),
	"loud_pain": preload("res://audio/painb.wav"),
	
	"snarls_deep": preload("res://audio/monster-snarls.ogg"),
	"snarls": preload("res://audio/zombie_noises.mp3"),
	
	"footstep": preload("res://audio/jute-dh-steps/stepdirt_1.wav"),
	"footstep_2": preload("res://audio/jute-dh-steps/stepdirt_2.wav"),
	
	"woosh": preload("res://audio/air_move.wav"),
	
	"point": preload("res://audio/residue-sfx/points.ogg"),
	
	"breathe": preload("res://audio/Mp3/Breath Scared/Breath_Scared_00.mp3"),
	"fast_breathe": preload("res://audio/Mp3/Breath Scared/Breath_Scared_07.mp3"),
	"breath_tired": preload("res://audio/Mp3/Breath Scared/Breath_Scared_16.mp3"),
		
	"reload_2": preload("res://audio/ShotgunSounds/Rack.mp3"),
	"reload": preload("res://audio/mike_koenig-shotgun/Shotgun-SoundBible.com-862990674.wav"),
	"shoot": preload("res://audio/mike_koenig-shotgun/10 Guage Shotgun-SoundBible.com-74120584.wav"),
	
	"punch_1": preload("res://audio/punch_1.wav"),
	"punch_2": preload("res://audio/punch_2.wav"),
	"punch_3": preload("res://audio/punch_3.wav"),
	
	"player_scream": preload("res://audio/Mp3/Scream_Male_02.mp3"),
	"loud_scream": preload("res://audio/Mp3/Monster_03.mp3"),
	"loud_death": preload("res://audio/deathb.wav"),
	"high_death": preload("res://audio/deathd.wav"),
	
	"click": preload("res://audio/RPGSounds_Kenney/chop.ogg")
}

var sfx_pool_size = 12
var sfx_players: Array[AudioStreamPlayer] = []
var music_players: Array[AudioStreamPlayer] = []
var current_music_index = 0


func _ready():
	# Initialize SFX Pool
	for i in sfx_pool_size:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_players.append(p)
	
	# Initialize Music Players (Two for crossfading)
	for i in 2:
		var p = AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -80 # Start muted
		add_child(p)
		music_players.append(p)
# Add this to your AudioManager.gd

## Starts a looping sound and returns the player so you can stop it later
func play_looping_sfx(sfx_name: String, pitch_min := 0.9, pitch_max := 1.1) -> AudioStreamPlayer:
	if not sfx_library.has(sfx_name):
		print("audio bad", sfx_name)
		return null
		
	print("audio play", sfx_name)
	var p = AudioStreamPlayer.new()
	p.stream = sfx_library[sfx_name]
	p.bus = "SFX"
	p.pitch_scale = randf_range(pitch_min, pitch_max)
	p.volume_db = -5
	add_child(p)
	p.play()
	return p

## Stops and deletes a looping sound
func stop_looping_sfx(player: AudioStreamPlayer, fade_out: float = 0.5):
	if player == null: return
	
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80.0, fade_out)
	tween.tween_callback(player.queue_free)
	
# --- SFX Logic ---
func play_sfx(sfx_name: String, pitch_min := 0.9, pitch_max := 1.1, is_loud: Node = null):
	if not sfx_library.has(sfx_name):
		push_error("AudioManager: SFX name not found: " + sfx_name)
		return

	print("audio play", sfx_name)
	
	for p in sfx_players:
		if not p.playing:
			p.stream = sfx_library[sfx_name]
			p.pitch_scale = randf_range(pitch_min, pitch_max)
			p.play()
			p.volume_db = -5
			
			if is_loud:
				var source = is_loud
				loud_sound.emit(source.global_position)
				
			return p

# --- Music Logic (Fade & Crossfade) ---
func play_music(stream: AudioStream, fade_duration: float = 1.5):
	var old_player = music_players[current_music_index]
	
	# If same music is already playing, don't restart it
	if old_player.stream == stream and old_player.playing:
		return
		
	# Switch index to the "other" player
	current_music_index = (current_music_index + 1) % 2
	var new_player = music_players[current_music_index]
	
	new_player.stream = stream
	new_player.volume_db = -80
	new_player.play()
	
	# Create Crossfade Tween
	var tween = create_tween().set_parallel(true)
	# Fade OUT old
	tween.tween_property(old_player, "volume_db", -80.0, fade_duration)
	# Fade IN new
	tween.tween_property(new_player, "volume_db", 0.0, fade_duration)
	
	# Stop old player after fade
	tween.set_parallel(false)
	tween.tween_callback(old_player.stop)

func fade_out_current(duration: float = 1.0):
	var player = music_players[current_music_index]
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80.0, duration)
	tween.tween_callback(player.stop)
	

# Inside AudioManager.gd

# Tracks active players: { "wind": AudioStreamPlayer, "birds": AudioStreamPlayer }
var active_ambience: Dictionary = {}

func play_ambience(key: String, stream: AudioStream, volume: float = -15.0, fade_duration: float = 2.0):
	# 1. If this specific ambience is already playing, just update volume if needed
	if active_ambience.has(key):
		var existing_p = active_ambience[key]
		if existing_p.stream == stream:
			create_tween().tween_property(existing_p, "volume_db", volume, fade_duration)
			return

	# 2. Create a new player for this specific key
	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "Music" 
	p.volume_db = -10.0
	add_child(p)
	
	active_ambience[key] = p
	p.play()

	# 3. Fade in
	var tween = create_tween()
	tween.tween_property(p, "volume_db", volume, fade_duration)

func stop_ambience(key: String, fade_duration: float = 2.0):
	if active_ambience.has(key):
		var p = active_ambience[key]
		active_ambience.erase(key) # Remove from tracking immediately
		
		var tween = create_tween()
		tween.tween_property(p, "volume_db", -80.0, fade_duration)
		tween.tween_callback(p.queue_free) # Clean up memory when done

func stop_all_ambience(fade_duration: float = 2.0):
	for key in active_ambience.keys():
		stop_ambience(key, fade_duration)

## Returns -80dB (silent) if out of range.
func get_3d_volume(listener: Vector3, source: Vector3, max_distance: float = 20.0) -> float:
	var dist = listener.distance_to(source)
	
	if dist >= max_distance:
		return -80.0 # Muted
		
	# Calculate a linear percentage (0.0 to 1.0) of how close it is
	var linear_volume = 1.0 - (dist / max_distance)
	
	# Godot's built-in math function converts linear (0-1) to Decibels
	return linear_to_db(linear_volume)

# Inside AudioManager.gd

# --- 3D SFX (Fire and Forget) ---
func play_sfx_3d(sfx_name: String, position: Vector3, max_dist: float = 20.0):
	if not sfx_library.has(sfx_name): return

	var p = AudioStreamPlayer3D.new()
	p.stream = sfx_library[sfx_name]
	p.bus = "SFX"
	p.position = position
	p.max_distance = max_dist
	
	# add_child(p) here makes it relative to the manager (world origin).
	# For 3D positional audio, it's often better to add it to the current scene tree
	get_tree().current_scene.add_child(p) 
	
	p.play()
	p.finished.connect(p.queue_free)


# --- 3D Looping Music/Ambience (Attached to a Source) ---
## Attaches a 3D sound to a moving object (like an enemy or a radio)
func play_attached_sfx(sfx_name: String, target_node: Node3D,  pitch_min := 0.9, pitch_max := 1.1, max_dist: float = 30.0) -> AudioStreamPlayer3D:
	if not sfx_library.has(sfx_name): return null
	
	var p = AudioStreamPlayer3D.new()
	p.stream = sfx_library[sfx_name]
	p.bus = "Music"
	p.max_distance = max_dist
	
	p.pitch_scale = randf_range(pitch_min, pitch_max)
	
	# IMPORTANT: By adding it as a child of the target_node, 
	# Godot automatically moves the audio source whenever the target moves!
	target_node.add_child(p)
	p.play()
	
	return p
