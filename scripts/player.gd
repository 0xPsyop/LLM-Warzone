extends CharacterBody2D

@export var speed = 20.0  # Tank movement speed
var player_id = ""  # Unique ID set by GameManager
var movement_direction = Vector2.ZERO  # Store movement direction

func execute_command(command: String):
	match command:
		"forward":
			movement_direction = Vector2(0, -1)  # Move up
		"backward":
			movement_direction = Vector2(0, 1)  # Move down
		"left":
			movement_direction = Vector2(-1, 0)  # Move left
		"right":
			movement_direction = Vector2(1, 0)  # Move right
		_:
			movement_direction = Vector2.ZERO  # Stop if unknown command

func _physics_process(delta):
	velocity = movement_direction * speed  # Apply movement
	move_and_slide()
