extends Node

# Default transition
const DEFAULT_FADE = preload("res://addons/scene_manager/fade_to_black.tres")

## Flexible File Change
func change_to_file(path: String, trans: Resource = DEFAULT_FADE,  props: Dictionary = {}):
	await _execute_with_transition(trans, func(): 
		SceneManager.change_scene_to_file(path, props)
	)

## Flexible Packed Change
func change_to_packed(packed: PackedScene, trans: Resource = DEFAULT_FADE, props: Dictionary = {}):
	await _execute_with_transition(trans, func(): 
		SceneManager.change_scene_to_packed(packed, props)
	)

## Core Logic: Swaps the scene only when the transition hits the "middle" (finished signal)
func _execute_with_transition(trans_res: Resource, change_call: Callable):
	process_mode = PROCESS_MODE_DISABLED
	
	# Start the specific transition resource provided
	var transition_task = SceneManager.transition_start(trans_res)
	await transition_task.finished # Wait for screen to be obscured
	
	# Perform the actual scene swap
	change_call.call()
	
	process_mode = PROCESS_MODE_INHERIT
