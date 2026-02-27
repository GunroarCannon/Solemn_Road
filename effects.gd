extends Node
# Effects.gd (Autoload)

func shake(node: Control, intensity: float, duration: float, frequency: float = 60.0, axes: String = "XY"):
	if not node: return
	
	var original_pos = node.position
	var time_passed = 0.0
	var axes_upper = axes.to_upper()
	
	# Create a series of random samples like your Lua table
	var sample_count = int(duration * frequency)
	var samples_x = []
	var samples_y = []
	for i in range(sample_count):
		samples_x.append(randf_range(-1.0, 1.0))
		samples_y.append(randf_range(-1.0, 1.0))

	# Use a Tween to process the frame-by-frame offset
	var tween = node.create_tween()
	# We use a dummy property to trigger a "callback" every frame
	tween.tween_method(
		func(t): 
			var current_time = t * duration
			# Calculate Decay (k)
			var k = (duration - current_time) / duration
			
			# Sample lookup (similar to your shakeNoise/getShakeAmplitude)
			var s = (current_time) * frequency
			var s0 = int(s)
			var s1 = s0 + 1
			
			var get_amp = func(samples: Array):
				if s1 >= samples.size(): return 0.0
				return intensity * (samples[s0] + (s - s0) * (samples[s1] - samples[s0])) * k

			var offset = Vector2.ZERO
			if "X" in axes_upper: offset.x = get_amp.call(samples_x)
			if "Y" in axes_upper: offset.y = get_amp.call(samples_y)
			
			node.position = original_pos + offset,
		0.0, 1.0, duration
	)
	
	# Reset position when done
	tween.finished.connect(func(): node.position = original_pos)

func pulse(node: Control, duration: float = 1.4, debug: bool = false):
	if not node: return
	
	var tween = node.create_tween().set_loops()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	if node is Label:
		# CHECK FOR LABEL SETTINGS (Your screenshot case)
		if node.label_settings:
			var settings = node.label_settings
			var base_color = settings.font_color
			
			if debug:
				base_color = Color.LIME
				settings.font_color = base_color
				print("DEBUG: Pulsing via LabelSettings on ", node.name)
				
			var target_color = base_color.darkened(0.8)
			if debug: target_color = Color.MAGENTA
			
			# We animate the property ON the settings resource, not the node
			tween.tween_property(settings, "font_color", target_color, duration*.3).set_trans(Tween.TRANS_SINE)
			tween.tween_property(settings, "font_color", base_color, duration*.7).set_trans(Tween.TRANS_SINE)
		
		else:
			# Standard Theme Override fallback
			var prop = "theme_override_colors/font_color"
			var base_color = node.get_theme_color("font_color")
			node.add_theme_color_override("font_color", base_color)
			
			var target_color = base_color.darkened(0.8)
			tween.tween_property(node, prop, target_color, duration).set_trans(Tween.TRANS_SINE)
			tween.tween_property(node, prop, base_color, duration).set_trans(Tween.TRANS_SINE)	
	elif node is PanelContainer:
		var style = node.get_theme_stylebox("panel")
		if style is StyleBoxFlat:
			# 1. Setup Unique Stylebox
			var dupe_style = style.duplicate()
			node.add_theme_stylebox_override("panel", dupe_style)
			
			# 2. Determine Colors
			var base_color = dupe_style.border_color
			var target_color = base_color.darkened(0.8)
			
			if debug:
				base_color = Color.LIME
				target_color = Color.MAGENTA
				dupe_style.set_border_width_all(10) # Make border huge for debug
				print("DEBUG: Pulsing Panel Border ", node.name)
				
			dupe_style.border_color = base_color
			
			# 3. Animate the StyleBox object directly (most reliable for borders)
			tween.tween_property(dupe_style, "border_color", target_color, duration).set_trans(Tween.TRANS_SINE)
			tween.tween_property(dupe_style, "border_color", base_color, duration).set_trans(Tween.TRANS_SINE)
