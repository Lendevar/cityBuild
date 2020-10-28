extends Spatial

export (PackedScene) var simpleRoad

export (Array) var roadBodies


func _ready():
	
	
	pass

func receiveRoadChange(whatHappened, nodes):
	
	print(whatHappened, nodes)
	
	match whatHappened:
		"newNode":
			
			var newRoadBody = simpleRoad.instance()
			
			$roadBodies.add_child(newRoadBody)
			
			newRoadBody.global_transform.origin = nodes[0]
			newRoadBody.look_at(nodes[1], Vector3(0,1,0))
			
	
	pass 





