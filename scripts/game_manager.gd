extends Node

@onready var http = $HTTPRequest  # Reference HTTPRequest node
@onready var players_node = get_tree().get_current_scene().get_node("Players") # Reference to "Players" Node
const PLAYER_SCENE = preload("res://scenes/player.tscn")  # Load player scene

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
		send_groq_request(llama)
		# Spawn player initially if not exists
		if not players.has("llama"):
			spawn_player("llama", Vector2(100, 100))

func spawn_player(player_id: String, position: Vector2):
	var new_player = PLAYER_SCENE.instantiate()
	new_player.position = position
	new_player.player_id = player_id
	players_node.add_child(new_player)
	players[player_id] = new_player

func send_groq_request(model_name:String):
	var url = "https://api.groq.com/openai/v1/chat/completions"
	var headers = [
		 "Authorization: Bearer " + GROQ_API_KEY,  
		 "Content-Type: application/json"
	]
	
	var payload = {
		"model": model_name,  # Specify the LLM model
		"messages": [
			{"role": "system", "content": "You are controlling a tank in a 2D battlefield."},
			{"role": "user", "content": "Choose the best movement. Respond with only 'forward', 'backward', 'left', or 'right'."}
		]}
	var json_payload = JSON.stringify(payload)  
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, json_payload) 
	print(error) 
	if error != OK:
		print("Request failed: ", error)
	
	

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var response_json = JSON.parse_string(body.get_string_from_utf8())
		print("Groq LLM Response:", response_json["choices"][0]["message"]["content"])
		var command = response_json["choices"][0]["message"]["content"]
		if players.has("llama") && players_node.has_node("Player") :
			var active_player = players_node.get_node("Player")
			active_player.execute_command(command)
	else:
		print("API Request Failed. Code:", response_code)
