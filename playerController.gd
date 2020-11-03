extends Spatial

signal arrayRoadsChanged(whatHappened, whichNodes)
signal readyToSendNodeData(arrayNodes)

signal requestTestPathFind(positions)

signal requestBuildingPlacement(type, position, rot)

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

var testPathFindMode = false

var placingBuildingMode = false
####################

var cursorNode
var rayTerrain
var IwantToSee

####################

var importedRoadBodiesArray = []
signal requestRoadBodyRemoval
signal requestRoadBodyEndPoint


var arrayBuildingButtons = []

var arrayNodeBodiesInArea = []

var materialRed
var materialGreen

export (PackedScene) var factoryPreview


func _ready():
	
	materialGreen = SpatialMaterial.new()
	materialGreen.albedo_color = Color("#00ff70")
	materialGreen.params_blend_mode = 1
	
	materialRed = SpatialMaterial.new()
	materialRed.albedo_color = Color("#b70303")
	materialRed.params_blend_mode = 1
	
	$buildingAreaCursor.connect("body_entered", self, "processBodyInBuildingCursor")
	$buildingAreaCursor.connect("body_exited", self, "processBodyLeavingCursor")
	#############################
	
	arrayBuildingButtons += [$pnlBuilding/ScrollContainer/HBoxContainer/btnFactory]
	
	for i in range(0, arrayBuildingButtons.size()):
		arrayBuildingButtons[i].connect("button_up", self, "startPlacingABuilding", [arrayBuildingButtons[i].text])
	
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
	
	#IwantToSee = MeshInstance.new()
	#IwantToSee.mesh = CubeMesh.new()
	
	#rayTerrain.add_child(IwantToSee)

############################

var nodePositionsForTestPathFind = []

############################

var currentlyPlacing

func startPlacingABuilding(buildingType):
	
	currentlyPlacing = buildingType
	$buildingAreaCursor.show()
	
	placingBuildingMode = true
	
	match currentlyPlacing:
			"Factory":
				buildingPreview = factoryPreview.instance()
				add_child(buildingPreview)
	

func nodeHasBeenClicked(id):
	
	#$pnlRoad.show()
	
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
		
	
	if testPathFindMode == true:
		
		var pos = arrayRoadNodes[id].nodeBody.global_transform.origin 
		
		nodePositionsForTestPathFind += [Vector3(floor(pos.x),floor(pos.y),floor(pos.z))]
		
		if nodePositionsForTestPathFind.size() == 2:
			emit_signal("requestTestPathFind", nodePositionsForTestPathFind)
			nodePositionsForTestPathFind.clear()
		
		pass
	

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
		

func updateRoadBodiesArray(arr):
	
	importedRoadBodiesArray = arr

func removeNeighbourByPos(nodePos, neighPos):
	
	var firstId = -1
	var secondId = -1
	
	var flooredNode = Vector3(floor(nodePos.x), floor(nodePos.y), floor(nodePos.z))
	var flooredNeigh = Vector3(floor(neighPos.x), floor(neighPos.y), floor(neighPos.z))
	
	for i in range(0, arrayRoadNodes.size()):
		
		var currentPos = arrayRoadNodes[i].nodeBody.global_transform.origin
		var flooredCurrent = Vector3(floor(currentPos.x), floor(currentPos.y), floor(currentPos.z))
		
		if flooredCurrent == flooredNode:
			firstId = i
		
		if flooredCurrent == flooredNeigh:
			secondId = i
		
		if firstId != -1 and secondId != -1:
			break
	
	if firstId != -1 and secondId != -1:
		arrayRoadNodes[firstId].neighbourNodes.erase(arrayRoadNodes[secondId])
		arrayRoadNodes[secondId].neighbourNodes.erase(arrayRoadNodes[firstId])
		print("destroyed neighbour relation between ", arrayRoadNodes[firstId], " and ", arrayRoadNodes[secondId])
	

