extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1909
var max_players = 20

var arrayPlayers = []

func startServer():
	
	network.create_server(port, max_players)
	
	get_tree().set_network_peer(network)
	
	print("Server Started")
	
	network.connect("peer_connected", self, "_Peer_Connected")
	network.connect("peer_disconnected", self, "_Peer_Disconnected")

func _ready():
	startServer()

class Player:
	var id = 0

func _Peer_Connected(player_id):
	print("User " + str(player_id) + " connected")
	
	var newPlayer = Player.new()
	newPlayer.id = player_id
	
	arrayPlayers += [newPlayer]

func _Peer_Disconnected(player_id):
	print("User " + str(player_id) + " is out")
	
	for i in range (0, arrayPlayers.size()):
		if arrayPlayers[i].id == player_id:
			arrayPlayers.remove(i)
			break
		
	



