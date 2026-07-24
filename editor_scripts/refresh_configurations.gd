@tool
extends EditorScript

const SEGMENT_PATH: String = "res://levels/minos_level_elements/"
const MINOS_CSG_GRID_LIBRARY = preload("uid://bgb5damgkyvtu")


# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	var segment_dir := EditorInterface.get_resource_filesystem().get_filesystem_path(SEGMENT_PATH)
	
	var translation_table: Dictionary[String,int] = MINOS_CSG_GRID_LIBRARY.get_name_to_id_translation_table()

	
	for i in range(segment_dir.get_file_count()):
		if segment_dir.get_file_type(i) == "Resource":
			var segment_path: String = segment_dir.get_file_path(i)
			var segment: MinosMapConfiguration = load(segment_path)
			var loaded_dict := segment.configuration_dict.merged(segment.edge_locations)
			MinosMapConfiguration._swap_via_table(loaded_dict,translation_table)
			var new_config := MinosMapConfiguration.generate_configuration_resource(loaded_dict,MINOS_CSG_GRID_LIBRARY,true)
			ResourceSaver.save(new_config,segment_path)
			new_config.take_over_path(segment_path)
	pass
