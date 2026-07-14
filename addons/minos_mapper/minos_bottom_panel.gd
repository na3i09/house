@tool
extends EditorDock

@export var generation_segments: SpinBox

var show_save_dialog: Callable
var show_load_dialog: Callable


func _on_generate_button_pressed() -> void:
	var map_placer: GridMapPlacer = EditorInterface.get_inspector().get_edited_object() as GridMapPlacer
	if map_placer:
		map_placer._generate(int(generation_segments.value))


func _on_save_button_pressed() -> void:
	if show_save_dialog.is_valid():
		show_save_dialog.call()


func save_configuration(save_name: String) -> void:
	var map_placer: GridMapPlacer = EditorInterface.get_inspector().get_edited_object() as GridMapPlacer
	if map_placer:
		var map_config: GridMapConfiguration = map_placer.generate_configuration_resource()
		ResourceSaver.save(map_config,save_name)


func _on_load_button_pressed() -> void:
	if show_load_dialog.is_valid():
		show_load_dialog.call()


func load_configuration(load_path: String) -> void:
	var config_resource: GridMapConfiguration = load(load_path)
	var map_placer: GridMapPlacer = EditorInterface.get_inspector().get_edited_object() as GridMapPlacer
	if config_resource:
		map_placer.apply_map_configuration_resource(config_resource)
