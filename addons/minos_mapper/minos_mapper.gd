@tool
extends EditorPlugin


const MINOS_BOTTOM_PANEL = preload("res://addons/minos_mapper/minos_bottom_panel.tscn")


var export_as_menu: PopupMenu = null

var menu_item_id: int = -1

var save_dialog: EditorFileDialog = null

var bottom_panel: EditorDock = null


func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	export_as_menu = get_export_as_menu()
	_add_export_as_entry(export_as_menu)
	_create_save_dialog()
	_create_placer_bottom_panel()
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	_remove_export_as_entry(export_as_menu)
	_destory_save_dialog()
	_destory_placer_bottom_panel()
	pass


func _handles(object: Object) -> bool:
	if object is GridMapPlacer:
		return true
	else:
		return false


func _make_visible(visible: bool) -> void:
	if visible:
		if bottom_panel:
			bottom_panel.make_visible()
	else:
		if bottom_panel:
			bottom_panel.close()


func _create_placer_bottom_panel() -> void:
	bottom_panel = MINOS_BOTTOM_PANEL.instantiate()
	
	add_dock(bottom_panel)
	bottom_panel.close()


func _destory_placer_bottom_panel() -> void:
	if bottom_panel:
		remove_dock(bottom_panel)
		bottom_panel.queue_free()


func _create_save_dialog() -> void:
	save_dialog = EditorFileDialog.new()
	
	save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	
	save_dialog.add_filter("*.tres", "Godot Resourses")
	
	save_dialog.file_selected.connect(_save_file)
	EditorInterface.get_base_control().add_child(save_dialog)


func _destory_save_dialog() -> void:
	if save_dialog:
		save_dialog.queue_free()


func show_save_dialog() -> void:
	save_dialog.popup_centered_clamped(Vector2i(700,500))	


func _save_file(path: String) -> void:
	print("Dummy Save: " + path)


func _add_export_as_entry(menu: PopupMenu) -> void:
	menu_item_id = randi() % 10000
	var safety: int = 0
	while menu.get_item_index(menu_item_id) != -1 and safety < 30:
		menu_item_id = randi() % 10000
		safety += 1
	menu.add_item("Bake Csg Meshes",menu_item_id)
	# callable set here will be called when menu item is pressed, totally undocumented functionality
	menu.set_item_metadata(menu.get_item_index(menu_item_id),_run_bake_meshes)


func _remove_export_as_entry(menu: PopupMenu) -> void:
	var menu_item_index: int = menu.get_item_index(menu_item_id)
	menu.remove_item(menu_item_index)


func _run_bake_meshes(...args) -> void:
	_bake_meshes()


func _bake_meshes() -> void:
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	
	var csgs: Array = scene_root.find_children("*","CSGShape3D",false)
	
	for csg: CSGShape3D in csgs:
		var baked_mesh: ArrayMesh = csg.bake_static_mesh()
		
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.mesh = baked_mesh
		mesh_inst.name = csg.name.replace("CSG","")
		if scene_root.find_child(mesh_inst.name):
			var old_inst := scene_root.find_child(mesh_inst.name)
			old_inst.name = old_inst.name + "_old"
			old_inst.queue_free()
		scene_root.add_child(mesh_inst)
		mesh_inst.global_position = csg.global_position
		mesh_inst.owner = scene_root
		
		mesh_inst.create_trimesh_collision()
