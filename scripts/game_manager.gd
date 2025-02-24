extends Node

@onready var http = $HTTPRequest  # Reference HTTPRequest node

var GROQ_API_KEY = ""

func _ready():
	var config = ConfigFile.new()
	var err = config.load("res://secrets.cfg")  # Use "user://" for persistent storage
	if err == OK:
		GROQ_API_KEY = config.get_value("secrets", "GROQ_API_KEY", "")
		print("Loaded API Key:", GROQ_API_KEY)
		send_groq_request()

func send_groq_request():
	var url = "https://api.groq.com/openai/v1/chat/completions"
	var headers = [
		 "Authorization: Bearer " + GROQ_API_KEY,  
		 "Content-Type: application/json"
	]
	
	var payload = {
		"model": "llama-3.3-70b-versatile",  # Specify the LLM model
		"messages": [
			{
				 "role": "user",
				"content": "Explain the importance of fast language models"
			}
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
	else:
		print("API Request Failed. Code:", response_code)
