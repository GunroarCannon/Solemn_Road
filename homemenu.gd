extends VBoxContainer


@export var y_separation: float = 60.0
@export var x_slant: float = 20.0 # How many pixels to move right per item

func _ready():
	var children = get_children()
	for i in range(children.size()):
		var child = children[i]
		if child is Button:
			print("child step")
			child.global_position.y = i * y_separation
			child.global_position.x = i * x_slant
