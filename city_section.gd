extends NavigationRegion3D

@onready var city_section_scene: PackedScene = preload("res://city_section.tscn")
var generated = false
# Configuration
const STRIP_LENGTH: float = 87.0
const SPAWNER_WIDTH: float = 4.0
const FIXED_Y: float = 9.935
const FIXED_Z: float = 0.1

# Monster List: [Scene Path, Base Intensity/Difficulty Value]
var monster_pool = [
	["res://crawler_monster.tscn", 1.0],
	["res://angel_follower_statue.tscn", 2.5],
	["res://floating_eye.tscn", 4.0],
	
	["res://walker_monster.tscn", 4.0],
	["res://mutant_monster.tscn", 7.0]
]

@onready var spawner_scene = preload("res://spawner_mesh.tscn")

func _ready():
	place_spawners()

func place_spawners():
	# Calculate how many spawners fit in 87m
	var count = floor(STRIP_LENGTH / SPAWNER_WIDTH)
	var start_x = -(STRIP_LENGTH / 2.0)
	
	for i in range(count):
		var spawner = spawner_scene.instantiate()
		
		# Linear placement along X
		var pos_x = start_x + (i * SPAWNER_WIDTH) + (SPAWNER_WIDTH / 2.0)
		spawner.position = Vector3(pos_x, FIXED_Y, FIXED_Z)
		
		add_child(spawner)
		
		# Initial monster population
		populate_spawner(spawner)

func _process(_delta):
	# Calculate "Flow Spike" Intensity
	var dist = GlobalGame.player.global_position.distance_to(GlobalGame.starting_point)
	
	# Base intensity climbs with distance, Sine wave creates the "flow spikes"
	var base_difficulty = dist * 0.05 
	var spike_pattern = (sin(dist * 0.2) + 1.0) / 2.0 # Oscillation between 0 and 1
	
	var current_intensity = base_difficulty * (1.0 + spike_pattern)
	
	# Pass this to GlobalGame or use it to live-update spawners
	GlobalGame.current_spawn_intensity = current_intensity

func populate_spawner(spawner_node):
	# Example logic: Pick a monster that fits the current distance intensity
	# You can call this periodically or once on spawn
	var chosen = monster_pool.pick_random()
	# spawner_node.setup_monster(chosen[0], chosen[1])



func genNewArea():
	if generated:
		return
	
	generated = true
	var parent = get_parent()
	var newSection = city_section_scene.instantiate()
	
	parent.add_child(newSection)
	
	newSection.global_position.x = 104+global_position.x#145.865*2
	newSection.rotation.y = -180
	newSection.rotation = self.rotation
	newSection.global_position.y = global_position.y
	newSection.global_position.z = global_position.z
	print("new section of city road generated ", newSection.rotation, newSection.global_position, global_position, rotation)


func _on_gen_new_area_checker_body_entered(body: Node3D) -> void:
	if body == GlobalGame.player:
		genNewArea()
	else:
		print("gen ", body)
