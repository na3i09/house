extends Resource
class_name RandomItemSelection


@export var options: Array[PackedScene]

@export var chance: float = 0.1


func pick_item() -> PackedScene:
	var landed: float = randf()
	if landed < chance:
		var selection: int = randi_range(0,options.size()-1)
		return options[selection]
	else:
		return null
