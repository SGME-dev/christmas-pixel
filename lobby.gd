extends Node3D

class_name lobby

var effect
var recording

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var http_request: HTTPRequest = $CanvasLayer/HTTPRequest
@onready var lan_ip_label: Label = $CanvasLayer/Label
@onready var public_ip_label: Label = $CanvasLayer/Label2
var local_addresses = IP.get_local_addresses()
var actual_port: int = 50170
var port: int = 50170
const DEFAULT_SERVER_IP: String = "127.0.0.1" # IPv4 localhost
var MAX_CONNECTIONS: int = 20
var Jesus_pass = 0
var user = FileAccess.open("user://username.save", FileAccess.READ).get_line()
@export var dedserver: bool = false
var ip: String

static var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene

func is_dedicated_server():
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg == "--headless":
			return true
	return false

@rpc("any_peer", "call_local", "unreliable")
func send_rec_data(rec_data):
	var sample = AudioStreamWAV.new()
	sample.data = rec_data
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = AudioServer.get_mix_rate()*2
	$AudioStreamPlayer2.stream = sample
	$AudioStreamPlayer2.play()
	print("Received audio packet of size: ", rec_data.size())

func _on_send_recording_timer_timeout():
	var rec = effect.get_recording()
	if rec != null:
		# The line below only works if you are connected to a server
		if multiplayer.multiplayer_peer != null:
			rpc("send_rec_data", rec.data)
	if multiplayer.multiplayer_peer != null:
		if multiplayer.get_peers().size() > 0:
			recording = effect.get_recording()
			effect.set_recording_active(false)
			if recording.data != null:
				rpc("send_rec_data",recording.data)
				effect.set_recording_active(true)


func _ready() -> void:
	
	if OS.has_feature("dedicated_server"):
		print("Started the server...")
		_on_host_pressed()
		%host.hide()
		%join.hide()
		%LineEdit.hide()
		%LineEdit2.hide()
		$Sprite3D.hide()
		dedserver = true
		var path = OS.get_executable_path().get_base_dir() + "max_players.limit"
		
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			var player_limit = file.get_line()
			file.close()
			if int(player_limit) > 0 and int(player_limit) < 101:
				MAX_CONNECTIONS = int(player_limit)
	if !OS.has_feature("dedicated_server"):
		var idx = AudioServer.get_bus_index("record")
		effect = AudioServer.get_bus_effect(idx,0)
		print(effect)
		effect.set_recording_active(true)
		get_tree().set_auto_accept_quit(false)
	


func _on_host_pressed() -> void:
	$Sprite3D.hide()
	peer.create_server(port, MAX_CONNECTIONS)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	multiplayer.get_peers()
	$Narrorator/AudioStreamPlayer.play()
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
	var local_addresse = IP.get_local_addresses()
	
	var found_desired_ipv4 = false
	var current_lan_ip = "Not Found" 
	
	for address in local_addresse:
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
	if local_addresse.is_empty():
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
	$Sprite3D.hide()
	if address.is_empty() or address == "localhost":
		address = DEFAULT_SERVER_IP
	if %LineEdit2.text.is_empty():
		port = actual_port
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	$Narrorator/AudioStreamPlayer.play()
	%host.hide()
	%join.hide()
	%LineEdit.hide()
	%LineEdit2.hide()
	$Sprite3D38.hide()
	$CanvasLayer/Panel.hide()
	
	$CanvasLayer/Timer.start()


func add_player(id: int = 1) -> void:
	var player: CharacterBody3D = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	

func exit_game(id: int) -> void:
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)
	msg_leave.rpc(str("\n" + user))



func del_player(id: int) -> void:
	rpc("_del_player" ,id)
	
@rpc("any_peer","call_local")
func  _del_player(id: int) -> void:
	get_node(str(id)).queue_free()
	

func _on_connected_fail() -> void:
	multiplayer.multiplayer_peer = null


func _on_area_3d_body_entered(body: player) -> void:
	$directions/Sprite3D.hide()
	$directions/Sprite3D2.show()
	$Area3D2/CollisionShape3D.set_deferred("disabled", true)



