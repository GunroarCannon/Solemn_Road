extends Control

# Using unique names or direct paths based on your screenshot
@onready var blood_rect: ColorRect = $CanvasLayer/ColorRect
@onready var game_over_group: Control = $CanvasLayer/VBoxContainer2/Label
@onready var death_rect: ColorRect = $CanvasLayer/ColorRect2
@onready var died_by : Label = $CanvasLayer/VBoxContainer2/VBoxContainer/DiedByLabel
@onready var click_to_retry : Label = $CanvasLayer/VBoxContainer2/VBoxContainer/RetryLabel
@onready var travelled_distance : Label = $CanvasLayer/VBoxContainer2/MarginContainer/HBoxContainer/TravelledDistanceLabel


var health_tween: Tween

var has_died = false
var click_sounds = ["punch_1", "punch_2", "punch_3", "click"]

var distance_travelled = 0
var old_distance_travelled = 0

func set_travelled_distance(num: float):
	
	travelled_distance.set_text("Distance Travelled: "+str(num))
	AudioManager.play_sfx(click_sounds.pick_random())
	
func _ready() -> void:
	# 1. Reset everything to "Alive and Healthy" state
	blood_rect.material.set_shader_parameter("health_factor", 1.0)
	game_over_group.hide()
	death_rect.color.a = 0 # Ensure game over overlay is transparent
	
	died_by.hide()
	click_to_retry.hide()
	travelled_distance.hide()
	
	# 2. Make sure this overlay doesn't block your mouse clicks during gameplay
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Call this for damage, healing, or health regen
func update_health(current_hp: float, max_hp: float):
	var percent = clamp(current_hp / max_hp, 0.0, 1.0)
	
	# Smoothly slide the shader values
	if health_tween: health_tween.kill()
	health_tween = create_tween()
	
	health_tween.tween_property(blood_rect.material, "shader_parameter/health_factor", 
		percent, 0.4).set_trans(Tween.TRANS_SINE)
	
	
	# Trigger Game Over if health hits zero
	if percent <= 0:
		trigger_game_over()

## Separate logic for the "Death" sequence
func trigger_game_over():
	if has_died:
		return
	
	has_died = true
	
	var death_tween = create_tween()
	
	# Fade to black over 3 seconds
	death_tween.tween_property(death_rect, "color:a", 0.7, 5.0)
	
	await get_tree().create_timer(1).timeout
	game_over_group.show()
	GlobalGame.player.shakeCamera()
	
	# Optional: You can emit a signal here to tell the player script to disable input
	print("Player has died.")
	await get_tree().create_timer(1).timeout
	
	died_by.show()
	GlobalGame.player.shakeCamera()
	
	await get_tree().create_timer(2 ).timeout
	
	travelled_distance.show()
	click_to_retry.show()
	GlobalGame.player.shakeCamera()
	
	var total_distance = GlobalGame.player.start_pos.x-GlobalGame.player.global_position.x
	total_distance *= 3
	
	Scoreboards.upload_score(total_distance, GlobalGame.wallet_address, GlobalGame.play_type == GlobalGame.PlayType.HARDCORE)
	var tween = create_tween()
	tween.tween_property(self, "distance_travelled", total_distance, 2)

func _process(delta: float) -> void:
	if old_distance_travelled != distance_travelled:
		set_travelled_distance(distance_travelled)
		old_distance_travelled = distance_travelled
		
## TEST FUNCTION: Press 'K' to test damage in-game
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		update_health(0,1)
