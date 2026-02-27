extends Node

const SAVE_PATH = "user://save_data.json"
var data: Dictionary = {}

func _ready():
	data = load_data()

# Saves a specific key/value pair and writes to disk immediately
func save_value(key: String, value: Variant):
	data[key] = value
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data, "\t") # "\t" makes the JSON readable/pretty
		file.store_string(json_string)
		file.close()
		print("Saved ", key, ": ", value)

# Simple helper to check if we have a piece of data
func has_data(key: String) -> bool:
	return data.has(key) and str(data[key]) != ""

func get_data(key):
	return data.get(key)

# Internal loader
func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error == OK:
		return json.get_data()
	return {}
