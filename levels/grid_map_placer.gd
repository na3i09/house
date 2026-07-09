@tool
extends GridMap
class_name GridMapPlacer
## [GridMap] with support for placing packed scenes into locations on the grid map
##
## Replication of grid map item configuration is handled via multiplayer spawner synchronization, 
## while replication of tile configuration is handled via rpc call.

## [Dictionary] for scenes to be places onto all cells with matching grid map items
@export var place_dict: Dictionary[int,String]

## [Dictionary] for scenes to be placed randomly with a percentage chance onto matching grid map items
@export var random_place_dict: Dictionary[int,RandomItemSelection]

## [Dictionary] for scenes to be placed only on specified grid cell locations
@export var location_place_dict: Dictionary[Vector3i,String]

## Vertical offset for placing scenes onto grid map
@export var vertical_offset: float = 0.0

@export var possible_item_resource: ItemTable

var _possible_items: Dictionary[StringName,PackedScene]:
	get:
		if possible_item_resource:
			return possible_item_resource.table
		else:
			return {}
	set(value):
		pass

@export var possible_segments: Array[GridMapConfiguration]

@export_group("Developement Functions","dev")
@export_tool_button("Generate Map") var dev_map_gen: Callable = _generate
@export_range(1,20,1,"or_greater") var dev_segments: int = 4
@export_tool_button("Save Configuration") var dev_config_save: Callable = _dev_save_config_resource
@export_placeholder("Scene Name") var dev_config_save_name: String
@export_tool_button("Load Configuration") var dev_config_load: Callable = _dev_load_config_resource
@export_file("*.tres") var dev_loadable_config: String
@export_tool_button("Clear Current Configuration") var dev_clear_config: Callable = clear
@export_tool_button("Place Item") var dev_place_item: Callable = _dev_place_item_into_scene
@export var dev_item_name: String
@export var dev_item_location: Vector3i = Vector3i.ZERO


## Generate [Dictionary] of grid cell tiles and items from [member place_dict] and [member location_place_dict]
static func generate_static_configuration_dictionary(_placer: GridMapPlacer) -> Dictionary[Vector3i,Array]:
	var serialized_dict: Dictionary[Vector3i,Array] = generate_tile_configuration_dictionary(_placer)
	var item_dict: Dictionary[Vector3i,Array] = generate_item_configuration_dictionary(_placer)
	
	for location: Vector3i in item_dict:
		if serialized_dict.has(location):
			serialized_dict[location].append_array(item_dict[location])
	
	return serialized_dict


## Generate [Dictionary] of cell tile type and orientation
static func generate_tile_configuration_dictionary(_map: GridMap) -> Dictionary[Vector3i,Array]:
	var dict: Dictionary[Vector3i,Array]
	
	var tiles_used: Array[Vector3i] = _map.get_used_cells()
	
	for location: Vector3i in tiles_used:
		dict[location] = [_map.get_cell_item(location),_map.get_cell_item_orientation(location)]
	
	return dict


## Generate [Dictionary] of items and their offset transforms from [member place_dict] and [member location_place_dict]
static func generate_item_configuration_dictionary(_placer: GridMapPlacer) -> Dictionary[Vector3i,Array]:
	var item_dict: Dictionary[Vector3i,Array] = {}
	
	for index: int in _placer.place_dict:
		var instance_array: Array[Vector3i] = _placer.get_used_cells_by_item(index)
		for inst: Vector3i in instance_array:
			item_dict.get_or_add(inst,[]).append_array([_placer.place_dict[index],Transform3D.IDENTITY])
	
	for location: Vector3i in _placer.location_place_dict:
		item_dict.get_or_add(location,[]).append_array([_placer.location_place_dict[location],Transform3D.IDENTITY])
	
	return item_dict

## Generate [Dictionary] of instances of random items and their transforms from [member random_placer_dict]
static func generate_random_item_configuration_dictionary(_placer: GridMapPlacer) -> Dictionary[Vector3i,Array]:
	var item_dict: Dictionary[Vector3i,Array] = {}
	
	for index: int in _placer.random_place_dict:
			var instance_array: Array[Vector3i] = _placer.get_used_cells_by_item(index)
			for inst: Vector3i in instance_array:
				var random_scene: StringName = _placer.random_place_dict[index].pick_item()
				if random_scene:
					item_dict.get_or_add(inst,[]).append_array([random_scene,Transform3D.IDENTITY])
	
	return item_dict


