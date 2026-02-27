@tool
extends EditorPlugin

const Spawner2D = preload("res://addons/spawner/spawner_2d/spawner_2d.gd")
const Spawner3D = preload("res://addons/spawner/spawner_3d/spawner_3d.gd")

func _enter_tree() -> void:
	# Add custom node types to the editor
	add_custom_type(
		"Spawner2D",
		"Marker2D",
		Spawner2D,
		preload("res://addons/spawner/spawner_2d/spawner_2d_icon.svg")
	)
	
	add_custom_type(
		"Spawner3D",
		"Marker3D",
		Spawner3D,
		preload("res://addons/spawner/spawner_3d/spawner_3d_icon.svg")
	)

func _exit_tree() -> void:
	# Remove custom node types from the editor
	remove_custom_type("Spawner2D")
	remove_custom_type("Spawner3D")
