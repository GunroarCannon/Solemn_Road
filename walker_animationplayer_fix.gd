@tool
extends AnimationPlayer

@export var animation_name = "Mon_BlackDragon31_Btl_Walk01"
@export var shift_amount : float = 63
@export var run_shift: bool:
	set(value):
		if value:
			_shift_keyframes();
var donee = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _shift_keyframes():
	if Engine.is_editor_hint():
		self.donee = true
		print(99)
		var anim : Animation = get_animation(animation_name);
		print(animation_name," hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh")
		if anim:
			var max_new_time = 0.0
			for track_idx in anim.get_track_count():
				var key_count = anim.track_get_key_count(track_idx)
				for key_idx in range(key_count-1, -1, -1):
					#reversing avoids index shifts
					var time = anim.track_get_key_time(track_idx, key_idx)
					var new_time = max(0.0, time - shift_amount)
					if new_time == 0.0 and time <= shift_amount:
						print("too small",time," ,",shift_amount," ,",new_time)
						pass
						#remove if shifted to 0? Nah
						#anim.track_remove_key(track_idx, key_idx)
					else:
						print("done shift")
						anim.track_set_key_time(track_idx, key_idx, new_time)
						max_new_time = max(max_new_time, new_time)
				
			print("old anim length,",anim.length)
			if anim.get_track_count()>0: print("bad")
			anim.length = max_new_time if max_new_time != 0.0 else anim.length
			print("Shifted")

	pass # Replace with function body.
