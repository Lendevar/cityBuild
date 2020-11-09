extends Spatial

const PositiveInfinity = 3.402823e+38

export (Array) var importedRoadNodes

export (PackedScene) var testBody



class roadNode:
	
	var nodeBody
	var neighbourNodes = []
	

class vehicle:
	
	var vehicleBody
	var vehiclePathFollow
	var vehiclePath
	
	var vehicleMaxSpeed = 2
	
	var inventory = {}
	

var arrayVehicles = []

func _ready():
	pass # Replace with function body.

func getImportedNodesByPositions(positions):
	
	var start
	var target
	
	var isFound = 0
	
	for i in range(0, importedRoadNodes.size()):
		
		var currentPos = importedRoadNodes[i].nodeBody.global_transform.origin
		var flooredCurrentPos = Vector3(floor(currentPos.x),floor(currentPos.y),floor(currentPos.z))
		
		if flooredCurrentPos == positions[0]:
			start = importedRoadNodes[i]
			isFound += 0.5
		
		if flooredCurrentPos == positions[1]:
			target = importedRoadNodes[i]
			isFound += 0.5
		
		if isFound == 1:
			break
	
	#var pathNodes = findPath(start, target)
	
	var pathNodes = AstarPathfind(start, target)
	
	print("Path found! ", pathNodes)
	
	var newVehicle = vehicle.new()
	newVehicle.vehicleBody = testBody.instance()
	
	newVehicle.vehiclePath = Path.new()
	
	if pathNodes.size() != 0:
		for i in range(0, pathNodes.size()):
			
			newVehicle.vehiclePath.curve.add_point(pathNodes[i])
			
		
	else:
		newVehicle.vehiclePath.curve.add_point(target.nodeBody.global_transform.origin)
	
	newVehicle.vehiclePathFollow = PathFollow.new()
	newVehicle.vehiclePathFollow.loop = false
	newVehicle.vehiclePathFollow.set_rotation_mode(4)
	
	newVehicle.vehiclePathFollow.add_child(newVehicle.vehicleBody)
	newVehicle.vehiclePath.add_child(newVehicle.vehiclePathFollow)
	
	add_child(newVehicle.vehiclePath)
	newVehicle.vehiclePathFollow.look_at(newVehicle.vehiclePath.curve.get_baked_points()[0], Vector3(0,1,0))
	
	arrayVehicles += [newVehicle]


class MyCustomSorter:
	static func sort_ascending(a, b):
		if a[0] < b[0]:
			return true
		return false

func AstarPathfind(start, target):
	
	var astar = AStar.new()
	
	for i in range(0, importedRoadNodes.size()):
		astar.add_point(i, importedRoadNodes[i].nodeBody.global_transform.origin)
	
	for i in range(0, importedRoadNodes.size()):
		for j in range(0, importedRoadNodes[i].neighbourNodes.size()):
			
			var neighbourPoint = importedRoadNodes.find(importedRoadNodes[i].neighbourNodes[j])
			
			if astar.are_points_connected(i, neighbourPoint, true) == false:
				astar.connect_points(i, neighbourPoint, true)
			
			
		
	
	var startId = importedRoadNodes.find(start)
	var targetId = importedRoadNodes.find(target)
	
	return astar.get_point_path(startId, targetId)




func _physics_process(delta):
	
	for i in range(0, arrayVehicles.size()):
		
		arrayVehicles[i].vehiclePathFollow.offset += lerp(0, arrayVehicles[i].vehicleMaxSpeed, +0.05)
		
		if arrayVehicles[i].vehiclePathFollow.unit_offset == 1:
			
			remove_child(arrayVehicles[i].vehiclePath)
			
			arrayVehicles.erase(arrayVehicles[i])
			break
		
	



