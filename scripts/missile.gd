extends Area2D

@export var speed = 300.0
@export var damage = 25
@export var lifetime = 3.0  # Seconds before self-destruction

var direction = Vector2.RIGHT
var shooter_id = ""

@onready var lifetime_timer = $LifetimeTimer
@onready var sprite = $Sprite2D
@onready var explosion_scene = preload("res://scenes/explosion.tscn")

func _ready():
	# Set up timer for self-destruction
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.start()
	
	# Connect signals
	connect("body_entered", Callable(self, "_on_body_entered"))
	lifetime_timer.timeout.connect(Callable(self, "_on_lifetime_timer_timeout"))
	
	# Set initial rotation based on direction
	rotation = direction.angle()

func _physics_process(delta):
	# Move in the specified direction
	position += direction * speed * delta

func _on_body_entered(body):
	# Check if the body is a player and not the shooter
	if body is CharacterBody2D and body.has_method("execute_command") and body.player_id != shooter_id:
		# Apply damage
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# Print a hit message
		print(shooter_id + " hit " + body.player_id)
		
		# Create explosion
		explode()
		
		# Destroy the missile
		queue_free()

func _on_lifetime_timer_timeout():
	# Self-destruct after lifetime expires
	explode()
	queue_free()

func explode():
	# Instantiate explosion effect
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().get_current_scene().add_child(explosion)
