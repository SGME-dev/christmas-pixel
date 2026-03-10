extends Node3D

class_name lighthunt

var effect
var recording

@onready var label_3: TextEdit = $Label3
@onready var http_request: HTTPRequest = $CanvasLayer/HTTPRequest
@onready var lan_ip_label: Label = $CanvasLayer/Label
@onready var public_ip_label: Label = $CanvasLayer/Label2
@export var lights: int = 0
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
	if !OS.has_feature("dedicated_server"):
		var idx = AudioServer.get_bus_index("record")
		effect = AudioServer.get_bus_effect(idx,0)
		print(effect)
		effect.set_recording_active(true)
		get_tree().set_auto_accept_quit(false)

func _physics_process(delta: float) -> void:
	$Label2.text = str(lights, "/21")
	

func _on_host_pressed() -> void:
	peer.create_server(port, MAX_CONNECTIONS)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	multiplayer.get_peers()
	
	http_request.request_completed.connect(_on_http_request_completed)
	
	print("--- Attempting to get Public WAN IPv4 Address ---")
	public_ip_label.text = "Fetching Public IP..." 
	
	var error = http_request.request("https://ipv4.icanhazip.com")
	
	if error != OK:
		print("Failed to start HTTP request: ", error)
		public_ip_label.text = "Error: Failed to start request."
	
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
		print("No suitable local IPv4 address found.")
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
	if address.is_empty() or address == "localhost":
		address = DEFAULT_SERVER_IP
	if %LineEdit2.text.is_empty():
		%LineEdit2.text = str(port)
	peer.create_client(address, int(%LineEdit2.text))
	multiplayer.multiplayer_peer = peer
	%host.hide()
	%join.hide()
	%LineEdit.hide()
	%LineEdit2.hide()
	$Sprite3D38.hide()
	$CanvasLayer/Panel.hide()
	
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
func _del_player(id: int) -> void:
	get_node(str(id)).queue_free()
	

func _on_connected_fail() -> void:
	multiplayer.multiplayer_peer = null

func _on_area_3d_6_body_entered(body: player) -> void:
	if lights == 21 or lights >= 21:
		get_tree().quit()

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var public_ip = body.get_string_from_utf8().strip_edges()
		print("Public WAN IPv4 Address: " + public_ip)
		public_ip_label.text = "(Use after port forwarding)Public WAN IPv4 Address: " + public_ip 
	else:
		print("Failed to get public IP.")
		public_ip_label.text = "Error: Could not get public IP."

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
	if dedserver == true:
		var path = Exepath + "/data/Player/location/" + namer + ".save"
		var posav = FileAccess.open(path, FileAccess.WRITE)
		if posav:
			posav.store_var(pos)
			

@rpc("any_peer", "call_remote", "reliable")
func teleport_player(sender_id, new_position):
	get_node(str(sender_id)).global_position = new_position
	print("Teleported to: ", new_position)


@rpc("any_peer", "call_remote", "reliable")
func load_pos_on_server(namer: String):
	if not dedserver: return 
	var path = OS.get_executable_path().get_base_dir() + "/data/Player/location/" + namer + ".save"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var saved_pos = file.get_var(true) 
		file.close()
		var sender_id = multiplayer.get_remote_sender_id()
		teleport_player.rpc(sender_id, saved_pos)


func _on_area_3d_15_body_entered(body: player, namer: String = str(user)) -> void:
	load_pos_on_server.rpc_id(1, user)
	$Area3D15/CollisionShape3D.queue_free()

@rpc("any_peer", "call_remote", "reliable")
func save_bans_on_server(namer: String) -> void:
	var Exepath = OS.get_executable_path().get_base_dir()
	if dedserver == true:
		var path = Exepath + "/data/bans/bans.txt"
		var bans = FileAccess.open(path, FileAccess.READ_WRITE)
		var nbans = bans.get_as_text()
		bans.store_string(nbans + "\n" + namer)
		

@rpc("any_peer", "call_remote", "reliable")
func save_ban_ips_on_server(namer: String) -> void:
	var Exepath = OS.get_executable_path().get_base_dir()
	if dedserver == true:
		var path = Exepath + "/data/ban-ips/ban-ips.txt"
		var bans = FileAccess.open(path, FileAccess.READ_WRITE)
		var nbans = bans.get_as_text()
		bans.store_string(nbans + "\n" + namer)
		

@rpc("any_peer", "call_remote", "reliable")
func load_bans_on_server():
	if not dedserver: return 
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
	if not dedserver: return 
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
			var public_ip = body.get_string_from_utf8().strip_edges()
			ip = public_ip
		else:
			print("Failed to get public IP.")


# --- LIGHT HUNT VERSES START ---

func _on_area_3d_body_entered(body: player) -> void:
	$Area3D/CollisionShape3D.set_deferred("disabled", true)
	$Area3D.hide()
	$Label3.show()
	lights += 1
	$Label3.text += "\nMatthew 1:21: She will bear a son, and you shall call his name Jesus, for he will save his people from their sins."

func _on_area_3d_2_body_entered(body: player) -> void:
	$Area3D2/CollisionShape3D.set_deferred("disabled", true)
	$Area3D2.hide()
	$Label3.show()
	$Label3.text += "\nMatthew 1:23: Behold, the virgin shall conceive and bear a son, and they shall call his name Immanuel."
	lights += 1

func _on_area_3d_3_body_entered(body: player) -> void:
	$Area3D3/CollisionShape3D.set_deferred("disabled", true)
	$Area3D3.hide()
	$Label3.show()
	$Label3.text += "\nMatthew 2:1: Now after Jesus was born in Bethlehem of Judea in the days of Herod the king, behold, wise men from the east came to Jerusalem."
	lights += 1

