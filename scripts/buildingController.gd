extends Spatial

export (PackedScene) var buildingFactory
export (PackedScene) var buildingResidential

var arrayBuildings = []

class building:
	
	var buildingBody
	var buildingType
	
	var entrancePoint
	

func _ready():
	pass # Replace with function body.

func placeBuilding(type, pos, rot):
	
	print("Building new ", type)
	
	var newBuilding = building.new()
	
	match type:
		"Factory":
			newBuilding.buildingBody = buildingFactory.instance()
		
		"Residential":
			newBuilding.buildingBody = buildingResidential.instance()
	
	add_child(newBuilding.buildingBody)
	newBuilding.buildingBody.global_transform.origin = pos
	newBuilding.buildingBody.rotation_degrees = rot
	
	arrayBuildings += [newBuilding]

func checkIfBuildingForRemoval(obj):
	for i in range(0, arrayBuildings.size()):
		if arrayBuildings[i].buildingBody == obj:
			arrayBuildings.erase(arrayBuildings[i])
			
			remove_child(obj)
			
			break
		
	



