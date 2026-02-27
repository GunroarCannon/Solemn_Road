extends Node

func optimize_scene(root: Node3D):
	_apply_to_meshes(root)

func _apply_to_meshes(node: Node):
	if node is MeshInstance3D:
		#Baking setup (uses pre baked LightmapGI)
		node.gi_mode = GeometryInstance3D.GI_MODE_STATIC #Enable lightmaps
		var nodee: MeshInstance3D = node;

		node.gi_lightmap_scale = 0.5 # low res for mobile performance
		
		printt("node optimized", node)
		
		#Render distance culling
		node.visibility_range_begin = 0.0
		node.visibility_range_end = 30.0
		node.visibility_range_begin_margin = 1.0
		node.visibility_range_end_margin = 2.0 #Anti flicker
		node.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		
	for child in node.get_children():
			_apply_to_meshes(child)
			
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
