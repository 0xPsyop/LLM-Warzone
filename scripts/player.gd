extends CharacterBody2D

@export var speed = 100.0  # Movement speed (pixels per second)
@export var turn_speed = 60.0  # Rotation speed (degrees per second)

var player_id = ""
var target_position: Vector2 = Vector2.ZERO  # Target position to move to
var moving = false
var target_angle = 0.0  # Desired rotation angle
var rotating = false

@onready var timer = $Timer


func execute_command(command: String):
	var parts = command.split(" ")  # Split command into words
	if parts.size() < 2:
		return  # Ignore invalid commands

	var action = parts[0]
	var value = parts[1].to_float()

	match action:
		"forward":
			var move_direction = Vector2.from_angle(rotation)
			target_position = global_position + move_direction * value  # Move by given distance
			moving = true
		"backward":
			var move_direction = Vector2.from_angle(rotation)
			target_position = global_position - move_direction * value  # Move backwards
			moving = true
		"left":
			target_angle = rotation_degrees - value  # Turn left by given degrees
			rotating = true
		"right":
			target_angle = rotation_degrees + value  # Turn right by given degrees
			rotating = true
		_:
			moving = false
			rotating = false

	timer.start(5)  # Stops movement after some time


func _on_move_timeout():
	moving = false  # Stop movement when timer expires
	velocity = Vector2.ZERO


func _physics_process(delta):
	# Handle rotation first
	if rotating:
		var angle_diff = fmod(target_angle - rotation_degrees + 180, 360) - 180
		if abs(angle_diff) > 1:  # If not aligned yet
			rotation_degrees += clamp(angle_diff, -turn_speed * delta, turn_speed * delta)
		else:
			rotation_degrees = target_angle  # Snap to target angle
			rotating = false

	# Handle movement
	if moving:
		var move_direction = (target_position - global_position).normalized()
		velocity = move_direction * speed
		if global_position.distance_to(target_position) < 2:  # Stop when close enough
			moving = false
			velocity = Vector2.ZERO

	move_and_slide()
