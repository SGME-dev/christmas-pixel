extends Node3D

class_name easteregghunt

@onready var label_3: TextEdit = $Label3

@onready var http_request: HTTPRequest = $CanvasLayer/HTTPRequest
@onready var lan_ip_label: Label = $CanvasLayer/Label
@onready var public_ip_label: Label = $CanvasLayer/Label2
@export var easter_egg: int = 0
var port: int = 50170
const DEFAULT_SERVER_IP: String = "127.0.0.1" # IPv4 localhost
var MAX_CONNECTIONS: int = 20
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

func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		print("Started the server...")
		_on_host_pressed()
		%host.hide()
		%join.hide()
		%LineEdit.hide()
		%LineEdit2.hide()
		$Sprite3D38.hide()
		$CanvasLayer/Panel.hide()
		dedserver = true
		var path = OS.get_executable_path().get_base_dir() + "max_players.limit"
		
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			var player_limit = file.get_line()
			file.close()
			if int(player_limit) > 0 and int(player_limit) < 101:
				MAX_CONNECTIONS = int(player_limit)

func _physics_process(delta: float) -> void:
	if easter_egg == 12:
		$Label.text = "Go to the electricity sound!"
	$Label2.text = str(easter_egg, "/12")

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
	
	
	
	
	
	
	%host.hide()
	%join.hide()
	%LineEdit.hide()
	%LineEdit2.hide()
	$Sprite3D38.hide()
	$CanvasLayer/Panel.hide()
	$"NewPiskel(24)(1)".hide()


func _on_join_pressed(address: String = str(%LineEdit.text)) -> void:
	if address.is_empty() or address == "localhost":
		address = DEFAULT_SERVER_IP
	peer.create_client(address, int(%LineEdit2.text))
	multiplayer.multiplayer_peer = peer
	%host.hide()
	%join.hide()
	%LineEdit.hide()
	%LineEdit2.hide()
	$Sprite3D38.hide()
	$CanvasLayer/Panel.hide()
	$"NewPiskel(24)(1)".hide()
	
	print(user + " joined the game")
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
	label_3.show()
	label_3.text += "\nEaster egg 1:\nIsaiah 9:6 — For to us a child is born, to us a son is given... and he will be called Wonderful Counselor, Mighty God, Everlasting Father, Prince of Peace.\nPoem:\nA child is born to bear the weight, Of every heart and every state. A Counselor to guide the way, A Prince of Peace for a brand new day."
	$Area3D.hide()
	$Area3D/CollisionShape3D.set_deferred("disabled", true)
	easter_egg += 1


func _on_area_3d_2_body_entered(body: player) -> void:
	label_3.show()
	label_3.text += "\nEaster egg 2:\nLuke 1:38 — I am the Lord’s servant, Mary answered. May your word to me be fulfilled. Then the angel left her.\nPoem:\nShe bowed her head to heaven’s plan, Beyond the reach of mortal man. With Let it be, the world was changed, As grace and earth were rearranged."
	$Area3D2.hide()
	$Area3D2/CollisionShape3D.set_deferred("disabled", true)
	easter_egg += 1


func _on_area_3d_3_body_entered(body: player) -> void:
	label_3.show()
	label_3.text += "\nEaster egg 3:\nMatthew 1:21 — The angel said, ...You are to give him the name Jesus, because he will save his people from their sins.\nPoem:\nNot for a crown of polished gold, Nor for a story proudly told. He took a name that means to save, To bridge the gap from crib to grave."
	$Area3D3.hide()
	$Area3D3/CollisionShape3D.set_deferred("disabled", true)
	easter_egg += 1
	


func _on_area_3d_4_body_entered(body: player) -> void:
	label_3.show()
	label_3.text += "\nEaster egg 4:\nLuke 2:4-5 — So Joseph also went up from the town of Nazareth... to Bethlehem the town of David... He went there to register with Mary, who was pledged to be married to him and was expecting a child.\nPoem:\nOn dusty roads through cold and grit, The lamp of prophecy was lit. Toward the city, small and old, The greatest story would unfold."
	$Area3D4.hide()
	$Area3D4/CollisionShape3D.set_deferred("disabled", true)
	easter_egg += 1


