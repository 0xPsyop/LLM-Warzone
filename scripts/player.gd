extends CharacterBody2D

@export var speed = 100.0  # Tank movement speed
var player_id = ""  # Unique ID set by GameManager

func execute_command(command: String):
	match command:
		"forward":
			velocity = Vector2(0, -speed)  # Move up
		"backward":
			velocity = Vector2(0, speed)  # Move down
		"left":
			velocity = Vector2(-speed, 0)  # Move left
		"right":
			velocity = Vector2(speed, 0)  # Move right
		_:
			velocity = Vector2.ZERO  # Stop if unknown command
	
	move_and_slide()  # Apply movement