func set_active_environment(environment: WorldEnvironment):
	# Set the provided environment as the active environment
	get_viewport().world_3d.environment = environment.environment



func _on_next_pressed() -> void:
	
	var timer = Timer.new()
	var story: int = 0
	if $CanvasLayer/TextEdit.text == "There was a woman called Mary. She was engaged to marry a man called Joseph.":
		$Narrorator/AudioStreamPlayer2.play()
		$CanvasLayer/TextEdit.text = "Then when she whent home, a angel called gabriel appered. The angel Gabriel told Mary she was favored by God, would conceive and give birth to a son named Jesus, who would be great and called the Son of the Most High, and would reign forever. Gabriel also explained that the Holy Spirit would come upon her, and the power of God would overshadow her, enabling this miraculous conception."
		$AnimatableBody3D2/AnimationPlayer.play("move")
	if $CanvasLayer/TextEdit.text == "At first Joseph did not understand this all but then The angel explained it to him.":
		$CanvasLayer/TextEdit.text = "Then Joseph did what the angel said."
		$Narrorator/AudioStreamPlayer6.play()
	if $CanvasLayer/TextEdit.text == "Some shepards saw a bright light, then a angel appered and said Do not be afraid, the messiah has been born in a barn, then more angels appeared and sang a song. ":
		$CanvasLayer/TextEdit.text = "The Shepards found Jesus and told everyone about it. Mary made sure that she would remember all these things. The Separds came back to the field and praised the lord."
		$Narrorator/AudioStreamPlayer10.play()
	if $CanvasLayer/TextEdit.text == "When Herod the king ruled, he heard that Jesus is going to be the new king.":
		$CanvasLayer/TextEdit.text = "So he he lied to the wise men and said to them, i want to praise Jesus so find Jesus."
		$Narrorator/AudioStreamPlayer13.play()
	if $CanvasLayer/TextEdit.text == "When the wise men were going to Jesus they followed a star, God told them not to go back to Herod.":
		$CanvasLayer/TextEdit.text = "When they arrived they Gave Jesus Gifts that is Gold, frankincense and myrrh"
		$Narrorator/AudioStreamPlayer15.play()
	




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
	$Narrorator/AudioStreamPlayer5.play()
	$CanvasLayer/TextEdit.text = "At first Joseph did not understand this all but then The angel explained it to him."


func _on_area_3d_4_body_entered(body: player) -> void:
	set_active_environment($WorldEnvironment2)
	$Narrorator/AudioStreamPlayer12.play()
	$CanvasLayer/TextEdit.text = "After that, the ruler of Israel wanted to count how much people was in Israel so he commanded all the people to go to their home. Josephs and Marys hometown was Bethlehem so they went to Bethlehem."
	body.global_position = $StaticBody3D17.global_position


func _on_area_3d_5_body_entered(body: player) -> void:
	$directions/Sprite3D3.show()
	$directions/Sprite3D2.hide()
	$Narrorator/AudioStreamPlayer7.play()
	$CanvasLayer/TextEdit.text = "When they arrived, they could not find a place to stay."
	body.global_position = $StaticBody3D19.global_position


func _on_area_3d_6_body_entered(body: Node3D) -> void:
	$CanvasLayer/TextEdit.text = "So Jesus was born in a barn."
	$Narrorator/AudioStreamPlayer8.play()
	
	$directions/Sprite3D4.show()
	$directions/Sprite3D3.hide()
	$Area3D8/CollisionShape3D.set_deferred("disabled", true)
	$Area3D6/CollisionShape3D.set_deferred("disabled", true)


func _on_area_3d_7_body_entered(body: player) -> void:
	$directions/Sprite3D5.show()
	$directions/Sprite3D4.hide()
	$Narrorator/AudioStreamPlayer9.play()
	$CanvasLayer/TextEdit.text = "Some shepards saw a bright light, then a angel appered and said Do not be afraid, the messiah has been born in a barn, then more angels appeared and sang a song. "
	$AnimatableBody3D11.show()
	$AnimatableBody3D12.show()
	$AnimatableBody3D13.show()
	$Area3D6/CollisionShape3D.set_deferred("disabled", true)


