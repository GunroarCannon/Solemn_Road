@tool
@icon("res://addons/spawner/spawner_2d/spawner_2d_icon.svg")
extends Marker2D
class_name Spawner2D

# Import the Wave and WaveEntry classes
const Wave = preload("res://addons/spawner/wave.gd")
const WaveEntry = preload("res://addons/spawner/wave_entry.gd")

@export_category("Scenes")
@export var waves: Array[Wave] = []

@export_category("Spawn parameters")
@export var spawn_on_load: bool = false # start spawning on spawner load
@export var continuous_spawn: bool = false # spawn once or continuously in a coroutine
@export var use_marker_as_parent:bool = false # Use the spawn points as parrent or instanciate under the root of the scene
@export_enum("Random", "Ordered-ASC", "Ordered-DSC", "Wave") var spawn_type:String = "Ordered-ASC"
@export_enum("Random", "Ordered-ASC", "Ordered-DSC") var spawnpoint_selection_type:String = "Ordered-ASC"
@export var number_of_spawn_point_to_use: int = -1 # Max number of spawn point to use, use all if -1
@export var spawn_interval: float = 0 # Time between instaciation in seconds
@export var wave_interval: float = 0 # Time between wave in seconds
#TODO wave info something like array of array of int the later representing the distribution of the number of instance needed to spawn

var spawn_points: Array[Marker2D]

# Plugin Shenanigans
func _enable_plugin() -> void:
	# Add autoloads here.
	pass

func _disable_plugin() -> void:
	# Remove autoloads here.
	pass

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass

# Actual Plugin
func _ready() -> void:
	load_spawn_points()
	if spawn_on_load:
		if continuous_spawn:
			# TODO continuous spawn coroutine
			pass
		else:
			spawn_instances_coroutine()
			
func load_spawn_points() -> void:
	var children_nodes: Array[Node] = get_children()
	spawn_points.clear()
	for child in children_nodes:
		if child is Marker2D:
			spawn_points.append(child)
	print("Loaded ", spawn_points.size(), " spawn points")

func spawn_instances_coroutine() -> void:
	await spawn_instances()

func spawn_instances() -> void:
	if waves.is_empty():
		push_error("No waves to spawn")
		return
	
	if spawn_points.is_empty():
		push_error("No spawn points available")
		return
	
	match spawn_type:
		"Random":
			await random_spawn()
		"Ordered-ASC":
			await ordered_spawn()
		"Ordered-DSC":
			await ordered_spawn(false)
		"Wave":
			await wave_spawn()
		_:
			push_error("Invalid Spawn Type")

func random_spawn() -> void:
	var selected_spawn_points: Array[Marker2D] = get_selected_spawn_points()
	
	# Get all wave entries from all waves
	var all_wave_entries: Array[WaveEntry] = []
	for wave in waves:
		for entry in wave.wave_entries:
			for i in range(entry.number_of_instances):
				all_wave_entries.append(entry)
	
	if all_wave_entries.is_empty():
		push_error("No wave entries to spawn")
		return
			
	for spawnpoint in selected_spawn_points:
		var random_entry = all_wave_entries[randi_range(0, all_wave_entries.size()-1)]
		await instantiate_scene_from_entry(random_entry, spawnpoint)
	
func ordered_spawn(ASC: bool = true) -> void:
	# Get the spawn_points that will be used
	var selected_spawn_points: Array[Marker2D] = get_selected_spawn_points()
	
	# Get all wave entries from all waves
	var all_wave_entries: Array[WaveEntry] = []
	for wave in waves:
		for entry in wave.wave_entries:
			for i in range(entry.number_of_instances):
				all_wave_entries.append(entry)
	
	if all_wave_entries.is_empty():
		push_error("No wave entries to spawn")
		return
	
	if not ASC:
		all_wave_entries.reverse()
	
	var counter: int = 0
	for spawnpoint in selected_spawn_points:
		var entry = all_wave_entries[counter % all_wave_entries.size()]
		await instantiate_scene_from_entry(entry, spawnpoint)
		counter += 1
		

func wave_spawn() -> void:
	# Get the spawn_points that will be used
	var selected_spawn_points: Array[Marker2D] = get_selected_spawn_points()

	for wave in waves:
		# Get all wave entries from the current wave
		var all_wave_entries: Array[WaveEntry] = []
		for entry in wave.wave_entries:
			for i in range(entry.number_of_instances):
				all_wave_entries.append(entry)
		
		if all_wave_entries.is_empty():
			push_error("No wave entries to spawn in wave: " + wave.wave_name)
			continue
		
		var counter: int = 0
		for spawnpoint in selected_spawn_points:
			var entry = all_wave_entries[counter % all_wave_entries.size()]
			await instantiate_scene_from_entry(entry, spawnpoint)
			counter += 1
		
		# Wait for wave interval before spawning next wave
		await get_tree().create_timer(wave_interval).timeout
	
# Selecting spawn points
	
func get_selected_spawn_points() -> Array[Marker2D]:
	match spawnpoint_selection_type: 
		"Random":
			return select_random_spawn_points()
		"Ordered-ASC":
			return select_spawn_points()
		"Ordered-DSC":
			return select_spawn_points(false)
		_:
			push_error("Invalid Spawnpoints Selection Type")
			return []

func select_random_spawn_points() -> Array[Marker2D]:
	var selected_spawn_points: Array[Marker2D] = []
	if number_of_spawn_point_to_use == -1:
		selected_spawn_points = spawn_points.duplicate()
		selected_spawn_points.shuffle()
		return selected_spawn_points
	
	for i in range(number_of_spawn_point_to_use):
		selected_spawn_points.append(spawn_points[randi_range(0, spawn_points.size()-1)])
	return selected_spawn_points

func select_spawn_points(ASC: bool = true) -> Array[Marker2D]:
	var selected_spawn_points: Array[Marker2D] = []
	var counter:int = 0
	if ASC:
		for spawnpoint in spawn_points:
			if number_of_spawn_point_to_use != -1 and counter >= number_of_spawn_point_to_use:
				break
			
			selected_spawn_points.append(spawnpoint)
			counter+=1
	else :
		var reversed_spawn_points = spawn_points.duplicate()
		reversed_spawn_points.reverse()
		for spawnpoint in reversed_spawn_points:
			if number_of_spawn_point_to_use != -1 and counter >= number_of_spawn_point_to_use:
				break
			
			selected_spawn_points.append(spawnpoint)
			counter+=1
	return selected_spawn_points

# Instancing
	
func instantiate_scene_from_entry(wave_entry: WaveEntry, spawnpoint: Marker2D) -> void:
	if not wave_entry or not wave_entry.packed_scene:
		push_error("Invalid wave entry or missing packed scene")
		return
	
	var instance = wave_entry.packed_scene.instantiate()
	instance.global_position = spawnpoint.global_position
	
	if use_marker_as_parent:
		spawnpoint.add_child.call_deferred(instance)
		instance.position = Vector2.ZERO
	else:
		var root = get_tree().get_current_scene()
		if root:
			root.add_child.call_deferred(instance)
		else:
			get_tree().get_root().add_child.call_deferred(instance)
	await get_tree().create_timer(spawn_interval).timeout
	