func processClick(pos, obj):
	
	#print(pos, obj)
	
	var isChecked = false
	
	################ Checking if it is a road node
	
	for i in range (0, arrayRoadNodes.size()):
		if obj == arrayRoadNodes[i].nodeBody:
			
			nodeHasBeenClicked(i)
			
			isChecked = true
			
			break
		
	
	############## Checking if it is a road body
	
	if isChecked == false:
		for i in range(0, importedRoadBodiesArray.size()):
			if obj == importedRoadBodiesArray[i] and removeMode == true:
				
				var bodyPos = importedRoadBodiesArray[i].global_transform.origin
				var endPos = get_node(str(importedRoadBodiesArray[i].get_path()) + "/endPoint").global_transform.origin
				
				removeNeighbourByPos(bodyPos, endPos)
				
				emit_signal("requestRoadBodyRemoval", [bodyPos, endPos])
				
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

###############################################

var placingPoint

var mousePosBuildingMode
var mouseMovedBuildingMode

var arrayDistancesToCursor = []
var nearestNode = null
var nearestNodeDistance = -1

var readyToPlaceABuilding = false

var buildingPreview

func drawBuildingCursor():
	
	if placingBuildingMode == true:
		
		if mousePosBuildingMode != get_viewport().get_mouse_position():
			
			mouseMovedBuildingMode = true
			
		else:
			
			mouseMovedBuildingMode = false
			
		
		camera = $RtsCameraController2/Elevation/Camera
		var from = camera.project_ray_origin(get_viewport().get_mouse_position())
		var to = from + camera.project_ray_normal(get_viewport().get_mouse_position()) * ray_length
		
		$lever.global_transform.origin = camera.global_transform.origin
		
		$lever.look_at(to, Vector3(0,-1,0))
		
		placingPoint = $lever/RayCast.get_collision_point()
		
		if mouseMovedBuildingMode == true:
			
			$buildingAreaCursor.global_transform.origin = placingPoint
			
			if nearestNodeDistance != -1 and nearestNode != null:
				if placingPoint.distance_to(nearestNode.global_transform.origin) > 9:
					$buildingAreaCursor.global_transform.origin = placingPoint
					$buildingAreaCursor/MeshInstance.set_surface_material(0, materialRed)
					
					readyToPlaceABuilding = false
					
				else:
					$buildingAreaCursor.global_transform.origin = nearestNode.global_transform.origin
					$buildingAreaCursor/MeshInstance.set_surface_material(0, materialGreen)
					
					readyToPlaceABuilding = true
					
			else:
				$buildingAreaCursor.global_transform.origin = placingPoint
				$buildingAreaCursor/MeshInstance.set_surface_material(0, materialRed)
				
				readyToPlaceABuilding = false
			
			
			if arrayNodeBodiesInArea.size() != 0:
				for i in range(0, arrayNodeBodiesInArea.size()):
					
					var currentDistance = placingPoint.distance_to(arrayNodeBodiesInArea[i].global_transform.origin)
					
					arrayDistancesToCursor += [[currentDistance, arrayNodeBodiesInArea[i]]]
					
				
				arrayDistancesToCursor.sort_custom(MyCustomSorter, "sort_ascending")
				
				nearestNode = arrayDistancesToCursor[0][1]
				nearestNodeDistance = arrayDistancesToCursor[0][0]
			
		
		if readyToPlaceABuilding == true:
			
			buildingPreview.show()
			
			var previewVector = placingPoint - nearestNode.global_transform.origin
			previewVector = previewVector / previewVector.length()
			
			previewVector.y = 0
			
			var previewPoint = nearestNode.global_transform.origin + (previewVector * 6)
			
			previewPoint.y += 10
			rayTerrain.global_transform.origin = previewPoint
			
			buildingPreview.global_transform.origin = rayTerrain.get_collision_point()
			buildingPreview.look_at(nearestNode.global_transform.origin, Vector3(0,1,0))
			
			if Input.is_action_just_released("mouse_left"):
				
				requestNewBuilding()
		
		
		mousePosBuildingMode = get_viewport().get_mouse_position()
		arrayDistancesToCursor.clear()


############################################

