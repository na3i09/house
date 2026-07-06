@tool
extends EditorScript
class_name GenerateMapConfig

# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	
	var placer: GridMapPlacer
	
	if scene_root is GridMapPlacer:
		placer = scene_root as GridMapPlacer
	else:
		var map_placers := scene_root.find_children("*","GridMapPlacer")
		
		if map_placers.is_empty():
			return
		
		placer = map_placers[0] as GridMapPlacer
	
	if not placer:
		return
	
	var scene_path: String = scene_root.scene_file_path
	
	var config: GridMapConfiguration = generate_configuration_resource(placer)
	
	ResourceSaver.save(config,scene_path.replace(".tscn",".tres"))

func generate_configuration_resource(_placer: GridMapPlacer) -> GridMapConfiguration:
	var config_resource: GridMapConfiguration = GridMapConfiguration.new()
	
	config_resource.configuration_dict = GridMapPlacer.generate_static_configuration_dictionary(_placer)
	
	var edge_id: int = _placer.mesh_library.find_item_by_name("Edge")
	if edge_id != -1:
		var edge_locs := _placer.get_used_cells_by_item(edge_id)
		for edge in edge_locs:
			config_resource.edge_locations[edge] = _placer.get_cell_item_orientation(edge)
			config_resource.configuration_dict.erase(edge)
	
	return config_resource
