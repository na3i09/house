@tool
extends MeshLibrary
class_name MinosMeshLibrary


@export_storage var edge_info: Dictionary[int,Array]


func set_edge(item_id: int) -> void:
	edge_info.get_or_add(item_id,[])


func remove_edge(item_id: int) -> void:
	edge_info.erase(item_id)


func is_edge(item_id: int) -> bool:
	return edge_info.has(item_id)


func add_edge_mate(item_id: int, mate_id: int) -> void:
	if edge_info.has(item_id):
		if not edge_info[item_id].has(mate_id):
			edge_info[item_id].append(mate_id)


func remove_edge_mate(item_id: int, mate_id: int) -> void:
	if edge_info.has(item_id):
		edge_info[item_id].erase(mate_id)


func get_id_to_name_translation_table() -> Dictionary[int,String]:
	var translation_table: Dictionary[int,String]
	
	for id: int in get_item_list():
		translation_table[id] = get_item_name(id)
	
	return translation_table


func get_name_to_id_translation_table() -> Dictionary[String,int]:
	var translation_table: Dictionary[int,String] = get_id_to_name_translation_table()
	
	var inverse_translation_table: Dictionary[String,int]
	
	for id in translation_table:
		inverse_translation_table[translation_table[id]] = id
	
	return inverse_translation_table
