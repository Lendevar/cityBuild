extends Spatial

func _ready():
	
	$playerController.connect("arrayRoadsChanged", $roadController, "receiveRoadChange")
	
	pass # Replace with function body.

