@tool
class_name Wave
extends Resource

@export var wave_entries: Array[WaveEntry] = []
@export var wave_name: String = "Wave"
@export var delay_before_next_wave: float = 0.0

# This ensures WaveEntry is loaded before Wave
const WaveEntry = preload("res://addons/spawner/wave_entry.gd")
