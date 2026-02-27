extends MeshInstance3D
# Assumes Godot 4.x for some features, but compatible with 3.x by replacing 'match' with if-elif chains if needed.
# SpawnMesh should be a MeshInstance3D with a BoxMesh (or similar rectangular mesh).
# Creatures are assumed to be PackedScene resources (e.g., "res://creatures/MyCreature.tscn").
# Formations are spawned on the TOP surface of the SpawnMesh (fixed Y, vary X/Z).
# Global coordinates are used for positioning.

# Example spawn table as per your notes. This is a dictionary where keys are levels (int),
# and values are arrays of spawn configurations (dictionaries).
# Each config has: spawn_id_name (string for identification), percentage (0-100 chance to spawn this group),
# weight (for weighted selection if multiple), max (max amount for this group).

@export_category("Spawn Data")
@export var spawn_level : int = 5
@export var spawn_table : Dictionary = {
		"crawlers":{
			"weight":40,
			"level": 2,
			"max": 3,
			"min": 1,
			"formation": "scatter",  # Example formation
			"creature_name": "res://crawler_monster.tscn",  # Path to PackedScene
			"animations": []  # Array of animation names or dicts, if needed (ignored for now)
		},
		"gaurds": {
			"weight": 10,
			"level": 2,
			"formation": "guard",
			"creature_name": "res://angel_follower_statue.tscn",
			"animations": []
		}
}

"""
function lume.weightedchoice(t)
  local sum = 0
  for _, v in pairs(t) do
	-- assert(v >= 0, "weight value less than zero")
	sum = sum + v
  end
  assert(sum ~= 0, "all weights are zero")
  local rnd = lume.random(sum)
  for k, v in pairs(t) do
	if rnd < v then return k end
	rnd = rnd - v
  end
end"""

func weighted_choice(data : Dictionary):
	var sum = 0
	for i in data:
		sum += data[i]["weight"]
		
	assert(sum != 0, "all weights are zero")
	var rnd = randi_range(0, sum-1)
	
	for ii in data:
		var i = data[ii]
		if rnd < i["weight"]:
			return i
		rnd -= i["weight"]
	
	push_error("weighted choice failed!!")
		
	
# Helper to get the global AABB of the spawn mesh
func get_global_aabb(mesh: MeshInstance3D) -> AABB:
	var local_aabb = mesh.get_aabb()
	return mesh.global_transform * local_aabb

# Get a random point on the top surface (fixed Y, random X/Z within bounds)
func get_random_point_on_top(mesh: MeshInstance3D) -> Vector3:
	var aabb = get_global_aabb(mesh)
	var top_y = aabb.end.y  # Assuming Y-up, top is max Y
	var x = randf_range(aabb.position.x, aabb.end.x)
	var z = randf_range(aabb.position.z, aabb.end.z)
	return Vector3(x, top_y, z)

# Get far left point on top (min X, random Z, top Y)
func get_far_left_point(mesh: MeshInstance3D, random_z: bool = true) -> Vector3:
	var aabb = get_global_aabb(mesh)
	var top_y = aabb.end.y
	var x = aabb.position.x
	var z = aabb.position.z + (aabb.size.z / 2.0)  # Center Z by default
	if random_z:
		z = randf_range(aabb.position.z, aabb.end.z)
	return Vector3(x, top_y, z)

# Get far right point on top (max X, random Z, top Y)
func get_far_right_point(mesh: MeshInstance3D, random_z: bool = true) -> Vector3:
	var aabb = get_global_aabb(mesh)
	var top_y = aabb.end.y
	var x = aabb.end.x
	var z = aabb.position.z + (aabb.size.z / 2.0)  # Center Z by default
	if random_z:
		z = randf_range(aabb.position.z, aabb.end.z)
	return Vector3(x, top_y, z)

# Get a point in a queue line (along Z, spaced evenly, at center X)
func get_queue_point(mesh: MeshInstance3D, index: int, total: int) -> Vector3:
	var aabb = get_global_aabb(mesh)
	var top_y = aabb.end.y
	var center_x = aabb.position.x + (aabb.size.x / 2.0)
	var spacing = aabb.size.z / float(total)  # Even spacing along Z
	var z = aabb.position.z + (spacing * index) + (spacing / 2.0)  # Center each in segment
	return Vector3(center_x, top_y, z)

func spawn_instance(instance, pos):
	
	instance.global_position = pos
	get_parent().add_child(instance)
	instance.set_deferred("global_position", pos)
	
	
	print(instance.global_position,"instance spawning",pos)

