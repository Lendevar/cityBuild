extends Node

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1909

var t

func connectToServer():
	print("Trying to establish connection")
	
	network.create_client(ip, port)
	
	get_tree().set_network_peer(network)
	
	network.connect("connection_failed", self, "_OnConnectionFailed")
	network.connect("connection_succeeded", self, "_OnConnectionSucceeded")
	

func waitBeforeConnection(howLong):
	t = Timer.new()
	t.set_wait_time(howLong)
	t.set_one_shot(true)
	self.add_child(t)
	t.start()

func _ready():
	#waitBeforeConnection(2)
	#t.connect("timeout", self, "connectToServer")
	pass

func _OnConnectionFailed():
	
	print("Failed To Connect")

func _OnConnectionSucceeded():
	
	print("Yeah we connected")