## Generate [Dictionary] representing a randomly assembled map made up of [GridMapConfiguration] segments in [param segments]
static func generate_map(_placer: GridMap, segments: Array[GridMapConfiguration], _max_instances: int, origin: Vector3i = Vector3i(0,0,0)) -> Dictionary[Vector3i,Array]:
	var generated_map: Dictionary[Vector3i,Array] = {}
	
	var first_segment: GridMapConfiguration = segments.pick_random()
	generated_map.merge(first_segment.configuration_dict)
	
	var segment_edges: Dictionary[Vector3i,int] = first_segment.edge_locations
	
	for edge in segment_edges:
		var new_segment: GridMapConfiguration = segments.pick_random()
		
		var connecting_edge: Vector3i = new_segment.edge_locations.keys().pick_random()
		var edge_basis: Basis = _placer.get_basis_with_orthogonal_index(new_segment.edge_locations[connecting_edge])
		var edge_direction: Vector3i = Vector3i(edge_basis.z)
		for loc in new_segment.configuration_dict:
			var true_loc: Vector3i = loc - connecting_edge + origin# + edge_direction
			if not generated_map.has(true_loc):
				var tile_basis: Basis = _placer.get_basis_with_orthogonal_index(new_segment.configuration_dict[loc][1])
				var new_basis: Basis = edge_basis * tile_basis
				var new_array: Array = new_segment.configuration_dict[loc].duplicate()
				#new_array[1] = _placer.get_orthogonal_index_from_basis(new_basis)
				generated_map[true_loc] = new_array
	
	return generated_map


var spawner: MultiplayerSpawner
var is_multiplayer: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	spawner = find_child("MultiplayerSpawner")
	if spawner:
		spawner.spawn_function = _spawn_item
		is_multiplayer = true
	if is_multiplayer_authority():
		if possible_segments:
			_generate()
		
		var item_dict := GridMapPlacer.generate_item_configuration_dictionary(self)
		
		for location in item_dict:
			_instance_item_on_cell(item_dict[location][0],location)
		
		var random_item_dict := GridMapPlacer.generate_random_item_configuration_dictionary(self)
		
		for location in random_item_dict:
			_instance_item_on_cell(random_item_dict[location][0],location)
		
		print(_serialize_items())
	else:
		request_map_configuration.rpc_id(1)


## Generate [Dictionary] of map configuration using the current map configuration 
## and items currently placed in the scene
func generate_live_configuration_dictionary() -> Dictionary[Vector3i,Array]:
	var dict := generate_tile_configuration_dictionary(self)
	var item_dict := _serialize_items()
	
	for location: Vector3i in dict:
		if item_dict.has(location):
			dict[location].append_array(item_dict[location])
	
	return dict


## Generate [GridMapConfiguration] resource using the current map configuration 
## and items from [member place_dict], [member location_place_dict], and items currently placed in the scene
func generate_configuration_resource() -> GridMapConfiguration:
	var dict := GridMapPlacer.generate_static_configuration_dictionary(self)
	var item_dict := _serialize_items()
	for item_loc in item_dict:
		if dict.has(item_loc):
			dict[item_loc].append_array(item_dict[item_loc])
	return GridMapConfiguration.generate_configuration_resource(
		dict,
		mesh_library.find_item_by_name("Edge")
		)


## Apply configuration from [param config] to current map with optional [param offset]
func apply_map_configuration_resource(config: GridMapConfiguration, offset: Vector3i = Vector3i(0,0,0)) -> void:
	_apply_map_configuration(config.configuration_dict,offset)


func _instance_item_on_cell(item_name: String, location: Vector3i, orientation: int = 0) -> void:
	if is_multiplayer:
		spawner.spawn([item_name,location,orientation,Transform3D.IDENTITY])
	else:
		add_child(_instantiate_item_at_cell_position(item_name,location,orientation))

func _instantiate_item_at_cell_position(item_name: String, location: Vector3i, orientation: int = 0, offset_transform: Transform3D = Transform3D.IDENTITY) -> Node:
	var scene: PackedScene = _possible_items[item_name]
	assert(scene.can_instantiate())
	if find_child(str(location) + "*"):
		push_warning("Item overlap")
		return
	var inst_scene := scene.instantiate() as Node3D
	assert(inst_scene, "Scene to be instantiated was not derived from Node3D")
	_place_item_on_map(inst_scene,location,orientation,offset_transform)
	inst_scene.name = _name_item(item_name,location,inst_scene.transform)
	
	return inst_scene

