@tool
extends EditorPlugin

var export_as_menu: PopupMenu = null

var menu_item_id: int = -1

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
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	_remove_export_as_entry(export_as_menu)
	pass


func _add_export_as_entry(menu: PopupMenu) -> void:
	menu_item_id = randi() % 10000
	var safety: int = 0
	while menu.get_item_index(menu_item_id) != -1 and safety < 30:
		menu_item_id = randi() % 10000
		safety += 1
	menu.add_item("Bake Csg Meshes",menu_item_id)
	menu.id_pressed.connect(_run_bake_meshes)


func _remove_export_as_entry(menu: PopupMenu) -> void:
	var menu_item_index: int = menu.get_item_index(menu_item_id)
	menu.remove_item(menu_item_index)
	menu.id_pressed.disconnect(_run_bake_meshes)


func _run_bake_meshes(id: int) -> void:
	if id == menu_item_id:
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
