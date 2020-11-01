extends Spatial

func _ready():
	
	$playerController.connect("arrayRoadsChanged", $roadController, "receiveRoadChange")
	$roadController.connect("roadBodyHasBeenPlaced", $playerController, "updateRoadBodiesArray")
	$playerController.connect("requestRoadBodyRemoval", $roadController, "bodyRemoval")
	$playerController.connect("readyToSendNodeData", self, "sendNodeData")
	$playerController.connect("requestTestPathFind", $trafficController, "getImportedNodesByPositions")
	
	pass # Replace with function body.

func sendNodeData(arrayNodes):
	$trafficController.importedRoadNodes = arrayNodes