func _on_area_3d_9_body_entered(body: player) -> void:
	Jesus_pass += 1
	if Jesus_pass == 1:
		
		$CanvasLayer/TextEdit.text = "When Herod the king ruled, he heard that Jesus is going to be the new king."
		$Narrorator/AudioStreamPlayer11.play()
		body.global_position = $StaticBody3D41.global_position
	if Jesus_pass == 2:
		$CanvasLayer/TextEdit.text = "Herod was angry because the wise men did not come back so he dicided to kill all babys in Jerlusalem. God warned Joseph about this so they moved to Eygypt until herod was gone, then they went to nasareth because herods son was in Jerlusalem"
		set_active_environment($WorldEnvironment)
		$Narrorator/AudioStreamPlayer16.play()
		body.global_position = $StaticBody3D53.global_position
	


func _on_area_3d_10_body_entered(body: player) -> void:
	$directions/Sprite3D6.show()
	$directions/Sprite3D5.hide()
	body.global_position = $StaticBody3D19.global_position
	$CanvasLayer/TextEdit.text = "When the wise men were going to Jesus they followed a star, God told them not to go back to Herod."
	$Narrorator/AudioStreamPlayer14.play()
	$AnimatableBody3D22.show()
	$AnimatableBody3D23.show()
	$AnimatableBody3D24.show()


func _on_audio_stream_player_2_finished() -> void:
	$Narrorator/AudioStreamPlayer3.play()


func _on_audio_stream_player_3_finished() -> void:
	$Narrorator/AudioStreamPlayer4.play()

func _on_button_pressed() -> void:
	msg_rec.rpc(user, $CanvasLayer/Chat/LineEdit.text)
	

@rpc("any_peer", "call_local")
func msg_rec(user: String, msg: String) -> void:
	$CanvasLayer/Chat.text += str("\n" + user + ":" + msg)
	print("\n" + user + ":" + $CanvasLayer/Chat/LineEdit.text)

@rpc("any_peer", "call_local")
func msg_join(name: String) -> void:
	$CanvasLayer/Chat.text += str(name + " joined the game")
	print(name + " joined the game")

@rpc("any_peer", "call_local")
func msg_leave(name: String) -> void:
	$CanvasLayer/Chat.text += str(name + " left the game")
	print(name + " left the game")


func _on_timer_timeout() -> void:
	msg_join.rpc(str("\n" + user))

@rpc("any_peer", "call_remote", "reliable")
func save_pos_on_server(pos: Vector3, namer: String) -> void:
	var Exepath = OS.get_executable_path().get_base_dir()
	# Double check: Only the server should execute this file logic
	if dedserver == true:
		var path = Exepath + "/data/Player/location/" + namer + ".save"
		var posav = FileAccess.open(path, FileAccess.WRITE)
		
		if posav:
			posav.store_var(pos)
			

@rpc("any_peer", "call_remote", "reliable")
func teleport_player(sender_id, new_position):
	# This runs on the client side
	get_node(str(sender_id)).global_position = new_position
	print("Teleported to: ", new_position)


@rpc("any_peer", "call_remote", "reliable")
func load_pos_on_server(namer: String):
	if not dedserver: return # Safety check
	
	var path = OS.get_executable_path().get_base_dir() + "/data/Player/location/" + namer + ".save"
	
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var saved_pos = file.get_var(true) # Assuming this is a Vector3 or Vector2
		file.close()
		
		# Find who asked for this and tell THEM to teleport
		var sender_id = multiplayer.get_remote_sender_id()
		teleport_player.rpc(sender_id, saved_pos)


func _on_area_3d_15_body_entered(body: player, namer: String = str(user)) -> void:
	load_pos_on_server.rpc_id(1, user)
	$Area3D15/CollisionShape3D.queue_free()

@rpc("any_peer", "call_remote", "reliable")
func save_bans_on_server(namer: String) -> void:
	var Exepath = OS.get_executable_path().get_base_dir()
	# Double check: Only the server should execute this file logic
	if dedserver == true:
		var path = Exepath + "/data/bans/bans.txt"
		var bans = FileAccess.open(path, FileAccess.READ_WRITE)
		var nbans = bans.get_as_text()
		bans.store_string(nbans + "\n" + namer)
		

