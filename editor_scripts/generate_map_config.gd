@tool
extends EditorScript
class_name GenerateMapConfig

# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	
	var map_placers := scene_root.find_children("*","GridMapPlacer")
	
	if map_placers.is_empty():
		return
	
	var placer := map_placers[0] as GridMapPlacer
	if not placer:
		return
	
	var scene_path: String = scene_root.scene_file_path
	
	var config: GridMapConfiguration = generate_configuration_resource(placer)
	
	ResourceSaver.save(config,scene_path.replace(".tscn",".tres"))

func generate_configuration_resource(_placer: GridMapPlacer) -> GridMapConfiguration:
	var serialized_dict: Dictionary[Vector3i,Array]
	
	var tiles_used: Array[Vector3i] = _placer.get_used_cells()
	
	for tile_pos: Vector3i in tiles_used:
		serialized_dict[tile_pos] = [_placer.get_cell_item(tile_pos)]
	
	for index: int in _placer.place_dict:
		var instance_array: Array[Vector3i] = _placer.get_used_cells_by_item(index)
		for inst: Vector3i in instance_array:
			serialized_dict[inst].append(_placer.possible_items.find(_placer.place_dict[index]))
	
	for location: Vector3i in _placer.location_place_dict:
		serialized_dict[location].append(_placer.possible_items.find(_placer.location_place_dict[location]))
	
	var config_resource: GridMapConfiguration = GridMapConfiguration.new()
	
	config_resource.configuration_dict = serialized_dict
	
	return config_resource
