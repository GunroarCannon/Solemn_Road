@icon("res://addons/splash_screen_wizard/icons/SlideTransitionFade.svg")
class_name SlideTransitionZoom extends SlideTransition
## Transition that fades in or out a [SplashScreenSlide].


## The different types of fade.
enum FadeType
{
	## Start with 0 and go to 1.
	FADE_IN,
	## Start with 1 and go to 0.
	FADE_OUT,
}


## The type of fade to perform.
@export var fade_type: FadeType = FadeType.FADE_IN
## The duration of the fade.
@export var duration: float = 0.5
## The type of transition to use.
@export var transition_type: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR


func _start(target: Node) -> void:
	var fade: Tween = target.get_tree().create_tween()

	var value_start: float
	var value_end: float

	match fade_type:
		FadeType.FADE_IN:
			value_start = 0
			value_end = 1
		FadeType.FADE_OUT:
			value_start = 0
			value_end = 0

	var max = 3
	target.scale = value_start*max
	
	target.show()
	fade.tween_property(target, "scale", value_end*max, duration).set_trans(transition_type)

	await fade.finished
