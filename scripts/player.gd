extends CharacterBody2D

@export var speed = 100.0  # Movement speed (pixels per second)
@export var turn_speed = 60.0  # Rotation speed (degrees per second)
var player_id = ""
var target_position: Vector2 = Vector2.ZERO  # Target position to move to
var moving = false
@onready var timer = $Timer

func execute_command(command: String):
	var parts = command.split(" ")  # Split command into words
	if parts.size() < 2:
		return  # Ignore invalid commands
	
	var action = parts[0]
	if action != "move":
		return  # Only process "move" commands
	
	# Extract X,Y components from the command
	var vector_parts = parts[1].split(",")
	if vector_parts.size() != 2:
		return  # Ignore commands without proper X,Y format
	
	var x_component = vector_parts[0].to_float()
	var y_component = vector_parts[1].to_float()
	
	# Calculate the movement vector
	var movement_vector = Vector2(x_component, y_component)
	
	# Set target position based on the movement vector
	target_position = global_position + movement_vector
	moving = true
	
	# Start the timeout timer
	timer.start(5)  # Stops movement after some time

func _on_move_timeout():
	moving = false  # Stop movement when timer expires
	velocity = Vector2.ZERO

func _physics_process(delta):
	# Handle movement
	if moving:
		var move_direction = (target_position - global_position).normalized()
		
		# Optionally rotate the tank to face the direction of movement
		var target_angle = move_direction.angle()
		rotation = lerp_angle(rotation, target_angle, turn_speed * delta * 0.1)
		
		velocity = move_direction * speed
		
		if global_position.distance_to(target_position) < 2:  # Stop when close enough
			moving = false
			velocity = Vector2.ZERO
	
	move_and_slide()
