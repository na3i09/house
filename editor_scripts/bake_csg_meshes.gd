@tool
extends EditorScript
class_name BakeCSGMeshes

func _run() -> void:
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
