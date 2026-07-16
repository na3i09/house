extends EditorResourceConversionPlugin


func _handles(resource: Resource) -> bool:
	return resource is MeshLibrary


func _converts_to() -> String:
	return "MinosMeshLibrary"


func _convert(resource: Resource) -> Resource:
	var source_mesh_library: MeshLibrary = resource as MeshLibrary
	
	var minos_mesh_library := MinosMeshLibrary.new()
	
	for id in source_mesh_library.get_item_list():
		minos_mesh_library.create_item(id)
		_push_mesh_item_to_new_mesh_lib(id,source_mesh_library,minos_mesh_library)
	
	
	return minos_mesh_library


func _push_mesh_item_to_new_mesh_lib(id: int, source: MeshLibrary, destination: MeshLibrary) -> void:
	destination.set_item_mesh(id,source.get_item_mesh(id))
	destination.set_item_mesh_cast_shadow(id,source.get_item_mesh_cast_shadow(id))
	destination.set_item_mesh_transform(id,source.get_item_mesh_transform(id))
	destination.set_item_preview(id,source.get_item_preview(id))
	destination.set_item_shapes(id,source.get_item_shapes(id))
	destination.set_item_name(id,source.get_item_name(id))
