extends Spatial

export (Array) var arrayRoadNodes

class roadNode:
	
	var nodeBody
	var neighbourNodes = []
	

var buildMode = false
var currentlyDrawingFrom = 0

func _ready():
	
	var firstNode = roadNode.new()
	
	firstNode.nodeBody = $roadNodes/roadNode
	
	arrayRoadNodes += [firstNode]
	
	pass # Replace with function body.

func nodeHasBeenClicked(id):
	
	buildMode = true
	currentlyDrawingFrom = id




func _physics_process(delta):
	
	if buildMode = true:
		
		
		pass
	
	
	pass




