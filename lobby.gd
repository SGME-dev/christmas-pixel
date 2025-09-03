extends Node3D

class_name lobby

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var http_request: HTTPRequest = $CanvasLayer/HTTPRequest
@onready var lan_ip_label: Label = $CanvasLayer/Label
@onready var public_ip_label: Label = $CanvasLayer/Label2
var local_addresses = IP.get_local_addresses()
var actual_port: int = 15780
var port: int = 15780
const DEFAULT_SERVER_IP: String = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS: int = 20


static var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene

func is_dedicated_server():
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg == "--headless":
			return true
	return false

func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		print("Started the server...")
		_on_host_pressed()
		%host.hide()
		%join.hide()
		%LineEdit.hide()
		%LineEdit2.hide()
		$Sprite3D38.hide()
	
	


func _on_host_pressed() -> void:
	
	peer.create_server(port, MAX_CONNECTIONS)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	multiplayer.get_peers()
	
	# Connect the request_completed signal to our handler function.
	# This signal is emitted when the HTTP request finishes, whether successful or not.
	http_request.request_completed.connect(_on_http_request_completed)
	
	print("--- Attempting to get Public WAN IPv4 Address ---")
	public_ip_label.text = "Fetching Public IP..." # Update label to show fetching status
	
	# Make an HTTP GET request to a service that returns the public IP.
	# icanhazip.com is a simple service that returns the IP address as plain text.
	var error = http_request.request("https://ipv4.icanhazip.com")
	
	if error != OK:
		# If there was an error initiating the request (e.g., invalid URL, no network interface).
		print("Failed to start HTTP request: ", error)
		public_ip_label.text = "Error: Failed to start request."
	
	
	
	
	# --- LAN IP Address Retrieval ---
	print("--- IPv4 Addresses ---")
	var local_addresses = IP.get_local_addresses()
	
	var found_desired_ipv4 = false
	var current_lan_ip = "Not Found" 
	
	for address in local_addresses:
		if "." in address and ":" not in address:
			if address.begins_with("192.168.") or \
			   address.begins_with("10.") or \
			   (address.begins_with("172.") and int(address.split(".")[1]) >= 16 and int(address.split(".")[1]) <= 31):
				
				print("Lan IPV4 address: " + address)
				lan_ip_label.text = str("(Use For LAN)Private IPv4 Address: ", address)
				current_lan_ip = address
				found_desired_ipv4 = true
				break
	
	if not found_desired_ipv4:
		print("No suitable local IPv4 address found (e.g., not in common private ranges).")
		lan_ip_label.text = "Lan IPV4 address: Not Found"
	if local_addresses.is_empty():
		print("No local addresses found at all.")
		lan_ip_label.text = "Lan IPV4 address: No Addresses"
	
	
	
	
	
	# --- Your existing UI/Animation code ---
	%host.hide()
	%join.hide()
	%LineEdit.hide()
	%LineEdit2.hide()
	$Sprite3D38.hide()
	$CanvasLayer/Panel.hide()


func _on_join_pressed(address: String = str(%LineEdit.text), port: int = int(%LineEdit2.text)) -> void:
	if address.is_empty() or address == "localhost":
		address = DEFAULT_SERVER_IP
	if %LineEdit2.text.is_empty():
		port = actual_port
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	
	%host.hide()
	%join.hide()
	%LineEdit.hide()
	%LineEdit2.hide()
	$Sprite3D38.hide()
	$CanvasLayer/Panel.hide()

func add_player(id: int = 1) -> void:
	var player: CharacterBody3D = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	

func exit_game(id: int) -> void:
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)


func del_player(id: int) -> void:
	rpc("_del_player" ,id)
	
@rpc("any_peer","call_local")
func  _del_player(id: int) -> void:
	get_node(str(id)).queue_free()
	

func _on_connected_fail() -> void:
	multiplayer.multiplayer_peer = null


func _on_area_3d_body_entered(body: player) -> void:
	$Area3D2/CollisionShape3D.set_deferred("disabled", true)



func set_active_environment(environment: WorldEnvironment):
	# Set the provided environment as the active environment
	get_viewport().world_3d.environment = environment.environment



