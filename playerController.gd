extends Spatial

signal arrayRoadsChanged(whatHappened, whichNodes)

export (int) var ray_length = 1000

export onready var camera = get_node("RtsCameraController2/Elevation/Camera")
export onready var ray = get_node("lever/RayCast")

signal playerClicked(pos, obj)

################ Roads

export (Array) var arrayRoadNodes

export (PackedScene) var singleRoadNode

class roadNode:
	
	var nodeBody
	var neighbourNodes = []
	

var buildMode = false
var currentlyDrawingFrom = 0

var removeMode = false

####################

var cursorNode
var rayTerrain
var IwantToSee

func _ready():
	
	ray.cast_to = Vector3(0,0, - ray_length)
	
	var firstNode = roadNode.new()
	
	firstNode.nodeBody = $roadNodes/roadNode
	
	arrayRoadNodes += [firstNode]
	
	###############
	$pnlRoad.hide()
	###############
	
	cursorNode = MeshInstance.new()
	cursorNode.mesh = SphereMesh.new()
	
	$roadNodes.add_child(cursorNode)
	
	###############
	
	rayTerrain = RayCast.new()
	
	$roadNodes.add_child(rayTerrain)
	
	rayTerrain.enabled = true
	rayTerrain.cast_to = Vector3(0,0, -100)
	
	rayTerrain.rotation_degrees.x = -90
	
	IwantToSee = MeshInstance.new()
	IwantToSee.mesh = CubeMesh.new()
	
	rayTerrain.add_child(IwantToSee)

func nodeHasBeenClicked(id):
	
	$pnlRoad.show()
	
	$pnlRoad/lblNeighbours.text = "node " + str(arrayRoadNodes[id])
	$pnlRoad/lblNeighbours.text += "\r\nneighb " + str(arrayRoadNodes[id].neighbourNodes)
	
	if buildMode != true:
		currentlyDrawingFrom = id
	
	if removeMode == true:
		print("removing ", arrayRoadNodes[id])
		
		########## Removal might be requested from the server in future multiplayer version
		if currentlyDrawingFrom != 0:
			requestNodeRemoval(arrayRoadNodes[id])
			
			currentlyDrawingFrom = 0
		
	


############### Turning ray rotation to the click position

func _input(event):
	
	if event is InputEventMouseButton and event.pressed and  event.button_index == 1:
		
		camera = $RtsCameraController2/Elevation/Camera
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * ray_length
		
		$lever.global_transform.origin = camera.global_transform.origin
		
		$lever.look_at(to, Vector3(0,-1,0))
		
	

var collPoint = Vector3()
var collObj

####### Getting collision point and object

func getLmbCollider():
	
	if Input.is_action_just_pressed("mouse_left"):   
		
		collPoint = $lever/RayCast.get_collision_point() 
		collObj = $lever/RayCast.get_collider()
		
		$collMesh.global_transform.origin = collPoint
		
		processClick(collPoint, collObj)
		


func processClick(pos, obj):
	
	#print(pos, obj)
	
	################ Checking if it is a road node
	
	for i in range (0, arrayRoadNodes.size()):
		
		if obj == arrayRoadNodes[i].nodeBody:
			
			nodeHasBeenClicked(i)
			break
		
	

var roadEnd = Vector3()
var roadVector = Vector3()
var directionVector = Vector3()

export (int) var distanceBetweenNodes = 10

var nodesToDraw = 0

var arrayCurrentlyDrawing = []

var mouseMoved
var mousePos

class MyCustomSorter:
	static func sort_ascending(a, b):
		if a[0] < b[0]:
			return true
		return false

func fillNewRoadArray():
	
	var arrayRoad = []
	
	########## Since we're constantly adding and removing currentlyDrawing nodes
	########## Ids of them are messed up
	########## So I want to recalculate id's 
	########## Based on their distance to the start
	##########(0 is the closest from start -> last is to the end)
	
	for i in range(0, arrayCurrentlyDrawing.size()):
		
		var startNodePos = arrayRoadNodes[currentlyDrawingFrom].nodeBody.global_transform.origin
		var distance = arrayCurrentlyDrawing[i].global_transform.origin.distance_to(startNodePos)
		
		arrayRoad += [[distance, arrayCurrentlyDrawing[i].global_transform.origin]]
	
	############# Using custom sorting
	
	arrayRoad.sort_custom(MyCustomSorter, "sort_ascending")
	
	############ Then we leave only the positions of nodes
	
	for i in range(0, arrayCurrentlyDrawing.size()):
		
		arrayRoad[i] = arrayRoad[i][1]
		
	
	return arrayRoad