func requestNewBuilding():
	var previewPos = buildingPreview.global_transform.origin
	var previewRot = buildingPreview.rotation_degrees
	
	previewRot.z = 0
	previewRot.x = 0
	
	emit_signal("requestBuildingPlacement", currentlyPlacing, previewPos, previewRot )
	
	var entrancePos = get_node(str(buildingPreview.get_path()) + "/entrancePoint").global_transform.origin
	
	var newNode = roadNode.new()
	
	newNode.nodeBody = singleRoadNode.instance()
	
	$roadNodes.add_child(newNode.nodeBody)
	
	newNode.nodeBody.global_transform.origin = entrancePos
	
	var neighbour
	
	for i in range(0, arrayRoadNodes.size()):
			
			if arrayRoadNodes[i].nodeBody == nearestNode:
				
				neighbour = arrayRoadNodes[i]
				break
			
		
	
	newNode.neighbourNodes += [neighbour]
	neighbour.neighbourNodes += [newNode]
	
	arrayRoadNodes += [newNode]
	
	emit_signal("arrayRoadsChanged", "withEnd", [neighbour.nodeBody.global_transform.origin, entrancePos])
	
	buildingPreview.hide()
	placingBuildingMode = false
	
	$buildingAreaCursor.global_transform.origin = Vector3(0,0,0)










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
					
					emit_signal("arrayRoadsChanged", "withEnd", [nodeOnePos, nodeTwoPos])
				else:
					
					var nodeOnePos = previousNode.nodeBody.global_transform.origin
					var nodeTwoPos = newNode.nodeBody.global_transform.origin
					
					emit_signal("arrayRoadsChanged", "newNode", [nodeOnePos, nodeTwoPos])
				
				previousNode = newNode
				
		
	
	buildMode = false
	
	for i in range(0, arrayCurrentlyDrawing.size()):
		
		$roadNodes.remove_child(arrayCurrentlyDrawing[i])
		
	
	arrayCurrentlyDrawing.clear()
	
	emit_signal("readyToSendNodeData", arrayRoadNodes)

#################################

func requestRoadConnect(roadArray, intersection, start):
	if start.neighbourNodes.find(intersection) == -1:		
		if roadArray.size() == 1:  #### Simple connection with one road section
			
			start.neighbourNodes += [intersection]
			intersection.neighbourNodes += [start]
			
			var nodeOnePos = start.nodeBody.global_transform.origin
			var nodeTwoPos = intersection.nodeBody.global_transform.origin
			
			if intersection.neighbourNodes.size() > 2:
				emit_signal("arrayRoadsChanged", "newNode", [nodeOnePos, nodeTwoPos])
			else:
				emit_signal("arrayRoadsChanged", "withEnd", [nodeOnePos, nodeTwoPos])
			
		else:
			for i in range(0, roadArray.size()):
				if i == 0:
					
					var firstNode = roadNode.new()
					firstNode.nodeBody = singleRoadNode.instance()
					
					firstNode.neighbourNodes += [start]
					start.neighbourNodes += [firstNode]
					
					arrayRoadNodes += [firstNode]
					
					previousNode = firstNode
					
					$roadNodes.add_child(firstNode.nodeBody)
					firstNode.nodeBody.global_transform.origin = roadArray[0]
					
					var nodeOnePos = start.nodeBody.global_transform.origin
					var nodeTwoPos = firstNode.nodeBody.global_transform.origin
					
					emit_signal("arrayRoadsChanged", "newNode", [nodeOnePos, nodeTwoPos])
					
				else:
					if i != roadArray.size() - 1:
						
						var newNode = roadNode.new()
						newNode.nodeBody = singleRoadNode.instance()
						
						newNode.neighbourNodes += [previousNode]
						previousNode.neighbourNodes += [newNode]
						
						arrayRoadNodes += [newNode]
						
						$roadNodes.add_child(newNode.nodeBody)
						
						var nodeOnePos = previousNode.nodeBody.global_transform.origin
						
						
						previousNode = newNode
						
						newNode.nodeBody.global_transform.origin = roadArray[i]
						
						var nodeTwoPos = newNode.nodeBody.global_transform.origin
						
						emit_signal("arrayRoadsChanged", "newNode", [nodeOnePos, nodeTwoPos])
						
					else:   
						
						# we dont draw the node that sits onto the crossroad since it already exists
						
						previousNode.neighbourNodes += [intersection]
						intersection.neighbourNodes += [previousNode]
						
						var nodeOnePos = previousNode.nodeBody.global_transform.origin
						var nodeTwoPos = intersection.nodeBody.global_transform.origin
						
						if intersection.neighbourNodes.size() > 2:
							emit_signal("arrayRoadsChanged", "newNode", [nodeOnePos, nodeTwoPos])
						else:
							emit_signal("arrayRoadsChanged", "withEnd", [nodeOnePos, nodeTwoPos])
					
				
			
		
	else:
		
		print("They are already neighbours")
		
	
	buildMode = false
	
	for i in range(0, arrayCurrentlyDrawing.size()):
		
		$roadNodes.remove_child(arrayCurrentlyDrawing[i])
		
	
	arrayCurrentlyDrawing.clear()
	
	emit_signal("readyToSendNodeData", arrayRoadNodes)

