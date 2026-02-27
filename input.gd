extends Node

func _ready():
	# Movement
	add_key_action("moveForwardAction", KEY_W)
	add_key_action("moveBackwardAction", KEY_S)
	add_key_action("moveLeftAction", KEY_A)
	add_key_action("moveRightAction", KEY_D)
	add_key_action("runAction", KEY_SHIFT)
	add_key_action("jumpAction", KEY_SPACE)
	add_key_action("crouchAction", KEY_CTRL)

	# Camera / Input
	add_key_action("mouseModeAction", KEY_ESCAPE)

	# Weapons
	add_mouse_button_action("shootAction", MOUSE_BUTTON_LEFT)
	add_key_action("reloadAction", KEY_R)
	add_mouse_wheel_action("weaponWheelUpAction", true)
	add_mouse_wheel_action("weaponWheelDownAction", false)

	# Shooting Range
	add_key_action("restartShootingRangeAction", KEY_F5)


# ---------- HELPERS ----------

func add_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

		var event := InputEventKey.new()
		event.keycode = keycode
		InputMap.action_add_event(action_name, event)


func add_mouse_button_action(action_name: String, button: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

		var event := InputEventMouseButton.new()
		event.button_index = button
		InputMap.action_add_event(action_name, event)


func add_mouse_wheel_action(action_name: String, up: bool) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

		var event := InputEventMouseButton.new()
		event.button_index =  MOUSE_BUTTON_WHEEL_DOWN
		if up:
			event.button_index = MOUSE_BUTTON_WHEEL_UP
		InputMap.action_add_event(action_name, event)
