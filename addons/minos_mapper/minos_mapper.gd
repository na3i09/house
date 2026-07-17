@tool
extends EditorPlugin


const MINOS_BOTTOM_PANEL = preload("res://addons/minos_mapper/minos_bottom_panel.tscn")

const ConvertMeshLibToMinos = preload("res://addons/minos_mapper/convert_mesh_lib_to_minos.gd")


var export_as_menu: PopupMenu = null

var menu_item_id: int = -1

var save_dialog: EditorFileDialog = null

var load_dialog: EditorFileDialog = null

var save_callable: Callable

var load_callable: Callable

var bottom_panel: EditorDock = null

var editor_selection: EditorSelection = null

var conversion_plugin: EditorResourceConversionPlugin

var minos_mesh_save_dialog: EditorFileDialog = null

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	export_as_menu = get_export_as_menu()
	minos_mesh_save_dialog = _create_save_dialog(_create_minos_mesh_library)
	_add_export_as_entry(export_as_menu)
	editor_selection = EditorInterface.get_selection()
	_create_placer_bottom_panel()
	save_dialog = _create_save_dialog(save_callable)
	load_dialog = _create_load_dialog(load_callable)
	conversion_plugin = ConvertMeshLibToMinos.new()
	add_resource_conversion_plugin(conversion_plugin)
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	_remove_export_as_entry(export_as_menu)
	_destory_file_dialog(minos_mesh_save_dialog)
	_destory_file_dialog(save_dialog)
	_destory_file_dialog(load_dialog)
	_destory_placer_bottom_panel()
	remove_resource_conversion_plugin(conversion_plugin)
	pass


func _handles(object: Object) -> bool:
	if object is MinosMap:
		return true
	else:
		return false


func _make_visible(visible: bool) -> void:
	if visible:
		if bottom_panel:
			bottom_panel.open()
	else:
		if bottom_panel:
			bottom_panel.close()


func _create_placer_bottom_panel() -> void:
	bottom_panel = MINOS_BOTTOM_PANEL.instantiate()
	
	bottom_panel.show_save_dialog = show_save_dialog
	save_callable = bottom_panel.save_configuration
	bottom_panel.show_load_dialog = show_load_dialog
	load_callable = bottom_panel.load_configuration
	
	if editor_selection:
		bottom_panel.editor_selection = editor_selection
	
	add_dock(bottom_panel)
	bottom_panel.close()


func _destory_placer_bottom_panel() -> void:
	if bottom_panel:
		bottom_panel.editor_selection = null
		remove_dock(bottom_panel)
		bottom_panel.queue_free()


func _create_save_dialog(_save_callable: Callable) -> EditorFileDialog:
	if not _save_callable.is_valid():
		return null
	
	var _save_dialog := EditorFileDialog.new()
	
	_save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	
	_save_dialog.add_filter("*.tres", "Godot Resourses")
	
	_save_dialog.file_selected.connect(_save_callable)
	EditorInterface.get_base_control().add_child(_save_dialog)
	
	return _save_dialog


func _destory_file_dialog(_dialog: EditorFileDialog) -> void:
	if _dialog:
		_dialog.queue_free()


func show_save_dialog() -> void:
	save_dialog.popup_centered_clamped(Vector2i(700,500))	


func _create_load_dialog(_load_callable: Callable) -> EditorFileDialog:
	if not _load_callable.is_valid():
		return null
	
	var _load_dialog := EditorFileDialog.new()
	
	_load_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_load_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	
	_load_dialog.add_filter("*.tres", "Godot Resourses")
	
	_load_dialog.file_selected.connect(_load_callable)
	EditorInterface.get_base_control().add_child(_load_dialog)
	
	return _load_dialog


func show_load_dialog() -> void:
	load_dialog.popup_centered_clamped(Vector2i(700,500))	


func _add_export_as_entry(menu: PopupMenu) -> void:
	menu_item_id = randi() % 10000
	var safety: int = 0
	while menu.get_item_index(menu_item_id) != -1 and safety < 30:
		menu_item_id = randi() % 10000
		safety += 1
	menu.add_item("MinosMeshLibrary...",menu_item_id)
	# callable set here will be called when menu item is pressed, totally undocumented functionality
	menu.set_item_metadata(menu.get_item_index(menu_item_id),_show_minos_mesh_save_dialog)


func _remove_export_as_entry(menu: PopupMenu) -> void:
	var menu_item_index: int = menu.get_item_index(menu_item_id)
	menu.remove_item(menu_item_index)