# Core spawn function as per notes
func spawn_creature(data: Dictionary):
	var spawn_mesh = self
	var creature_scene: PackedScene = load(data["creature_name"])
	if not creature_scene:
		print("Error: Failed to load creature scene: " + data["creature_name"])
		return

	var formation = data.get("formation", "simple")
	var amount = data.get("amount", 1)  # Default to 1, override for multi-formations
	
	print("Spawning ", data["creature_name"], " at formation <", formation, "> and amount ", amount, ".")
	var sp = false;
	match formation:
		"simple", "random":  # 'simple' alias for 'random'
			for i in range(amount):
				var pos = get_random_point_on_top(spawn_mesh)
				var creature = creature_scene.instantiate()
				creature.global_position = pos
				spawn_instance(creature, pos)
				sp = true
				# TODO: Play animations if needed: creature.play_animation(data["animations"][0]) or similar

		"scatter":  # Multiple random points on top
			for i in range(amount):
				var pos = get_random_point_on_top(spawn_mesh)
				var creature = creature_scene.instantiate()
				creature.global_position = pos
				spawn_instance(creature,pos)
				sp = true
			

		"guard":  # Two creatures: far left and far right, each with random Z
			# Amount ignored/fixed at 2 for guard
			var left_pos = get_far_left_point(spawn_mesh, true)  # Random Z
			var left_creature = creature_scene.instantiate()
			left_creature.global_position = left_pos
			spawn_instance(left_creature,left_pos)

			var right_pos = get_far_right_point(spawn_mesh, true)  # Independent random Z
			var right_creature = creature_scene.instantiate()
			right_creature.global_position = right_pos
			spawn_instance(right_creature,right_pos)
			return true

		"queue":  # Multiple in a line along Z, behind each other
			for i in range(amount):
				var pos = get_queue_point(spawn_mesh, i, amount)
				var creature = creature_scene.instantiate()
				creature.global_position = pos
				spawn_instance(creature,pos)
				sp = true

		# Additional formation types I added for variety:
		"circle":  # Spawn in a circle around the center of the top surface
			var aabb = get_global_aabb(spawn_mesh)
			var top_y = aabb.end.y
			var center = aabb.position + (aabb.size / 2.0)
			center.y = top_y
			var radius = min(aabb.size.x, aabb.size.z) / 3.0  # Arbitrary radius
			for i in range(amount):
				var angle = (2 * PI * i) / amount
				var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
				var pos = center + offset
				var creature = creature_scene.instantiate()
				creature.global_position = pos
				spawn_instance(creature,pos)
				sp = true

		"line":  # Spawn in a straight line along X, at center Z
			var aabb = get_global_aabb(spawn_mesh)
			var top_y = aabb.end.y
			var center_z = aabb.position.z + (aabb.size.z / 2.0)
			var spacing = aabb.size.x / float(amount)
			for i in range(amount):
				var x = aabb.position.x + (spacing * i) + (spacing / 2.0)
				var pos = Vector3(x, top_y, center_z)
				var creature = creature_scene.instantiate()
				creature.global_position = pos
				spawn_instance(creature,pos)
				sp = true
				
			return amount > 0
		

		_:
			print("Unknown formation: " + formation)
			return false
		
	return sp

func _spawn(spawnable : Dictionary) -> int:
		# Determine amount: random between 1 and max (weight not used here, but could for probability)
		var amount : int = randi_range(spawnable.get("min", 1), spawnable.get("max", 1))
		var data = spawnable.duplicate()  # Copy to avoid modifying original
		data["amount"] = amount
		if spawn_creature(data):
			return amount
		else:
			return 0
		
# Example function to spawn for a whole level (using spawn_table)
# Call this like: spawn_at_level(1, $Path/To/SpawnMesh)
func do_spawn():
	var level_spawns = spawn_table
	var level = spawn_level
	var max_loops = 50
	
	while level > 0:
		max_loops -= 1
		
		var spawnable : Dictionary =  weighted_choice(spawn_table)
		var sp_level = spawnable.get("level", 1)
		
		if level >= sp_level:
			
			
			var intensity = sp_level * _spawn(spawnable)
			print("Doing spawn with an intensity of ", intensity, " and AMOUNT = ", intensity/sp_level, ".")
			level -= intensity
			
		
		if max_loops <= 0 or level <= 0:
			break

func spawn_ammo():
	var scene: PackedScene = load("res://ammo_box.tscn")
	var pos = get_random_point_on_top(self)
	var obj = scene.instantiate()
	obj.scale *= 3
	obj.global_position = pos
	obj.rotate_y(-90)
	spawn_instance(obj, pos)
	print("ammo scale", obj.scale)
	
func spawn_upgrade():
	var scene: PackedScene = load("res://subview.tscn")
	var pos = get_far_right_point(self)
	
	pos.y = 11.941
	pos.z = -0.366
	
	var obj: Node3D = scene.instantiate()
	obj.global_position = pos
	obj.rotate_y(-90)
	print("Upgrade rotation I ", obj.rotation.y)
	spawn_instance(obj, pos)
	obj.rotate_y(-90)

	print("Upgrade rotation II ", obj.rotation.y)
	
	
func _ready() -> void:
	# Wait until the current frame is finished processing
	await get_tree().process_frame
	do_spawn()
	if randi_range(0, 100) < 40:
		spawn_ammo()
	spawn_upgrade()
