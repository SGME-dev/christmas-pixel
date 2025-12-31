extends Node3D

class_name lobby_bible_verses

@onready var lan_ip_label: Label = $CanvasLayer/Label
@onready var public_ip_label: Label = $CanvasLayer/Label2
@onready var http_request: HTTPRequest = $CanvasLayer/HTTPRequest
@onready var label: TextEdit = $Label
var port: int = 50170
const DEFAULT_SERVER_IP: String = "127.0.0.1" # IPv4 localhost
var MAX_CONNECTIONS: int = 20
@export var bible_verses: int = 0
var user = FileAccess.open("user://username.save", FileAccess.READ).get_line()
@export var dedserver: bool = false
var ip: String

static var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene

func  _physics_process(delta: float) -> void:
	$Label2.text = str("50/" + str(bible_verses))

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
		$Sprite3D178.hide()
		dedserver = true
		var path = OS.get_executable_path().get_base_dir() + "max_players.limit"
		
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			var player_limit = file.get_line()
			file.close()
			if int(player_limit) > 0 and int(player_limit) < 101:
				MAX_CONNECTIONS = int(player_limit)


func _on_host_pressed() -> void:
	$Sprite3D178.hide()
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


func _on_join_pressed(address: String = str(%LineEdit.text)) -> void:
	$Sprite3D38.hide()
	$Sprite3D178.hide()
	if address.is_empty() or address == "localhost":
		address = DEFAULT_SERVER_IP
	if %LineEdit2.text.is_empty():
		%LineEdit2.text = str(50170)
	peer.create_client(address, int(%LineEdit2.text))
	multiplayer.multiplayer_peer = peer
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
	label.text += "\nIsaiah 7:14 - Therefore the Lord himself will give you a sign: The virgin will conceive and give birth to a son, and will call him Immanuel."
	label.show()
	$Area3D/CollisionShape3D.set_deferred("disabled", true)
	$Area3D.hide()
	body.Area3d = $Area3D
	bible_verses += 1
	


func _on_area_3d_2_body_entered(body: player) -> void:
	label.text += "\nIsaiah 9:6 - For to us a child is born, to us a son is given, and the government will be on his shoulders. And he will be called Wonderful Counselor, Mighty God, Everlasting Father, Prince of Peace."
	$Area3D2/CollisionShape3D.set_deferred("disabled", true)
	$Area3D2.hide()
	body.Area3d = $Area3D2
	bible_verses += 1

func _on_area_3d_3_body_entered(body: player) -> void:
	label.text += "\nMicah 5:2 - But you, Bethlehem Ephrathah, though you are small among the clans of Judah, out of you will come for me one who will be ruler over Israel, whose origins are from of old, from ancient times."
	$Area3D3/CollisionShape3D.set_deferred("disabled", true)
	$Area3D3.hide()
	body.Area3d = $Area3D3
	bible_verses += 1

func _on_area_3d_4_body_entered(body: player) -> void:
	label.text += "\nJeremiah 23:5 - The days are coming, declares the Lord, when I will raise up for David a righteous Branch, a King who will reign wisely and do what is just and right in the land."
	$Area3D4/CollisionShape3D.set_deferred("disabled", true)
	$Area3D4.hide()
	body.Area3d = $Area3D4
	bible_verses += 1

func _on_area_3d_5_body_entered(body: player) -> void:
	label.text += "\nIsaiah 11:1 - A shoot will come up from the stump of Jesse; from his roots a Branch will bear fruit."
	$Area3D5/CollisionShape3D.set_deferred("disabled", true)
	$Area3D5.hide()
	body.Area3d = $Area3D5
	bible_verses += 1

func _on_area_3d_6_body_entered(body: player) -> void:
	label.text += "\nLuke 1:26-27 - In the sixth month of Elizabeth’s pregnancy, God sent the angel Gabriel to Nazareth, a town in Galilee, to a virgin pledged to be married to a man named Joseph, a descendant of David. The virgin’s name was Mary."
	$Area3D6/CollisionShape3D.set_deferred("disabled", true)
	$Area3D6.hide()
	body.Area3d = $Area3D6
	bible_verses += 1

func _on_area_3d_7_body_entered(body: player) -> void:
	label.text += "\nLuke 1:28 - The angel went to her and said, Greetings, you who are highly favored! The Lord is with you."
	$Area3D7/CollisionShape3D.set_deferred("disabled", true)
	$Area3D7.hide()
	body.Area3d = $Area3D7
	bible_verses += 1

func _on_area_3d_8_body_entered(body: player) -> void:
	label.text += "\nLuke 1:30-31 - But the angel said to her, Do not be afraid, Mary; you have found favor with God. You will conceive and give birth to a son, and you are to call him Jesus."
	$Area3D8/CollisionShape3D.set_deferred("disabled", true)
	$Area3D8.hide()
	body.Area3d = $Area3D8
	bible_verses += 1



func _on_area_3d_10_body_entered(body: player) -> void:
	label.text += "\nLuke 1:34 - How will this be, Mary asked the angel, since I am a virgin?"
	$Area3D10/CollisionShape3D.set_deferred("disabled", true)
	$Area3D10.hide()
	body.Area3d = $Area3D10
	bible_verses += 1