func _on_next_pressed() -> void:
	
	var timer = Timer.new()
	var story: int = 0
	if $CanvasLayer/TextEdit.text == "There was a woman called Mary. She was engaged to marry a man called Joseph.":
		$CanvasLayer/TextEdit.text = "Then when she whent home, a angel called gabriel appered. The angel Gabriel told Mary she was favored by God, would conceive and give birth to a son named Jesus, who would be great and called the Son of the Most High, and would reign forever. Gabriel also explained that the Holy Spirit would come upon her, and the power of God would overshadow her, enabling this miraculous conception."
		$AnimatableBody3D2/AnimationPlayer.play("move")
	if $CanvasLayer/TextEdit.text == "At first Joseph did not understand this all but then The angel explained it to him.":
		$CanvasLayer/TextEdit.text = "Then Joseph did what the angel said."
	if $CanvasLayer/TextEdit.text == "Some shepards saw a bright light, then a angel appered and said Do not be afraid, the messiah has been born in a barn, then more angels appeared and sang a song.":
		$CanvasLayer/TextEdit.text = "The Shepards found Jesus and told everyone about it. Mary made sure that she would remember all these things. The Separds came back to the field and praised the lord."
	
	




func _on_area_3d_13_body_entered(body: player) -> void:
	body.global_position = $StaticBody3D23/Marker3D.global_position
	print(1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11 + 12 + 13 + 14 + 15 + 16 + 17 + 18 + 19 + 20 + 21 + 22 + 23 + 24 + 25 + 26 + 27 + 28 + 29 + 30 + 31 + 32 + 33 + 34 + 35 + 36 + 37 + 38 + 39 + 40 + 41 + 42 + 43 + 44 + 45 + 46 + 47 + 48 + 49 + 50)


func _on_area_3d_14_body_entered(body: player) -> void:
	body.global_position = Vector3(0, 0, 0)

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		# If the request was successful and the HTTP status code is 200 (OK).
		
		# Convert the raw byte array body to a UTF-8 string.
		# .strip_edges() removes any leading/trailing whitespace (like newlines).
		var public_ip = body.get_string_from_utf8().strip_edges()
		
		print("Public WAN IPv4 Address: " + public_ip)
		public_ip_label.text = "(Use after port forwarding)Public WAN IPv4 Address: " + public_ip # Update the UI label
	else:
		# If the request failed or returned a non-200 status code.
		print("Failed to get public IP.")
		
		print("HTTP Response Code: ", response_code) # HTTP status code
		public_ip_label.text = "Error: Could not get public IP."
		
		# You might want to add more specific error handling here based on result and response_code.
		# For example:
		# if result == HTTPRequest.RESULT_CANT_RESOLVE:
		#     print("Error: Could not resolve host (no internet connection or DNS issue).")
		# if response_code == 404:
		#     print("Error: Service URL not found.")


func _on_area_3d_3_body_entered(body: player) -> void:
	$CanvasLayer/TextEdit.text = "At first Joseph did not understand this all but then The angel explained it to him."


func _on_area_3d_4_body_entered(body: player) -> void:
	$CanvasLayer/TextEdit.text = "After that, the ruler of Israel wanted to count how much people was in Israel so he commanded all the people to go to their home. Josephs and Marys hometown was Bethlehem so they went to Bethlehem."
	body.global_position = $StaticBody3D17.global_position


func _on_area_3d_5_body_entered(body: Node3D) -> void:
	$CanvasLayer/TextEdit.text = "When they arrived, they could not find a place to stay."
	body.global_position = $StaticBody3D19.global_position


func _on_area_3d_6_body_entered(body: Node3D) -> void:
	$CanvasLayer/TextEdit.text = "So Jesus was born in a barn."
	$Area3D8/CollisionShape3D.set_deferred("disabled", true)


func _on_area_3d_7_body_entered(body: Node3D) -> void:
	$CanvasLayer/TextEdit.text = "Some shepards saw a bright light, then a angel appered and said Do not be afraid, the messiah has been born in a barn, then more angels appeared and sang a song. "
	$AnimatableBody3D11.show()
	$AnimatableBody3D12.show()
	$AnimatableBody3D13.show()
	$Area3D6/CollisionShape3D.set_deferred("disabled", true)
