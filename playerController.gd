extends Spatial


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
	
	
	pass


func nodeHasBeenClicked(id):
	
	$pnlRoad.show()
	currentlyDrawingFrom = id
	



############### Turning ray to the click position

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
			
		
	

var roadEnd = Vector3()
var roadVector = Vector3()
var directionVector = Vector3()

export (int) var distanceBetweenNodes = 10

var nodesToDraw = 0

var arrayCurrentlyDrawing = []

var mouseMoved
var mousePos

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
		
	
	if buildMode == true:
		if Input.is_action_just_pressed("mouse_left"):
			
			var arrayRoad = []
			
			for i in range(0, arrayCurrentlyDrawing.size()):
				
				arrayRoad += [arrayCurrentlyDrawing[i].global_transform.origin]
				
			
			arrayRoad += [roadEnd]
			
			requestRoadBuild(arrayRoad)
			
			#print(arrayRoad)
	
	
	
	mousePos = get_viewport().get_mouse_position()
	
	

########################## This thing should probably be requested from server


func requestRoadBuild(roadArray):
	
	
	if roadArray.size() != 0:
		
		var firstNode = roadNode.new()
		firstNode.nodeBody = singleRoadNode.instance()
		firstNode.neighbourNodes += [arrayRoadNodes[currentlyDrawingFrom]]
		
		arrayRoadNodes += [firstNode]
		
		$roadNodes.add_child(firstNode.nodeBody)
		firstNode.nodeBody.global_transform.origin = roadArray[0]
		
		if roadArray.size() > 1:
			
			for i in range(1, roadArray.size()):
				
				var newNode = roadNode.new()
				
				newNode.nodeBody = singleRoadNode.instance()
				newNode.neighbourNodes += [arrayRoadNodes[i-1]]
				
				arrayRoadNodes += [newNode]
				
				$roadNodes.add_child(newNode.nodeBody)
				newNode.nodeBody.global_transform.origin = roadArray[i]
				
				pass
	
	buildMode = false
	currentlyDrawingFrom = -1
	
	for i in range(0, arrayCurrentlyDrawing.size()):
		
		arrayCurrentlyDrawing[i].hide()
		
	
	pass





func _physics_process(delta):
	
	getLmbCollider()
	
	drawingRoad()


func _on_btnAddRoad_button_up():
	
	buildMode = true
	
	print(currentlyDrawingFrom)
	
	pass 