func _on_area_3d_4_body_entered(body: player) -> void:
	$Area3D4/CollisionShape3D.set_deferred("disabled", true)
	$Area3D4.hide()
	$Label3.show()
	$Label3.text += "\nMatthew 2:11: And going into the house, they saw the child with Mary his mother, and they fell down and worshiped him."
	lights += 1

func _on_area_3d_5_body_entered(body: player) -> void:
	$Area3D5/CollisionShape3D.set_deferred("disabled", true)
	$Area3D5.hide()
	$Label3.show()
	$Label3.text += "\nLuke 1:31: And behold, you will conceive in your womb and bear a son, and you shall call his name Jesus."
	lights += 1

func _on_area_3d_7_body_entered(body: player) -> void:
	$Area3D7/CollisionShape3D.set_deferred("disabled", true)
	$Area3D7.hide()
	$Label3.show()
	$Label3.text += "\nLuke 1:35: The Holy Spirit will come upon you, and the power of the Most High will overshadow you; therefore the child to be born will be called holy—the Son of God."
	lights += 1

func _on_area_3d_8_body_entered(body: player) -> void:
	$Area3D8/CollisionShape3D.set_deferred("disabled", true)
	$Area3D8.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:7: And she gave birth to her firstborn son and wrapped him in swaddling cloths and laid him in a manger, because there was no place for them in the inn."
	lights += 1

func _on_area_3d_9_body_entered(body: player) -> void:
	$Area3D9/CollisionShape3D.set_deferred("disabled", true)
	$Area3D9.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:10: And the angel said to them, Fear not, for behold, I bring you good news of great joy that will be for all the people."
	lights += 1

func _on_area_3d_10_body_entered(body: player) -> void:
	$Area3D10/CollisionShape3D.set_deferred("disabled", true)
	$Area3D10.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:11: For unto you is born this day in the city of David a Savior, who is Christ the Lord."
	lights += 1

func _on_area_3d_11_body_entered(body: player) -> void:
	$Area3D11/CollisionShape3D.set_deferred("disabled", true)
	$Area3D11.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:12: And this will be a sign for you: you will find a baby wrapped in swaddling cloths and lying in a manger."
	lights += 1

func _on_area_3d_12_body_entered(body: player) -> void:
	$Area3D12/CollisionShape3D.set_deferred("disabled", true)
	$Area3D12.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:14: Glory to God in the highest, and on earth peace among those with whom he is pleased!"
	lights += 1

func _on_area_3d_13_body_entered(body: player) -> void:
	$Area3D13/CollisionShape3D.set_deferred("disabled", true)
	$Area3D13.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:16: And they went with haste and found Mary and Joseph, and the baby lying in a manger."
	lights += 1

func _on_area_3d_14_body_entered(body: player) -> void:
	$Area3D14/CollisionShape3D.set_deferred("disabled", true)
	$Area3D14.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:21: And at the end of eight days, when he was circumcised, he was called Jesus."
	lights += 1

func _on_area_3d_16_body_entered(body: player) -> void:
	$Area3D16/CollisionShape3D.set_deferred("disabled", true)
	$Area3D16.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:40: And the child grew and became strong, filled with wisdom. And the favor of God was upon him."
	lights += 1

func _on_area_3d_17_body_entered(body: player) -> void:
	$Area3D17/CollisionShape3D.set_deferred("disabled", true)
	$Area3D17.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:41: Now his parents went to Jerusalem every year at the Feast of the Passover."
	lights += 1

func _on_area_3d_18_body_entered(body: player) -> void:
	$Area3D18/CollisionShape3D.set_deferred("disabled", true)
	$Area3D18.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:42: And when he was twelve years old, they went up according to custom."
	lights += 1

func _on_area_3d_19_body_entered(body: player) -> void:
	$Area3D19/CollisionShape3D.set_deferred("disabled", true)
	$Area3D19.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:46: After three days they found him in the temple, sitting among the teachers, listening to them and asking them questions."
	lights += 1

func _on_area_3d_20_body_entered(body: player) -> void:
	$Area3D20/CollisionShape3D.set_deferred("disabled", true)
	$Area3D20.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:47: And all who heard him were amazed at his understanding and his answers."
	lights += 1

func _on_area_3d_21_body_entered(body: player) -> void:
	$Area3D21/CollisionShape3D.set_deferred("disabled", true)
	$Area3D21.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:49: And he said to them, Why were you looking for me? Did you not know that I must be in my Father's house?"
	lights += 1

func _on_area_3d_22_body_entered(body: player) -> void:
	$Area3D22/CollisionShape3D.set_deferred("disabled", true)
	$Area3D22.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:51: And he went down with them and came to Nazareth and was submissive to them."
	lights += 1

func _on_area_3d_23_body_entered(body: Node3D) -> void:
	$Area3D23/CollisionShape3D.set_deferred("disabled", true)
	$Area3D23.hide()
	$Label3.show()
	$Label3.text += "\nLuke 2:52: And Jesus increased in wisdom and in stature and in favor with God and man."
	lights += 1

func _on_area_3d_24_body_entered(body: player) -> void:
	body.global_position = Vector3(0, 0, 0)


func _on_area_3d_37_body_entered(body: player) -> void:
	body.global_position = Vector3(0, 0, 0)

var mute: bool = false
var mute_all: bool = false


func _on_mute_pressed() -> void:
	if mute == false:
		mute = true
		effect.set_recording_active(false)
		$AudioStreamPlayer.volume_db = -80
		$AudioStreamRecord.volume_db = -80
		$CanvasLayer/mute.icon = ResourceLoader.load("res://mute.png")
		return
	if mute == true:
		mute = false
		effect.set_recording_active(true)
		$AudioStreamPlayer.volume_db = 10.478
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
