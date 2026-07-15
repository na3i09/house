@tool
extends EditorDock

@export var generation_segments: SpinBox
@export var item_type_dropdown: OptionButton
@export var location_selection: HBoxContainer

var show_save_dialog: Callable
var show_load_dialog: Callable

var editor_selection: EditorSelection = null:
	set(value):
		if editor_selection:
			editor_selection.selection_changed.disconnect(_on_selection_changed)
		if value:
			value.selection_changed.connect(_on_selection_changed)
		
		editor_selection = value

var map_placer: MinosMap = null:
	set(value):
		item_type_dropdown.clear()
		if value:
			item_type_dropdown.generate_options(value._possible_items.keys())
		
		map_placer = value

func _on_generate_button_pressed() -> void:
	if map_placer:
		map_placer._generate(int(generation_segments.value))


func _on_save_button_pressed() -> void:
	if show_save_dialog.is_valid():
		show_save_dialog.call()


func save_configuration(save_name: String) -> void:
	if map_placer:
		var map_config: MinosMapConfiguration = map_placer.generate_configuration_resource()
		ResourceSaver.save(map_config,save_name)


func _on_load_button_pressed() -> void:
	if show_load_dialog.is_valid():
		show_load_dialog.call()


func load_configuration(load_path: String) -> void:
	var config_resource: MinosMapConfiguration = load(load_path)
	if config_resource:
		map_placer.apply_map_configuration_resource(config_resource)


func _on_selection_changed() -> void:
	var selected_nodes: Array[Node] = editor_selection.get_top_selected_nodes()
	
	if selected_nodes:
		map_placer = selected_nodes[0] as MinosMap
	else:
		map_placer = null


func _on_place_item_button_pressed() -> void:
	if map_placer:
		if item_type_dropdown.text:
			map_placer._instance_item_on_cell(item_type_dropdown.text,location_selection.get_location())
