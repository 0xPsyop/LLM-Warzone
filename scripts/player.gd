extends CharacterBody2D

@export var speed = 100.0  # Movement speed (pixels per second)
@export var turn_speed = 60.0  # Rotation speed (degrees per second)
@export var detection_radius = 200.0  # Detection radius for enemies
@export var shoot_cooldown = 0.5  # Time between shots (reduced for more frequent shooting)
@export var max_health = 100  # Maximum health points
@export var health = 100  # Current health

var player_id = ""
var target_position: Vector2 = Vector2.ZERO  # Target position to move to
var moving = false
var can_shoot = true

@onready var timer = $Timer
@onready var cooldown_timer = $CooldownTimer
@onready var detection_area = $DetectionArea
@onready var health_bar = $HealthBar
const MISSILE_SCENE = preload("res://scenes/missile.tscn")

func _ready():
	# Setup the detection area as a CircleShape2D if it doesn't already have a shape
	if detection_area.get_child_count() == 0:
		var collision_shape = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = detection_radius
		collision_shape.shape = shape
		detection_area.add_child(collision_shape)
	
	# Set up health bar
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = true
	
	# Setup cooldown timer
	cooldown_timer.wait_time = shoot_cooldown
	cooldown_timer.one_shot = true

func execute_command(command: String):
	var parts = command.split(" ")  # Split command into words
	if parts.size() < 2:
		return  # Ignore invalid commands
	
	var action = parts[0].to_lower()  # Convert to lowercase for case insensitivity
	
	if action == "move":
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
	elif action == "shoot" and can_shoot:
		# Extract target coordinates if provided
		if parts.size() >= 2:
			var target_parts = parts[1].split(",")
			if target_parts.size() == 2:
				var target_x = target_parts[0].to_float()
				var target_y = target_parts[1].to_float()
				shoot(Vector2(target_x, target_y))
			else:
				# Shoot in the direction the tank is facing
				shoot(global_position + Vector2.RIGHT.rotated(rotation) * 100)
		else:
			# Shoot in the direction the tank is facing
			shoot(global_position + Vector2.RIGHT.rotated(rotation) * 100)

# Fixed parameter name to avoid shadowing the class variable target_position
func shoot(shoot_target: Vector2):
	if !can_shoot:
		return
		
	# Create missile instance
	var missile = MISSILE_SCENE.instantiate()
	missile.shooter_id = player_id
	missile.global_position = global_position
	missile.direction = (shoot_target - global_position).normalized()
	
	# Add missile to the main scene
	get_tree().get_current_scene().add_child(missile)
	
	# Start cooldown
	can_shoot = false
	cooldown_timer.start()

func take_damage(amount):
	health -= amount
	health_bar.value = health
	
	# Flash red to indicate damage
	modulate = Color(1, 0.3, 0.3, 1)
	create_tween().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
	
	if health <= 0:
		# Tank destroyed
		print(player_id + " was destroyed!")
		# Optional: Add explosion effect here
		var explosion_scene = load("res://scenes/explosion.tscn")
		var explosion = explosion_scene.instantiate()
		explosion.position = position
		get_parent().add_child(explosion)
		
		# Reset health and position after a short delay
		await get_tree().create_timer(2.0).timeout
		health = max_health
		health_bar.value = health
		position = Vector2(randf_range(100, 500), randf_range(100, 500))

func _on_timer_timeout():
	moving = false  # Stop movement when timer expires
	velocity = Vector2.ZERO

func _on_cooldown_timer_timeout():
	can_shoot = true

func _physics_process(delta):
	# Original movement behavior
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

func get_closest_enemy():
	var enemies = []
	var bodies = detection_area.get_overlapping_bodies()
	
	for body in bodies:
		if body is CharacterBody2D and body != self and body.player_id != player_id:
			enemies.append(body)
	
	if enemies.size() > 0:
		var closest_enemy = enemies[0]
		var closest_distance = global_position.distance_to(closest_enemy.global_position)
		
		for enemy in enemies:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_enemy = enemy
				closest_distance = distance
		
		return closest_enemy
	
	return null
