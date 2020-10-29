extends Spatial

export (PackedScene) var simpleRoad
export (PackedScene) var roadEnd

export (Array) var roadBodies
export (Array) var roadEnds

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
			
			roadBodies += [newRoadBody]
			
			removeRoadEnd(nodes)
			
		
		"withEnd":
			
			var newRoadBody = simpleRoad.instance()
			
			$roadBodies.add_child(newRoadBody)
			
			newRoadBody.global_transform.origin = nodes[0]
			
			newRoadBody.scale.z = nodes[0].distance_to(nodes[1])/2
			newRoadBody.look_at(nodes[1], Vector3(0,1,0))
			
			roadBodies += [newRoadBody]
			
			var newRoadEnd = roadEnd.instance()
			
			removeRoadEnd(nodes)
			
			$roadBodies.add_child(newRoadEnd)
			
			newRoadEnd.global_transform.origin = nodes[1]
			
			newRoadEnd.look_at(nodes[0], Vector3(0,1,0))
			
			roadEnds += [newRoadEnd]
			
		
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
			
			
		
		"roadEndRemoval":
			
			for i in range(0, roadEnds.size()):
				if nodes[0] == roadEnds[i].global_transform.origin:
					
					$roadBodies.remove_child(roadEnds[i])
					roadEnds.erase(roadEnds[i])
					
					break
				
			
		