func _on_area_3d_11_body_entered(body: player) -> void:
	label.text += "\nLuke 1:35 - The angel answered, The Holy Spirit will come on you, and the power of the Most High will overshadow you. So the holy one to be born will be called the Son of God." 
	$Area3D11/CollisionShape3D.set_deferred("disabled", true)
	$Area3D11.hide()
	body.Area3d = $Area3D11
	bible_verses += 1

func _on_area_3d_12_body_entered(body: player) -> void:
	label.text += "\nLuke 1:37 - For no word from God will ever fail."
	$Area3D12/CollisionShape3D.set_deferred("disabled", true)
	$Area3D12.hide()
	body.Area3d = $Area3D12
	bible_verses += 1

func _on_laser_3d_body_entered(body: player) -> void:
	if body.Area3d == null:
		body.global_position = Vector3(0, 0, 0)
	else:
		body.global_position = body.Area3d.global_position


func _on_area_3d_13_body_entered(body: player) -> void:
	label.text += "\nLuke 1:38 - I am the Lord’s servant, Mary answered. May your word to me be fulfilled. Then the angel left her."  
	$Area3D13/CollisionShape3D.set_deferred("disabled", true)
	$Area3D13.hide()
	body.Area3d = $Area3D13
	bible_verses += 1

func _on_area_3d_14_body_entered(body: player) -> void:
	label.text += "\nMatthew 1:19-20 - Because Joseph her husband was faithful to the law, and yet did not want to expose her to public disgrace, he had in mind to divorce her quietly. But after he had considered this, an angel of the Lord appeared to him in a dream..."  
	$Area3D14/CollisionShape3D.set_deferred("disabled", true)
	$Area3D14.hide()
	body.Area3d = $Area3D14
	bible_verses += 1

func _on_area_3d_15_body_entered(body: player) -> void:
	label.text += "\nMatthew 1:21 - The angel said, ...You are to give him the name Jesus, because he will save his people from their sins."
	$Area3D15/CollisionShape3D.set_deferred("disabled", true)
	$Area3D15.hide()
	body.Area3d = $Area3D15
	bible_verses += 1

func _on_area_3d_16_body_entered(body: player) -> void:
	label.text += "\nMatthew 1:22-23 - All this took place to fulfill what the Lord had said through the prophet: The virgin will conceive and give birth to a son, and they will call him Immanuel (which means God with us)."  
	$Area3D16/CollisionShape3D.set_deferred("disabled", true)
	$Area3D16.hide()
	body.Area3d = $Area3D16
	bible_verses += 1

func _on_area_3d_17_body_entered(body: player) -> void:
	label.text += "\nMatthew 1:24 - When Joseph woke up, he did what the angel of the Lord had commanded him and took Mary home as his wife."
	$Area3D17/CollisionShape3D.set_deferred("disabled", true)
	$Area3D17.hide()
	body.Area3d = $Area3D17
	bible_verses += 1

func _on_area_3d_18_body_entered(body: player) -> void:
	label.text += "\nLuke 2:1 - In those days Caesar Augustus issued a decree that a census should be taken of the entire Roman world."
	$Area3D18/CollisionShape3D.set_deferred("disabled", true)
	$Area3D18.hide()
	body.Area3d = $Area3D18
	bible_verses += 1

func _on_area_3d_19_body_entered(body: player) -> void:
	label.text += "\nLuke 2:4-5 - So Joseph also went up from the town of Nazareth in Galilee to Judea, to Bethlehem the town of David, because he belonged to the house and line of David. He went there to register with Mary, who was pledged to be married to him and was expecting a child."
	$Area3D19/CollisionShape3D.set_deferred("disabled", true)
	$Area3D19.hide()
	body.Area3d = $Area3D19
	bible_verses += 1


func _on_area_3d_20_body_entered(body: player) -> void:
	label.text += "\nLuke 2:6 - While they were there, the time came for the baby to be born." 
	$Area3D20/CollisionShape3D.set_deferred("disabled", true)
	$Area3D20.hide()
	body.Area3d = $Area3D20
	bible_verses += 1

func _on_area_3d_21_body_entered(body: player) -> void:
	label.text += "\nLuke 2:7 - And she gave birth to her firstborn, a son. She wrapped him in cloths and placed him in a manger, because there was no guest room available for them."  
	$Area3D21/CollisionShape3D.set_deferred("disabled", true)
	$Area3D21.hide()
	body.Area3d = $Area3D21
	bible_verses += 1

