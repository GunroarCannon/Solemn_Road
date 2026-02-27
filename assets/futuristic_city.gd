@tool
extends EditorScenePostImport

func _post_import(scene):
	iterate(scene)
	return scene

func iterate(node):
	if node == null:
		return
	print("node...")
	if node is MeshInstance3D:
		# This creates the "Trimesh" collision perfectly aligned to the mesh
		print("Success")
		node.create_trimesh_collision()
		
	for child in node.get_children():
		iterate(child)
