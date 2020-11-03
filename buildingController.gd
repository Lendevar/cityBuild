extends Spatial

export (PackedScene) var buildingFactory

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
	
	newBuilding.buildingBody = buildingFactory.instance()
	add_child(newBuilding.buildingBody)
	newBuilding.buildingBody.global_transform.origin = pos
	newBuilding.buildingBody.rotation_degrees = rot
	
	arrayBuildings += [newBuilding]


