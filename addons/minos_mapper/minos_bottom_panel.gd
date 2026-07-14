@tool
extends EditorDock

@export var generation_segments: SpinBox

var save_dialog: EditorFileDialog = null


func _on_generate_button_pressed() -> void:
	var map_placer: GridMapPlacer = EditorInterface.get_inspector().get_edited_object() as GridMapPlacer
	if map_placer:
		map_placer._generate(int(generation_segments.value))


func _on_save_button_pressed() -> void:
	save_dialog.popup_centered_clamped(Vector2i(700,500))
	pass


func save_configuration(save_name: String) -> void:
	var map_placer: GridMapPlacer = EditorInterface.get_inspector().get_edited_object() as GridMapPlacer
	if map_placer:
		var map_config: GridMapConfiguration = map_placer.generate_configuration_resource()
		ResourceSaver.save(map_config,save_name)
