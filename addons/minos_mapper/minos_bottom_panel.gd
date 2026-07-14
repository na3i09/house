@tool
extends EditorDock


func _on_generate_button_pressed() -> void:
	var map_placer: GridMapPlacer = EditorInterface.get_inspector().get_edited_object() as GridMapPlacer
	if map_placer:
		map_placer._generate()
