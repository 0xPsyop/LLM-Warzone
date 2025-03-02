extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Connect to the animation finished signal
	animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	# Play the explosion animation
	animated_sprite.play("explode")

func _on_animation_finished():
	# Remove the explosion after animation completes
	queue_free()
