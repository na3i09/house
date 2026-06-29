extends GridMap
class_name GridMapPlacer

@export var place_dict: Dictionary[int,PackedScene]

@export var location_place_dict: Dictionary[Vector3i,PackedScene]

@export var verticle_offset: float = 0.0


func _ready() -> void:
	for index in place_dict:
		var instance_array: Array[Vector3i] = get_used_cells_by_item(index)
		for inst in instance_array:
			var inst_scene = place_dict[index].instantiate() as Node3D
			add_child(inst_scene)
			var inst_location: Vector3 = to_global(map_to_local(inst))
			inst_location.y += verticle_offset
			inst_scene.global_position = inst_location
			print(inst_scene.global_position)
	
	for location in location_place_dict:
		var inst_scene = location_place_dict[location].instantiate() as Node3D
		add_child(inst_scene)
		var inst_location: Vector3 = to_global(map_to_local(location))
		inst_location.y += verticle_offset
		inst_scene.global_position = inst_location
		print(inst_scene.global_position)
