@tool
extends EditorDock

@export var generation_segments: SpinBox
@export var item_type_dropdown: OptionButton
@export var location_selection: HBoxContainer
@export var reliable: CheckBox
@export var load_edges: CheckBox


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
		map_placer.generate(int(generation_segments.value))
		EditorInterface.mark_scene_as_unsaved()


func _on_save_button_pressed() -> void:
	if show_save_dialog.is_valid():
		show_save_dialog.call()


func save_configuration(save_name: String) -> void:
	if map_placer:
		var map_config: MinosMapConfiguration = map_placer.generate_configuration_resource(reliable.button_pressed)
		ResourceSaver.save(map_config,save_name)


func _on_load_button_pressed() -> void:
	if show_load_dialog.is_valid():
		show_load_dialog.call()


func load_configuration(load_path: String) -> void:
	var config_resource: MinosMapConfiguration = load(load_path)
	if config_resource:
		var load_flags: MinosMap.LoadFlags = MinosMap.LoadFlags.NONE
		if load_edges.button_pressed:
			load_flags |= MinosMap.LoadFlags.INCLUDE_EDGES
		map_placer.apply_map_configuration_resource(config_resource,Vector3i.ZERO,load_flags)
		EditorInterface.mark_scene_as_unsaved()


func _on_selection_changed() -> void:
	var selected_nodes: Array[Node] = editor_selection.get_top_selected_nodes()
	
	if selected_nodes:
		map_placer = selected_nodes[0] as MinosMap
	else:
		map_placer = null


func _on_place_item_button_pressed() -> void:
	var editor_root: Node = EditorInterface.get_resource_filesystem().get_node("/root")
	var grid_map_plugin: GridMapEditorPlugin = editor_root.find_children("*","GridMapEditorPlugin",true,false).get(0)
	var selection_location: Vector3i = location_selection.get_location()
	if grid_map_plugin:
		if grid_map_plugin.has_selection():
			selection_location = grid_map_plugin.get_selected_cells().get(0)
	if map_placer:
		if item_type_dropdown.text:
			map_placer._instance_item_on_cell(item_type_dropdown.text,selection_location)
			EditorInterface.mark_scene_as_unsaved()


func _on_clear_button_pressed() -> void:
	if map_placer:
		if map_placer.get_used_cells():
			map_placer._dev_clear_map()
			EditorInterface.mark_scene_as_unsaved()
