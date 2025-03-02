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
#var deepseek = "deepseek-r1-distill-llama-70b"  it's thinking so kinda slow
var polling_timer = 3.0

func _ready():
	var config = ConfigFile.new()
	var err = config.load("res://secrets.cfg")  # Use "user://" for persistent storage
	if err == OK:
		GROQ_API_KEY = config.get_value("secrets", "GROQ_API_KEY", "")
		print("Loaded API Key:", GROQ_API_KEY)
		
		# Initialize both models
		send_groq_request(llama, http_llama)
		send_groq_request(qwen, http_qwen)
		
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
	
	var payload = {
		"model": model_name,  # Specify the LLM model
		"messages": [
			{"role": "system", "content": "You are controlling a tank in a 2D battlefield."},
			{"role": "user", "content": "You are controlling a tank in a 2D battlefield. Respond with a single vector-based movement command in the format: move X,Y where X is the horizontal component (0 to +500) and Y is the vertical component (0 to +500). Positive X moves right, negative X moves left, positive Y moves up, negative Y moves down. The magnitude of your vector should typically be between 10 and 100. Your task is to navigate strategically. Generate completely random vector combinations for unpredictable movement. Do not include any explanations or additional text - output only the command itself."}
		]}
	var json_payload = JSON.stringify(payload)  
	
	var error = http_node.request(url, headers, HTTPClient.METHOD_POST, json_payload) 
	print("Sending request to model: " + model_name)
	if error != OK:
		print("Request failed for " + model_name + ": ", error)

# Renamed to be specific to Llama
func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	handle_api_response(result, response_code, headers, body, "llama")

func _on_http_request_qwen_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	handle_api_response(result, response_code, headers, body, "qwen")	

# Common function to handle responses for both models
func handle_api_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, model_id: String) -> void:
	if response_code == 200:
		var response_json = JSON.parse_string(body.get_string_from_utf8())
		var command = response_json["choices"][0]["message"]["content"]
		print(model_id + " Response:", command)
		
		if players.has(model_id) && players_node.has_node("Player") :
			players[model_id].execute_command(command)
	else:
		print("API Request Failed for " + model_id + ". Code:", response_code)

# Timer for Llama model
func _on_request_timer_llama_timeout() -> void:
	send_groq_request(llama, http_llama)

# Timer for Qwen model
func _on_request_timer_qwen_timeout() -> void:
	send_groq_request(qwen, http_qwen)