func drawingRoad():
	
	if mousePos != get_viewport().get_mouse_position():
		
		mouseMoved = true
		
	else:
		
		mouseMoved = false
		
	
	
	if buildMode == true and mouseMoved == true:
		
		camera = $RtsCameraController2/Elevation/Camera
		var from = camera.project_ray_origin(get_viewport().get_mouse_position())
		var to = from + camera.project_ray_normal(get_viewport().get_mouse_position()) * ray_length
		
		$lever.global_transform.origin = camera.global_transform.origin
		
		$lever.look_at(to, Vector3(0,-1,0))
		
		roadEnd = $lever/RayCast.get_collision_point()
		
		#cursorNode.global_transform.origin = roadEnd
		
		roadVector = roadEnd - arrayRoadNodes[currentlyDrawingFrom].nodeBody.global_transform.origin
		directionVector = roadVector / roadVector.length()
		
		nodesToDraw = floor(roadVector.length() / distanceBetweenNodes)
		
		#print(arrayCurrentlyDrawing.size())
		
		######## Defying how many nodes to pre-draw
		
		if arrayCurrentlyDrawing.size() < nodesToDraw:
			
			for i in range(0, nodesToDraw - arrayCurrentlyDrawing.size()):
				
				var newMesh = MeshInstance.new()
				newMesh.mesh = SphereMesh.new()
				
				arrayCurrentlyDrawing += [newMesh]
				$roadNodes.add_child(arrayCurrentlyDrawing.back())
			
		
		if arrayCurrentlyDrawing.size() > nodesToDraw:
			
			for i in range(0, arrayCurrentlyDrawing.size() - nodesToDraw):
				
				$roadNodes.remove_child(arrayCurrentlyDrawing[arrayCurrentlyDrawing.size() - 1])
				arrayCurrentlyDrawing.remove(arrayCurrentlyDrawing.size() - 1)
				break
			
		
		var start = arrayRoadNodes[currentlyDrawingFrom].nodeBody.global_transform.origin
		
		for i in range(0, arrayCurrentlyDrawing.size()):
			
			arrayCurrentlyDrawing[i].show()
			
		
		if nodesToDraw != 0:
			for i in range(0, arrayCurrentlyDrawing.size()):
				
				arrayCurrentlyDrawing[i].global_transform.origin = start + directionVector * (i+1) * (roadVector.length()/nodesToDraw)
				
				rayTerrain.global_transform.origin = arrayCurrentlyDrawing[i].global_transform.origin
				
				rayTerrain.global_transform.origin.y += 30
				
				
				arrayCurrentlyDrawing[i].global_transform.origin = rayTerrain.get_collision_point()
				rayTerrain.force_raycast_update()
				
				
		
		
	else: ##### if not build mode
		
		cursorNode.global_transform.origin = Vector3(0, -10, 0)
		
	
	var storageOfTheStart = arrayRoadNodes[currentlyDrawingFrom]
	
	if buildMode == true:
		if Input.is_action_just_pressed("mouse_left"):
			
			######### If it is a static body, we might check if it is the road Node
			
			var weConnectOrBuildNew  = "buildNew"
			var intersection = 0
			
			if $lever/RayCast.get_collider().get_class() == "StaticBody":
				for i in range(0, arrayRoadNodes.size()):
					if $lever/RayCast.get_collider() == arrayRoadNodes[i].nodeBody:
						
						weConnectOrBuildNew = "connect"
						intersection = arrayRoadNodes[i]
						
						print(intersection)
						
					
				
			
			if weConnectOrBuildNew == "buildNew":
				requestRoadBuild(fillNewRoadArray())
			else:
				requestRoadConnect(fillNewRoadArray(), intersection, storageOfTheStart)
			
		
	
	mousePos = get_viewport().get_mouse_position()
	


########################## This thing should probably be requested from server

var previousNode

func requestRoadBuild(roadArray):
	if roadArray.size() != 0:
		for i in range(0, roadArray.size()):
			if i == 0:
				
				var firstNode = roadNode.new()
				firstNode.nodeBody = singleRoadNode.instance()
				firstNode.neighbourNodes += [arrayRoadNodes[currentlyDrawingFrom]]
				arrayRoadNodes[currentlyDrawingFrom].neighbourNodes += [firstNode]
				
				arrayRoadNodes += [firstNode]
				
				previousNode = firstNode
				
				$roadNodes.add_child(firstNode.nodeBody)
				firstNode.nodeBody.global_transform.origin = roadArray[0]
				
				var nodeOnePos = arrayRoadNodes[currentlyDrawingFrom].nodeBody.global_transform.origin
				var nodeTwoPos = firstNode.nodeBody.global_transform.origin
				
				emit_signal("arrayRoadsChanged", "newNode", [nodeOnePos, nodeTwoPos])
				
			else:
				
				var newNode = roadNode.new()
				newNode.nodeBody = singleRoadNode.instance()
				
				newNode.neighbourNodes += [previousNode]
				previousNode.neighbourNodes += [newNode]
				
				arrayRoadNodes += [newNode]
				
				$roadNodes.add_child(newNode.nodeBody)
				newNode.nodeBody.global_transform.origin = roadArray[i]
				
				if i == roadArray.size() - 1:
					
					var nodeOnePos = previousNode.nodeBody.global_transform.origin
					var nodeTwoPos = newNode.nodeBody.global_transform.origin
					
					emit_signal("arrayRoadsChanged", "newSimpleConnection", [nodeOnePos, nodeTwoPos])
				else:
					
					var nodeOnePos = previousNode.nodeBody.global_transform.origin
					var nodeTwoPos = newNode.nodeBody.global_transform.origin
					
					emit_signal("arrayRoadsChanged", "newNode", [nodeOnePos, nodeTwoPos])
				
				previousNode = newNode
				
		
	
	buildMode = false
	
	for i in range(0, arrayCurrentlyDrawing.size()):
		
		$roadNodes.remove_child(arrayCurrentlyDrawing[i])
		
	
	arrayCurrentlyDrawing.clear()