func _on_area_3d_22_body_entered(body: player) -> void:
	label.text += "\nLuke 2:11 - Today in the town of David a Savior has been born to you; he is the Messiah, the Lord.\nLuke 2:8 - And there were shepherds living out in the fields nearby, keeping watch over their flocks at night.\nLuke 2:9 - An angel of the Lord appeared to them, and the glory of the Lord shone around them, and they were terrified.\nLuke 2:10 - But the angel said to them, Do not be afraid. I bring you good news that will cause great joy for all the people.\nLuke 2:12 - This will be a sign to you: You will find a baby wrapped in cloths and lying in a manger.\nLuke 2:13-14 - Suddenly a great company of the heavenly host appeared with the angel, praising God and saying, Glory to God in the highest heaven, and on earth peace to those on whom his favor rests.\nLuke 2:15 - When the angels had left them and gone into heaven, the shepherds said to one another, Let’s go to Bethlehem and see this thing that has happened, which the Lord has told us about.\nLuke 2:16 - So they hurried off and found Mary and Joseph, and the baby, who was lying in the manger.\nLuke 2:17-18 - When they had seen him, they spread the word concerning what had been told them about this child, and all who heard it were amazed at what the shepherds said to them.\nLuke 2:20 - The shepherds returned, glorifying and praising God for all the things they had heard and seen, which were just as they had been told.\nMatthew 2:1-2 - After Jesus was born in Bethlehem in Judea, during the time of King Herod, Magi from the east came to Jerusalem and asked, Where is the one who has been born king of the Jews? We saw his star when it rose and have come to worship him.\nMatthew 2:9-10 - After they had heard the king, they went on their way, and the star they had seen when it rose went ahead of them until it stopped over the place where the child was. When they saw the star, they were overjoyed.\nMatthew 2:11 - On coming to the house, they saw the child with his mother Mary, and they bowed down and worshiped him. Then they opened their treasures and presented him with gifts of gold, frankincense and myrrh.\nMatthew 2:13 - When they had gone, an angel of the Lord appeared to Joseph in a dream. Get up, he said, take the child and his mother and escape to Egypt. Stay there until I tell you, for Herod is going to search for the child to kill him.\nMatthew 2:14 - So he got up, took the child and his mother during the night and left for Egypt.\nMatthew 2:19-20 - After Herod died, an angel of the Lord appeared in a dream to Joseph in Egypt and said, Get up, take the child and his mother and go to the land of Israel, for those who were trying to take the child’s life are dead.\nMatthew 2:23 - And he went and lived in a town called Nazareth. So was fulfilled what was said through the prophets, that he would be called a Nazarene.\nJohn 3:16 - For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.\nTitus 3:4-5 - But when the kindness and love of God our Savior appeared, he saved us, not because of righteous things we had done, but because of his mercy.\nGalatians 4:4-5 - But when the set time had fully come, God sent his Son, born of a woman, born under the law, to redeem those under the law, that we might receive adoption to sonship.\n1 John 4:9 - This is how God showed his love among us: He sent his one and only Son into the world that we might live through him.\nJohn 1:14 - The Word became flesh and made his dwelling among us. We have seen his glory, the glory of the one and only Son, who came from the Father, full of grace and truth.\nJohn 1:1-2 - In the beginning was the Word, and the Word was with God, and the Word was God. He was with God in the beginning.\nLuke 1:68-69 - Praise be to the Lord, the God of Israel, because he has come to his people and redeemed them. He has raised up a horn of salvation for us in the house of his servant David.\nPhilippians 2:6-7 - Who, being in very nature God, did not consider equality with God something to be used to his own advantage; rather, he made himself nothing by taking the very nature of a servant, being made in human likeness.\n2 Corinthians 8:9 - For you know the grace of our Lord Jesus Christ, that though he was rich, yet for your sake he became poor, so that you through his poverty might become rich.\nHebrews 2:14-15 - Since the children have flesh and blood, he too shared in their humanity so that by his death he might break the power of him who holds the power of death—that is, the devil—and free those who all their lives were held in slavery by their fear of death.\nIsaiah 64:8 - Yet you, Lord, are our Father. We are the clay, you are the potter; we are all the work of your hand.\nJohn 1:12 - Yet to all who did receive him, to those who believed in his name, he gave the right to become children of God."
	$Area3D22/CollisionShape3D.set_deferred("disabled", true)
	$Area3D22.hide()
	body.Area3d = $Area3D22
	bible_verses += 29

func _on_area_3d_23_body_entered(body: player) -> void:
	 
	if label.get_line_count() == 51:
		$RichTextLabel.show()
		label.hide()
	else:
		body.label_2.text = "COLLECT ALL 50 BIBLE VERSES"
		body.global_position = Vector3(0, 0, 0)


func _on_area_3d_24_body_entered(body: player) -> void:
	if body.Area3d == null:
		body.global_position = Vector3(0, 0, 0)
	else:
		body.global_position = body.Area3d.global_position


func _on_button_pressed() -> void:
	Input.action_press("quit")


func _on_area_3d_9_body_entered(body: player) -> void:
	label.text += "\nLuke 1:32-33 - He will be great and will be called the Son of the Most High. The Lord God will give him the throne of his father David, and he will reign over Jacob’s descendants forever; his kingdom will never end."  
	$Area3D9/CollisionShape3D.set_deferred("disabled", true)
	$Area3D9.hide()
	body.Area3d = $Area3D9
	bible_verses += 1

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


func _on_area_3d_15s_body_entered(body: player, namer: String = str(user)) -> void:
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
			
