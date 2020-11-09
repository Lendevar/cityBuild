extends Spatial

func _ready():
	
	print("Loading map")
	var defaultMap = load("res://maps/defaultMap.tscn")
	var currentMap = defaultMap.instance()
	add_child(currentMap)
	
	$playerController.connect("arrayRoadsChanged", $roadController, "receiveRoadChange")
	$roadController.connect("roadBodyHasBeenPlaced", $playerController, "updateRoadBodiesArray")
	$playerController.connect("requestRoadBodyRemoval", $roadController, "bodyRemoval")
	$playerController.connect("readyToSendNodeData", self, "sendNodeData")
	$playerController.connect("requestTestPathFind", $trafficController, "getImportedNodesByPositions")
	$playerController.connect("requestBuildingPlacement", $buildingController, "placeBuilding")
	$playerController.connect("requestBuildingRemoval", $buildingController, "checkIfBuildingForRemoval")
	$playerController.connect("requestRoadUpgrade", $roadController, "upgradeRoad")
	$roadController.connect("transmitAnchorPoints", $playerController, "receiveAnchorPoints")
	
	
	


func sendNodeData(arrayNodes):
	$trafficController.importedRoadNodes = arrayNodes