#################################

func requestRoadConnect(roadArray, intersection, start):
	if start.neighbourNodes.find(intersection) == -1:		
		if roadArray.size() == 1:  #### Simple connection with one road section
			
			start.neighbourNodes += [intersection]
			intersection.neighbourNodes += [start]
			
			var nodeOnePos = start.nodeBody.global_transform.origin
			var nodeTwoPos = intersection.nodeBody.global_transform.origin
			
			emit_signal("arrayRoadsChanged", "newSimpleConnection", [nodeOnePos, nodeTwoPos])
			
		else:
			for i in range(0, roadArray.size()):
				if i == 0:
					
					var firstNode = roadNode.new()
					firstNode.nodeBody = singleRoadNode.instance()
					
					firstNode.neighbourNodes += [start]
					start.neighbourNodes += [firstNode]
					
					arrayRoadNodes += [firstNode]
					
					var nodeOnePos = start.nodeBody.global_transform.origin
					var nodeTwoPos = firstNode.nodeBody.global_transform.origin
					
					previousNode = firstNode
					
					$roadNodes.add_child(firstNode.nodeBody)
					firstNode.nodeBody.global_transform.origin = roadArray[0]
					
					emit_signal("arrayRoadsChanged", "newNode", [nodeOnePos, nodeTwoPos])
					
				else:
					if i != roadArray.size() - 1:
						
						var newNode = roadNode.new()
						newNode.nodeBody = singleRoadNode.instance()
						
						newNode.neighbourNodes += [previousNode]
						previousNode.neighbourNodes += [newNode]
						
						arrayRoadNodes += [newNode]
						
						var nodeOnePos = previousNode.nodeBody.global_transform.origin
						var nodeTwoPos = newNode.nodeBody.global_transform.origin
						
						previousNode = newNode
						
						$roadNodes.add_child(newNode.nodeBody)
						newNode.nodeBody.global_transform.origin = roadArray[i]
						
						emit_signal("arrayRoadsChanged", "newNode", [nodeOnePos, nodeTwoPos])
						
					else:   
						
						# we dont draw the node that sits onto the crossroad since it already exists
						
						previousNode.neighbourNodes += [intersection]
						intersection.neighbourNodes += [previousNode]
						
						var nodeOnePos = previousNode.nodeBody.global_transform.origin
						var nodeTwoPos = intersection.nodeBody.global_transform.origin
						
						emit_signal("arrayRoadsChanged", "newSimpleConnection", [previousNode, intersection])
					
				
			
		
	else:
		
		print("They are already neighbours")
		
	
	buildMode = false
	
	for i in range(0, arrayCurrentlyDrawing.size()):
		
		$roadNodes.remove_child(arrayCurrentlyDrawing[i])
		
	
	arrayCurrentlyDrawing.clear()

##############################################################

func requestNodeRemoval(node):
	
	$roadNodes.remove_child(node.nodeBody)
	
	emit_signal("arrayRoadsChanged", "newRemoval", [node] + node.neighbourNodes)
	
	arrayRoadNodes.erase(node)
	
	for i in range(0, arrayRoadNodes.size()):
		
		if arrayRoadNodes[i].neighbourNodes.find(node) != -1:
			
			arrayRoadNodes[i].neighbourNodes.erase(node)
			
		
	
	pass


func _physics_process(delta):
	
	getLmbCollider()
	
	drawingRoad()

func _on_btnAddRoad_button_up():
	
	buildMode = true
	
	removeMode = false
	

	
	print(currentlyDrawingFrom)



func _on_btnRemoveNode_button_up():
	
	buildMode = false
	if removeMode == false:
		removeMode = true
		$pnlRoad/btnRemoveNode.text = "X"
	else:
		removeMode = false
		$pnlRoad/btnRemoveNode.text = "-"
	
	pass # Replace with function body.
