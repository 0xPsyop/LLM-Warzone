extends Node

@onready var http_llama = $HTTPRequestLlama  
@onready var http_qwen = $HTTPRequestQwen  
@onready var players_node = get_tree().get_current_scene().get_node("Players") # Reference to "Players" Node
const PLAYER_SCENE = preload("res://scenes/player.tscn")  
@onready var request_timer_llama = $RequestTimerLlama
@onready var request_timer_qwen = $RequestTimerQwen  
var players = {}
var GROQ_API_KEY = ""
var llama = "llama-3.3-70b-versatile"
var qwen = "qwen-2.5-32b"
var polling_timer = 3.0

func _ready():
	# Connect signals explicitly to ensure they're working
	http_llama.request_completed.connect(_on_http_request_llama_request_completed)
	http_qwen.request_completed.connect(_on_http_request_qwen_request_completed)
	request_timer_llama.timeout.connect(_on_request_timer_llama_timeout)
	request_timer_qwen.timeout.connect(_on_request_timer_qwen_timeout)
	
	var config = ConfigFile.new()
	var err = config.load("res://secrets.cfg")  # Use "user://" for persistent storage
	if err == OK:
		GROQ_API_KEY = config.get_value("secrets", "GROQ_API_KEY", "")
		print("Loaded API Key:", GROQ_API_KEY)
		
		# Initialize both models
		send_groq_request(llama, http_llama)
		send_groq_request(qwen, http_qwen)
		
		# Start the timers to periodically poll the models
		request_timer_llama.start(polling_timer)
		request_timer_qwen.start(polling_timer)
		
		# Spawn both players initially if they don't exist
		if not players.has("llama"):
			spawn_player("llama", Vector2(100, 100))
		if not players.has("qwen"):
			spawn_player("qwen", Vector2(300, 100)) 
		
func spawn_player(player_id: String, position: Vector2):
	var new_player = PLAYER_SCENE.instantiate()
	new_player.position = position
	new_player.player_id = player_id
	players_node.add_child(new_player)
	players[player_id] = new_player

func send_groq_request(model_name: String, http_node):
	var url = "https://api.groq.com/openai/v1/chat/completions"
	var headers = [
		 "Authorization: Bearer " + GROQ_API_KEY,  
		 "Content-Type: application/json"
	]
	
	# Check if player has an enemy in range
	var has_enemy_in_range = false
	var enemy_position = Vector2.ZERO
	
	if players.has(get_model_id_from_http(http_node)):
		var player = players[get_model_id_from_http(http_node)]
		var closest_enemy = player.get_closest_enemy()
		
		if closest_enemy != null:
			has_enemy_in_range = true
			enemy_position = closest_enemy.global_position
	
	var system_message = "You are controlling a tank in a 2D battlefield."
	var user_message = "You are controlling a tank in a 2D battlefield. "
	
	if has_enemy_in_range:
		user_message += "An enemy tank is detected at position X=" + str(enemy_position.x) + ", Y=" + str(enemy_position.y) + ". "
		user_message += "Respond with either a movement or shooting command.\n"
		user_message += "For movement: 'move X,Y' where X is the horizontal component and Y is the vertical component.\n"
		user_message += "For shooting: 'shoot X,Y' to fire at the specified coordinates.\n"
		user_message += "Make strategic decisions about whether to shoot or move. Do not include any explanations - output only the command itself."
	else:
		user_message += "Respond with a single vector-based movement command in the format: move X,Y where X is the horizontal component (0 to +500) and Y is the vertical component (0 to +500). Positive X moves right, negative X moves left, positive Y moves up, negative Y moves down. The magnitude of your vector should typically be between 10 and 100. Your task is to navigate strategically. Generate completely random vector combinations for unpredictable movement. Do not include any explanations or additional text - output only the command itself."
	var payload = {
		"model": model_name,
		"messages": [
			{"role": "system", "content": system_message},
			{"role": "user", "content": user_message}
		],
		"temperature": 0.7
	}
	var json_payload = JSON.stringify(payload)  
	
	print("Sending request to model: " + model_name)
	var error = http_node.request(url, headers, HTTPClient.METHOD_POST, json_payload) 
	if error != OK:
		print("Request failed for " + model_name + ": ", error)

# Helper function to get model ID from HTTP node
func get_model_id_from_http(http_node):
	if http_node == http_llama:
		return "llama"
	elif http_node == http_qwen:
		return "qwen"
	return ""

func _on_http_request_llama_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Llama response received, code:", response_code)
	handle_api_response(result, response_code, headers, body, "llama")

func _on_http_request_qwen_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Qwen response received, code:", response_code)
	handle_api_response(result, response_code, headers, body, "qwen")    

# Common function to handle responses for both models
# Fixed warning by prefixing unused parameters with underscore
func handle_api_response(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, model_id: String) -> void:
	if response_code == 200:
		var json_string = body.get_string_from_utf8()
		var response_json = JSON.parse_string(json_string)
		
		if response_json == null:
			print("Failed to parse JSON response for " + model_id)
			return
			
		if not response_json.has("choices") or response_json["choices"].size() == 0:
			print("Invalid response format for " + model_id)
			return
			
		var command = response_json["choices"][0]["message"]["content"]
		print(model_id + " Response:", command)
		
		if players.has(model_id) and players[model_id] != null:
			players[model_id].execute_command(command)
	else:
		print("API Request Failed for " + model_id + ". Code:", response_code)
		print("Response body: ", body.get_string_from_utf8())

# Timer for Llama model
func _on_request_timer_llama_timeout() -> void:
	send_groq_request(llama, http_llama)

# Timer for Qwen model
func _on_request_timer_qwen_timeout() -> void:
	send_groq_request(qwen, http_qwen)
