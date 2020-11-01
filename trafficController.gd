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
	
	var pathNodes = findPath(start, target)
	
	var newVehicle = vehicle.new()
	newVehicle.vehicleBody = testBody.instance()
	
	newVehicle.vehiclePath = Path.new()
	
	for i in range(0, pathNodes.size()):
		
		newVehicle.vehiclePath.curve.add_point(pathNodes[i].nodeBody.global_transform.origin)
		
		
	
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

func findPath(start, target):
	
	print("Starting pathfind")
	
	var pathFound = []
	
	var closed = []
	
	var g_cost = []
	var h_cost = []
	var f_cost = []
	var neighbours = []
	var roadHelper
	
	var roadLengthSumm = 0
	
	var leastFcost = PositiveInfinity
	var nextStep
	var previousId
	
	var currentObject
	var current = start
	
	closed += [current]
	
	var iteration = 0
	
	pathFound += [start]
	
	while currentObject != target:
		for i in range(0, current.neighbourNodes.size()):
			
			neighbours += [current.neighbourNodes[i]]
			
		
		#print("current neighbours = ", neighbours)
		
		#neighbours = current.neighbourNodes
		
		for i in range(0, neighbours.size()):
			
			var dist = current.nodeBody.global_transform.origin.distance_to(neighbours[i].nodeBody.global_transform.origin)
			
			g_cost += [roadLengthSumm + dist]
			
			h_cost += [neighbours[i].nodeBody.global_transform.origin.distance_to(target.nodeBody.global_transform.origin)]
			
			f_cost += [g_cost.back() + h_cost.back()]
		
		var isFound = false
		
		for i in range(0, neighbours.size()):
			if floor(f_cost[i]) <= floor(leastFcost) and closed.find(neighbours[i]) == -1:
				leastFcost = f_cost[i]
				nextStep = neighbours[i]
				previousId = i
				isFound = true
		
		
		if isFound == false:
			var enumeratedArray = []
			
			for i in range(0, neighbours.size()):
				if closed.find(neighbours[i]) == -1:
					#enumeratedArray = [[neighbours[i] , i]]
					enumeratedArray = [[f_cost[i] , i]]
				
			
			if enumeratedArray.size() != 0:
				
				enumeratedArray.sort_custom(MyCustomSorter, "sort_ascending")
				
				leastFcost = f_cost[enumeratedArray[0][1]]
				nextStep = neighbours[enumeratedArray[0][1]]
				previousId = enumeratedArray[0][1]
			else:
				print("Pathfinding failed on iteration ", iteration, ", trying to get path to neighbour")
				#pathFound += [target]
				
				#pathFound = findPath(start, current.neighbourNodes[0])
				pathFound += [target]
				
				print("Path found = ", pathFound)
				
				return pathFound
			
			
			pass
		
		closed += [current]
		current = nextStep
		roadLengthSumm += g_cost[previousId]
		
		neighbours.clear()
		g_cost.clear()
		h_cost.clear()
		f_cost.clear()
		
		currentObject = current
		
		pathFound += [current]
		iteration += 1
	
	
	print("Path found = " + str(pathFound))
	return pathFound

func _physics_process(delta):
	
	for i in range(0, arrayVehicles.size()):
		
		arrayVehicles[i].vehiclePathFollow.offset += lerp(0, arrayVehicles[i].vehicleMaxSpeed, +0.05)
		
		if arrayVehicles[i].vehiclePathFollow.unit_offset == 1:
			
			remove_child(arrayVehicles[i].vehiclePath)
			
			arrayVehicles.erase(arrayVehicles[i])
			break
		
	
	
	
	
	