##############################################################

func requestNodeRemoval(node):
	
	var nodePos = node.nodeBody.global_transform.origin
	
	emit_signal("arrayRoadsChanged", "roadEndRemoval", [nodePos])
	emit_signal("arrayRoadsChanged", "newRemovalByTheEndPoint", [nodePos])
	
	$roadNodes.remove_child(node.nodeBody)
	
	emit_signal("arrayRoadsChanged", "newRemoval", [nodePos])
	
	arrayRoadNodes.erase(node)
	
	for i in range(0, arrayRoadNodes.size()):
		if arrayRoadNodes[i].neighbourNodes.find(node) != -1:
			arrayRoadNodes[i].neighbourNodes.erase(node)
			
		
	
	emit_signal("readyToSendNodeData", arrayRoadNodes)

func processBodyInBuildingCursor(body):
	
	if body.get_class() == "StaticBody":
		for i in range(0, arrayRoadNodes.size()):
			if body == arrayRoadNodes[i].nodeBody and arrayNodeBodiesInArea.find(body) == -1:
				
				arrayNodeBodiesInArea += [body]
				
			

func processBodyLeavingCursor(body):
	
	if arrayNodeBodiesInArea.find(body) != -1:
		arrayNodeBodiesInArea.erase(body)
	


func _physics_process(delta):
	
	getLmbCollider()
	
	drawingRoad()
	
	drawBuildingCursor()
	

func _on_btnAddRoad_button_up():
	
	buildMode = true
	
	removeMode = false
	



func _on_btnRemoveNode_button_up():
	
	buildMode = false
	if removeMode == false:
		removeMode = true
		$pnlRoad/btnRemoveNode.text = "X"
	else:
		removeMode = false
		$pnlRoad/btnRemoveNode.text = "-"
	
	pass # Replace with function body.

func _on_btnRoadMode_button_up():
	if $pnlRoad.is_visible_in_tree() == false:
		
		$pnlRoad.show()
		$roadNodes.show()
		$pnlBuilding.hide()
		
	else:
		
		buildMode = false
		testPathFindMode = false
		removeMode = false
		placingBuildingMode = false
		
		$pnlRoad.hide()
		$roadNodes.hide()
		$buildingAreaCursor.hide()
	

func _on_btnTestPath_button_up():
	
	if testPathFindMode == false:
		testPathFindMode = true
		buildMode = false
		removeMode = false
		placingBuildingMode = false
		
		$buildingAreaCursor.hide()
		
		emit_signal("readyToSendNodeData", arrayRoadNodes)
		$pnlMode/btnTestPath.text = "Selecting"
		
	else:
		testPathFindMode = false
		nodePositionsForTestPathFind.clear()
		
		$pnlMode/btnTestPath.text = "Test path"
	
	pass 


func _on_btnBuildingsMode_button_up():
	
	$pnlRoad.hide()
	
	buildMode = false
	removeMode = false
	testPathFindMode = false
	
	if $pnlBuilding.is_visible_in_tree() == false:
		
		$pnlBuilding.show()
	else:
		$pnlBuilding.hide()
	
	
	
	pass # Replace with function body.
