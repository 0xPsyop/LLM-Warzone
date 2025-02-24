extends Node

@onready var http = $HTTPRequest  # Reference HTTPRequest node

var last_sent_state = {}

# Function to collect game state
#func get_game_state():
	#return {
		#"player_position": get_player_position(),
		#"enemy_positions": get_enemy_positions(),
		#"obstacles": get_obstacle_positions(),
		#"game_map": get_grid_representation()
	#}

# Function to send game state only if changes occurred
#func send_game_state():
	#var new_state = get_game_state()
#
	#if new_state != last_sent_state:  # Avoid redundant requests
		#last_sent_state = new_state
		#send_to_llm(new_state)

# Send data to LLM API
func send_to_llm(state):
	var json = JSON.stringify(state)
	var url = "https://your-llm-api.com/update"
	http.request(url, [], HTTPClient.METHOD_POST, json)

# Process LLM response when request is completed
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var response_text = body.get_string_from_utf8()
		process_llm_command(response_text)

# Connect HTTPRequest signal in `_ready()`
func _ready():
	http.request_completed.connect(_on_request_completed)


func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	pass # Replace with function body.