func _dev_save_config_resource() -> void:
	var save_name: String
	if dev_config_save_name:
		save_name = owner.scene_file_path.get_base_dir().path_join(dev_config_save_name + ".tres")
	else:
		save_name = owner.scene_file_path.replace(".tscn",".tres")
	
	var map_config: GridMapConfiguration = generate_configuration_resource()
	ResourceSaver.save(map_config,save_name)


func _dev_load_config_resource() -> void:
	var config_resource: GridMapConfiguration = load(dev_loadable_config)
	if config_resource:
		apply_map_configuration_resource(config_resource)


func _dev_place_item_into_scene() -> void:
	if _possible_items.has(dev_item_name):
		var instanced_item: Node3D = _instantiate_item_at_cell_position(dev_item_name,dev_item_location)
		add_child(instanced_item)
		instanced_item.owner = owner
	else:
		print("invalid item name:" + dev_item_name)

func _generate() -> void:
	clear()
	_apply_map_configuration(generate_map(self,possible_segments,dev_segments))


func _serialize_items() -> Dictionary[Vector3i,Array]:
	var serialized_dict: Dictionary[Vector3i,Array]
	
	var children: Array[Node] = get_children()
	
	for child: Node in children:
		if child.name.begins_with("("):
			var info_array: Array = _get_grid_location_orientation_and_offset_from_node_transform(child.transform)
			var name_split: PackedStringArray = child.name.get_slice("=",0).split("_")
			
			serialized_dict.get_or_add(info_array[0],[]).append("_".join(name_split.slice(1)))
			serialized_dict[info_array[0]].append(info_array[2])
	return serialized_dict

func _get_grid_location_orientation_and_offset_from_node_transform(item_transform: Transform3D) -> Array:
	var grid_location: Vector3i = local_to_map(item_transform.origin)
	var grid_center_position: Vector3 = map_to_local(grid_location)
	var grid_item_orientation: int = get_cell_item_orientation(grid_location)
	var grid_item_basis: Basis = get_cell_item_basis(grid_location)
	
	var offset_transform := item_transform
	offset_transform.origin = offset_transform.origin - grid_center_position - Vector3(0,vertical_offset,0)
	offset_transform.basis = grid_item_basis.inverse() * offset_transform.basis
	
	return [grid_location,grid_item_orientation,offset_transform]

func _apply_map_configuration(config: Dictionary[Vector3i,Array], offset: Vector3i = Vector3i(0,0,0)) -> void:
	for location: Vector3i in config:
		var tile_type: int = config[location][0]
		var tile_orientation: int = config[location][1]
		var items: Array = config[location].slice(2)
		
		var true_location: Vector3i = location + offset
		
		set_cell_item(true_location,tile_type,tile_orientation)
		
		for item: String in items:
			_instance_item_on_cell(item,true_location,tile_orientation) #TODO: ensure this will actually work from serializing key index position

func _spawn_item(args: Array) -> Node:
	assert(args is Array)
	assert(args.size() == 4)
	
	return _instantiate_item_at_cell_position.callv(args)


func _name_item(item_name: String, location: Vector3i, item_transform: Transform3D) -> String:
	return str(location) + "_" + item_name + "=" + str(hash(item_transform))


func _place_item_on_map(item: Node3D, location: Vector3i, orientation: int = 0, offset_transform: Transform3D = Transform3D.IDENTITY) -> void:
	item.transform = _create_local_item_transform(location,orientation,offset_transform)

func _create_local_item_transform(location: Vector3i, orientation: int, offset_transform: Transform3D = Transform3D.IDENTITY) -> Transform3D:
	var inst_location: Vector3 = map_to_local(location)
	inst_location.y += vertical_offset
	var item_transform: Transform3D = offset_transform
	item_transform.basis = get_basis_with_orthogonal_index(orientation) * item_transform.basis
	item_transform.origin += inst_location
	
	return item_transform

@rpc("any_peer","reliable","call_remote")
func request_map_configuration() -> void:
	_recieve_map_configuration.rpc_id(multiplayer.get_remote_sender_id(),generate_tile_configuration_dictionary(self))


@rpc("authority","reliable","call_remote")
func _recieve_map_configuration(configuration: Dictionary[Vector3i,Array]) -> void:
	_apply_map_configuration(configuration)