func _show_minos_mesh_save_dialog() -> void:
	minos_mesh_save_dialog.popup_centered_clamped(Vector2i(700,500))


func _create_minos_mesh_library(save_path: String) -> void:
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	
	var csgs: Array = scene_root.find_children("*","CSGShape3D",false)
	
	var generated_nodes: Array[Node] = []
	
	for csg: CSGShape3D in csgs:
		var baked_mesh: ArrayMesh = csg.bake_static_mesh()
		
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.mesh = baked_mesh
		mesh_inst.name = csg.name.replace("CSG","")
		scene_root.add_child(mesh_inst)
		mesh_inst.global_position = csg.global_position
		generated_nodes.append(mesh_inst)
		
		mesh_inst.create_trimesh_collision()
		
		var meta_list: Array[StringName] = csg.get_meta_list().filter(_filter_metadata)
		
		for meta: StringName in meta_list:
			mesh_inst.set_meta(meta,csg.get_meta(meta))
	
	var mesh_lib: MinosMeshLibrary = _build_mesh_library(scene_root)
	
	ResourceSaver.save(mesh_lib,save_path)
	
	for node in generated_nodes:
		node.queue_free()

func _filter_metadata(element: StringName) -> bool:
	if element.begins_with("minos_"):
		return true
	else:
		return false

# create [MinosMeshLibrary] from a scene tree following the format of the standard mesh library generator
func _build_mesh_library(scene_root: Node) -> MinosMeshLibrary:
	var mesh_lib := MinosMeshLibrary.new()
	
	var mesh_instances: Array[Node] = scene_root.find_children("*","MeshInstance3D",false,false)
	
	var mesh_preview_dict: Dictionary[int,Mesh]
	
	# collect library parameters from mesh instances
	for mesh: MeshInstance3D in mesh_instances:
		var mesh_resource: Mesh = mesh.mesh
		
		var mesh_name: String = mesh.name
		
		var collision: StaticBody3D = mesh.find_children("*","StaticBody3D",true,false).get(0)
		
		var col_shapes: Array
		
		var shapes: Array = collision.find_children("*","CollisionShape3D",true,false)
		
		for shape in shapes:
			col_shapes.append_array([shape.shape,shape.transform])
		
		var item_id: int = mesh_lib.get_last_unused_item_id()
		
		mesh_lib.create_item(item_id)
		
		mesh_lib.set_item_mesh(item_id,mesh_resource)
		mesh_lib.set_item_shapes(item_id,col_shapes)
		mesh_lib.set_item_name(item_id,mesh_name)
		
		mesh_preview_dict[item_id] = mesh_resource
		
		_apply_metadata_and_suffixes(mesh,item_id,mesh_lib)
	
	var previews: Array[Texture2D] = EditorInterface.make_mesh_previews(mesh_preview_dict.values(),64)
	
	for i: int in range(mesh_preview_dict.keys().size()):
		mesh_lib.set_item_preview(mesh_preview_dict.keys()[i],previews[i])
	
	var overlay_texture: Texture2D = load("res://addons/minos_mapper/assets/E.png") #TODO: consider moving into file preload for responsiveness
	var overlay_image: Image = overlay_texture.get_image()
	
	# apply overlay image onto edge items
	for edge_id in mesh_lib.edge_info:
		var preview_tex: Texture2D = mesh_lib.get_item_preview(edge_id)
		
		var preview_image: Image = preview_tex.get_image()
		
		preview_image.blend_rect(overlay_image,Rect2i(0,0,overlay_image.get_width(),overlay_image.get_height()),Vector2i(0,0))
		
		if preview_tex is ImageTexture:
			preview_tex.update(preview_image)
		else:
			var blended_texture := ImageTexture.create_from_image(preview_image)
			mesh_lib.set_item_preview(edge_id,blended_texture)
	
	return mesh_lib


func _apply_metadata_and_suffixes(mesh: MeshInstance3D, item_id: int, mesh_lib: MinosMeshLibrary) -> void:
	var mesh_name: String = mesh.name
	
	if mesh_name.ends_with("-edge"):
		mesh_name = mesh_name.trim_suffix("-edge")
		mesh_lib.set_item_name(item_id,mesh_name)
		mesh_lib.set_edge(item_id)

	if mesh.get_meta("minos_edge",false):
		mesh_lib.set_edge(item_id)
