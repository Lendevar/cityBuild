extends Spatial

func _ready():
	
	$playerController.connect("arrayRoadsChanged", $roadController, "receiveRoadChange")
	$roadController.connect("roadBodyHasBeenPlaced", $playerController, "updateRoadBodiesArray")
	$playerController.connect("requestRoadBodyRemoval", $roadController, "bodyRemoval")
	
	pass # Replace with function body.

