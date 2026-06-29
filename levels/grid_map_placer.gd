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
		for inst: Vector3i in instance_array:
			_instance_item_on_cell(place_dict[index],inst)
	
	for location: Vector3i in location_place_dict:
		_instance_item_on_cell(location_place_dict[location],location)


func _instance_item_on_cell(scene: PackedScene, location: Vector3i) -> void:
	var inst_scene := scene.instantiate() as Node3D
	assert(inst_scene, "Scene to be instantiated was not derived from Node3D")
	add_child(inst_scene)
	_place_item_on_map(inst_scene,location)


func _place_item_on_map(item: Node3D, location: Vector3i) -> void:
	var inst_location: Vector3 = to_global(map_to_local(location))
	inst_location.y += vertical_offset
	item.global_position = inst_location
	print(item.global_position)