@rpc("any_peer", "call_remote", "reliable")
func save_ban_ips_on_server(namer: String) -> void:
	var Exepath = OS.get_executable_path().get_base_dir()
	# Double check: Only the server should execute this file logic
	if dedserver == true:
		var path = Exepath + "/data/ban-ips/ban-ips.txt"
		var bans = FileAccess.open(path, FileAccess.READ_WRITE)
		var nbans = bans.get_as_text()
		bans.store_string(nbans + "\n" + namer)
		

@rpc("any_peer", "call_remote", "reliable")
func load_bans_on_server():
	if not dedserver: return # Safety check
	
	var path = OS.get_executable_path().get_base_dir() + "/data/bans/bans.txt"
	
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var saved_bans = file.get_as_text()
		file.close()
		
		
		var sender_id = multiplayer.get_remote_sender_id()
		if user in saved_bans:
			exit_game(sender_id)

@rpc("any_peer", "call_remote", "reliable")
func load_ban_ips_on_server():
	if not dedserver: return # Safety check
	
	var path = OS.get_executable_path().get_base_dir() + "/data/ban-ips/ban-ips.txt"
	
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var saved_bans = file.get_as_text()
		file.close()
		
		
		var sender_id = multiplayer.get_remote_sender_id()
		$CanvasLayer/HTTPRequest2.request("https://ipv4.icanhazip.com")
		if ip in saved_bans:
			exit_game(sender_id)

func _on_ban_pressed() -> void:
	save_bans_on_server.rpc_id(1, $CanvasLayer/ban.text)


func _on_banip_pressed() -> void:
	save_ban_ips_on_server.rpc_id(1, $"CanvasLayer/ban-ip".text)


func _on_http_request_2_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if !OS.has_feature("dedicated_server"):
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			# If the request was successful and the HTTP status code is 200 (OK).
			
			# Convert the raw byte array body to a UTF-8 string.
			# .strip_edges() removes any leading/trailing whitespace (like newlines).
			var public_ip = body.get_string_from_utf8().strip_edges()
			
			print("Public WAN IPv4 Address: " + public_ip)
			ip = public_ip
		else:
			# If the request failed or returned a non-200 status code.
			print("Failed to get public IP.")
			
			print("HTTP Response Code: ", response_code) # HTTP status code
			
			
			# You might want to add more specific error handling here based on result and response_code.
			# For example:
			# if result == HTTPRequest.RESULT_CANT_RESOLVE:
			#     print("Error: Could not resolve host (no internet connection or DNS issue).")
			# if response_code == 404:
			#     print("Error: Service URL not found.")
			

var mute: bool = false
var mute_all: bool = false


func _on_mute_pressed() -> void:
	if mute == false:
		mute = true
		effect.set_recording_active(false)
		$AudioStreamPlayer2.volume_db = -80
		$AudioStreamRecord.volume_db = -80
		$CanvasLayer/mute.icon = ResourceLoader.load("res://mute.png")
		return
	if mute == true:
		mute = false
		effect.set_recording_active(true)
		$AudioStreamPlayer2.volume_db = 10.478
		$AudioStreamRecord.volume_db = 0
		$CanvasLayer/mute.icon = ResourceLoader.load("res://unmute.png")
		return


func _on_mute_2_pressed() -> void:
	if mute_all == false:
		$CanvasLayer/mute2.text = "unmute all"
		mute_all = true
		effect.set_recording_active(false)
		$AudioStreamPlayer2.volume_db = -80
		$AudioStreamRecord.volume_db = -80
		var bus_idx = AudioServer.get_bus_index("record")
		AudioServer.set_bus_mute(bus_idx, true)
		
		return
	if mute_all == true:
		$CanvasLayer/mute2.text = "mute all"
		mute_all = false
		effect.set_recording_active(true)
		$AudioStreamPlayer2.volume_db = 10.478
		$AudioStreamRecord.volume_db = 0
		var bus_idx = AudioServer.get_bus_index("record")
		AudioServer.set_bus_mute(bus_idx, false)
		
		return
