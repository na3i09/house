extends GridMap
class_name GridMapPlacer
## [GridMap] with support for placing packed scenes into locations on the grid map

## [Dictionary] for scenes to be places onto all cells with matching grid map items
@export var place_dict: Dictionary[int,PackedScene]

## [Dictionary] for scenes to be placed only on specified grid cell locations
@export var location_place_dict: Dictionary[Vector3i,PackedScene]

## Vertical offset for placing scenes onto grid map
@export var vertical_offset: float = 0.0


func _ready() -> void:
	for index in place_dict:
		var instance_array: Array[Vector3i] = get_used_cells_by_item(index)
		for inst in instance_array:
			var inst_scene = place_dict[index].instantiate() as Node3D
			add_child(inst_scene)
			var inst_location: Vector3 = to_global(map_to_local(inst))
			inst_location.y += vertical_offset
			inst_scene.global_position = inst_location
			print(inst_scene.global_position)
	
	for location in location_place_dict:
		var inst_scene = location_place_dict[location].instantiate() as Node3D
		add_child(inst_scene)
		var inst_location: Vector3 = to_global(map_to_local(location))
		inst_location.y += vertical_offset
		inst_scene.global_position = inst_location
		print(inst_scene.global_position)
