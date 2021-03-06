extends Spatial

export (PackedScene) var simpleRoad
export (PackedScene) var roadEnd

export (PackedScene) var upgradedRoad

export (Array) var roadBodies
export (Array) var roadEnds

signal roadBodyHasBeenPlaced

signal transmitAnchorPoints(anchors, road)

func _ready():
	
	
	pass

func removeRoadEnd(nodes):
	for i in range(0, roadEnds.size()):
		
		if roadEnds[i].global_transform.origin == nodes[1]:
			
			$roadBodies.remove_child(roadEnds[i])
			
			roadEnds.erase(roadEnds[i])
			
			break
		

func receiveRoadChange(whatHappened, nodes):
	
	print(whatHappened, nodes)
	
	match whatHappened:
		"newNode":
			
			var newRoadBody = simpleRoad.instance()
			
			$roadBodies.add_child(newRoadBody)
			
			newRoadBody.global_transform.origin = nodes[0]
			
			newRoadBody.scale.z = nodes[0].distance_to(nodes[1])/2
			newRoadBody.look_at(nodes[1], Vector3(0,1,0))
			
			get_node(str(newRoadBody.get_path()) + "/endPoint").global_transform.origin = nodes[1]
			
			roadBodies += [newRoadBody]
			
			removeRoadEnd(nodes)
			
			emit_signal("roadBodyHasBeenPlaced", roadBodies)
			
		
		"withEnd":
			
			var newRoadBody = simpleRoad.instance()
			
			$roadBodies.add_child(newRoadBody)
			
			newRoadBody.global_transform.origin = nodes[0]
			
			newRoadBody.scale.z = nodes[0].distance_to(nodes[1])/2
			newRoadBody.look_at(nodes[1], Vector3(0,1,0))
			
			get_node(str(newRoadBody.get_path()) + "/endPoint").global_transform.origin = nodes[1]
			
			roadBodies += [newRoadBody]
			
			var newRoadEnd = roadEnd.instance()
			
			removeRoadEnd(nodes)
			
			$roadBodies.add_child(newRoadEnd)
			
			newRoadEnd.global_transform.origin = nodes[1]
			
			newRoadEnd.look_at(nodes[0], Vector3(0,1,0))
			
			roadEnds += [newRoadEnd]
			
			emit_signal("roadBodyHasBeenPlaced", roadBodies)
			
		
		"newRemoval":
			
			var bodiesToRemove = []
			
			for i in range(0, nodes.size()):
				for j in range(0, roadBodies.size()):
					if roadBodies[j].is_inside_tree():
						if nodes[i] == roadBodies[j].global_transform.origin:
							
							$roadBodies.remove_child(roadBodies[j])
							bodiesToRemove += [roadBodies[j]]
						
					
				
			
			for i in range(0, bodiesToRemove.size()):
				roadBodies.erase(bodiesToRemove[i])
			
			emit_signal("roadBodyHasBeenPlaced", roadBodies)
			
		
		"roadEndRemoval":
			
			for i in range(0, roadEnds.size()):
				if nodes[0] == roadEnds[i].global_transform.origin:
					
					$roadBodies.remove_child(roadEnds[i])
					roadEnds.erase(roadEnds[i])
					
					break
				
			
		
		"newRemovalByTheEndPoint":
			
			var flooredInputPoint = Vector3(floor(nodes[0].x), floor(nodes[0].y), floor(nodes[0].z))
			
			var bodiesToRemove = []
			
			for i in range(0, roadBodies.size()):
				
				var endPoint = get_node(str(roadBodies[i].get_path()) + "/endPoint").global_transform.origin
				var flooredEndPoint = Vector3(floor(endPoint.x),floor(endPoint.y),floor(endPoint.z))
				
				if flooredInputPoint == flooredEndPoint:
					$roadBodies.remove_child(roadBodies[i])
					bodiesToRemove += [roadBodies[i]]
				
			
			for i in range(0, bodiesToRemove.size()):
				roadBodies.erase(bodiesToRemove[i])


func bodyRemoval(positions):
	for i in range(0, roadBodies.size()):
		
		var startPos = roadBodies[i].global_transform.origin
		var endPos = get_node(str(roadBodies[i].get_path()) + "/endPoint").global_transform.origin
		
		if startPos == positions[0] and endPos == positions[1]:
			
			$roadBodies.remove_child(roadBodies[i])
			roadBodies.erase(roadBodies[i])
			
			break
		
	

func upgradeRoad(start, end):
	
	var flooredStart = Vector3(floor(start.x),floor(start.y),floor(start.z))
	var flooredEnd = Vector3(floor(end.x),floor(end.y),floor(end.z))
	
	for i in range(0, roadBodies.size()):
		
		var bodyStart = roadBodies[i].global_transform.origin
		var bodyEnd = get_node(str(roadBodies[i].get_path()) + "/endPoint").global_transform.origin
		
		var flooredBodyStart = Vector3(floor(bodyStart.x),floor(bodyStart.y),floor(bodyStart.z))
		var flooredBodyEnd = Vector3(floor(bodyEnd.x),floor(bodyEnd.y),floor(bodyEnd.z))
		
		if flooredStart == flooredBodyStart and flooredEnd == flooredBodyEnd:
			
			var roadScale = roadBodies[i].scale
			var rot = roadBodies[i].rotation
			
			$roadBodies.remove_child(roadBodies[i])
			
			roadBodies[i] = upgradedRoad.instance()
			
			$roadBodies.add_child(roadBodies[i])
			
			roadBodies[i].global_transform.origin = bodyStart
			roadBodies[i].rotation = rot
			roadBodies[i].scale = roadScale
			get_node(str(roadBodies[i].get_path()) + "/endPoint").global_transform.origin = bodyEnd
			
			var arrayAnchors = []
			
			for a in range(1,4):
				arrayAnchors += [get_node(str(roadBodies[i].get_path()) + "/" + str(a))]
				arrayAnchors += [get_node(str(roadBodies[i].get_path()) + "/-" + str(a))]
			
			emit_signal("transmitAnchorPoints", arrayAnchors, roadBodies[i])
			
		
	