func _on_area_3d_5_body_entered(body: player) -> void:
	label_3.show()
	label_3.text += "\nEaster egg 5:\nLuke 2:7 — And she gave birth to her firstborn, a son. She wrapped him in cloths and placed him in a manger, because there was no guest room available for them.\nPoem:\nNo velvet bed, no palace hall, But wood and straw within a stall. The Lord of all, in silence deep, Was rocked by Mary’s arms to sleep."
	$Area3D5.hide()
	$Area3D5/CollisionShape3D.set_deferred("disabled", true)
	easter_egg += 1


func _on_area_3d_6_body_entered(body: player) -> void:
	label_3.show()
	label_3.text += "\nEaster egg 6:\nLuke 2:10 — But the angel said to them, Do not be afraid. I bring you good news that will cause great joy for all the people.\nPoem:\nFear not, the angel’s voice rang clear, To calm the trembling and the fear. A joy that ripples through the years, To dry the world of all its tears."
	$Area3D6.hide()
	$Area3D6/CollisionShape3D.set_deferred("disabled", true)
	easter_egg += 1


func _on_area_3d_7_body_entered(body: player) -> void:
	label_3.show()
	label_3.text += "\nEaster egg 7:\nLuke 2:14 — Glory to God in the highest heaven, and on earth peace to those on whom his favor rests.\nPoem:\nThe sky erupted into song, Where light and melody belong. A bridge of peace from sky to floor, To dwell with us forevermore."
	$Area3D7.hide()
	$Area3D7/CollisionShape3D.set_deferred("disabled", true)
	easter_egg += 1

func _on_area_3d_8_body_entered(body: player) -> void:
	label_3.show()
	label_3.text += "\nEaster egg 8:\nMatthew 2:9-10 — After they had heard the king, they went on their way, and the star they had seen when it rose went ahead of them until it stopped over the place where the child was. When they saw the star, they were overjoyed.\nPoem:\nA silver light across the blue, To guide the seekers, wise and true. It paused above the humble place, To shine upon the Savior’s face."
	$Area3D8.hide()
	$Area3D8/CollisionShape3D.set_deferred("disabled", true)
	easter_egg += 1


func _on_area_3d_9_body_entered(body: player) -> void:
	label_3.show()
	label_3.text += "\nEaster egg 9:\nMatthew 2:11 — On coming to the house, they saw the child with his mother Mary, and they bowed down and worshiped him. Then they opened their treasures and presented him with gifts of gold, frankincense and myrrh.\nPoem:\nThey brought the wealth of distant lands, And placed it in his tiny hands. Gold for a King, and spice for prayer, To honor Him who rested there."
	$Area3D9.hide()
	$Area3D9/CollisionShape3D.set_deferred("disabled", true)
	easter_egg += 1


func _on_area_3d_10_body_entered(body: player) -> void:
	label_3.show()
	label_3.text += "\nEaster egg 10:\nJohn 1:14 — The Word became flesh and made his dwelling among us. We have seen his glory, the glory of the one and only Son, who came from the Father, full of grace and truth.\nPoem:\nThe Voice that spoke the stars to flight, Became a breath within the night. The Infinite took form and bone, To make our human heart His home."
	$Area3D10.hide()
	$Area3D10/CollisionShape3D.set_deferred("disabled", true)
	easter_egg += 1


func _on_area_3d_11_body_entered(body: player) -> void:
	label_3.show()
	label_3.text += "\nEaster egg 11:\n2 Corinthians 8:9 — For you know the grace of our Lord Jesus Christ, that though he was rich, yet for your sake he became poor, so that you through his poverty might become rich.\nPoem:\nHe left the riches of the sky, Beneath a human roof to lie. He traded all His heavenly wealth, To bring our broken spirits health."
	$Area3D11.hide()
	$Area3D11/CollisionShape3D.set_deferred("disabled", true)
	easter_egg += 1


func _on_area_3d_12_body_entered(body: player) -> void:
	label_3.show()
	label_3.text += "\nEaster egg 12:\nJohn 3:16 — For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.\nPoem:\nThe widest love the world has known, In one small child was clearly shown. A gift of grace, a life of light, To guide us through the darkest night."
	$Area3D12.hide()
	$Area3D12/CollisionShape3D.set_deferred("disabled", true)
	easter_egg += 1


func _on_area_3d_13_body_entered(body: player) -> void:
	if easter_egg == 12:
		Input.action_press("quit")
	else:
		body.label_2.text = "Collect all 12 easter eggs!"
		body.label_2.show()

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

func _on_buttons_pressed() -> void:
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
			
