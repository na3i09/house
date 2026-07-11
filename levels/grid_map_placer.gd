@tool
extends GridMap
class_name GridMapPlacer
## [GridMap] with support for placing packed scenes into locations on the grid map
##
## Replication of grid map item configuration is handled via multiplayer spawner synchronization, 
## while replication of tile configuration is handled via rpc call.

const REVERSED_ORIENTATION: int = 10

## [Dictionary] for scenes to be places onto all cells with matching grid map items
@export var place_dict: Dictionary[int,String]

## [Dictionary] for scenes to be placed randomly with a percentage chance onto matching grid map items
@export var random_place_dict: Dictionary[int,RandomItemSelection]

## [Dictionary] for scenes to be placed only on specified grid cell locations
@export var location_place_dict: Dictionary[Vector3i,String]

## Vertical offset for placing scenes onto grid map
@export var vertical_offset: float = 0.0

@export var possible_item_resource: ItemTable:
	set(value):
		possible_item_resource = value
		notify_property_list_changed()

var _possible_items: Dictionary[StringName,PackedScene]:
	get:
		if possible_item_resource:
			return possible_item_resource.table
		else:
			return {}
	set(value):
		pass

@export var possible_segments: Array[GridMapConfiguration]

#region dev_exports
@export_group("Developement Functions","dev")
@export_tool_button("Generate Map") var dev_map_gen: Callable = _generate
@export_range(1,20,1,"or_greater") var dev_segments: int = 4
@export_tool_button("Save Configuration") var dev_config_save: Callable = _dev_save_config_resource
@export_placeholder("Scene Name") var dev_config_save_name: String
@export_tool_button("Load Configuration") var dev_config_load: Callable = _dev_load_config_resource
@export_file("*.tres") var dev_loadable_config: String
@export_tool_button("Clear Current Configuration") var dev_clear_config: Callable = _dev_clear_map
@export_tool_button("Place Item") var dev_place_item: Callable = _dev_place_item_into_scene
#WARNING: dropdown list of item names does not update unless the possible_items_resource is unset and reset
@export var dev_item_name: String
@export var dev_item_location: Vector3i = Vector3i.ZERO
#endregion

# hard grab reversed basis for mirroring the connecting edge
var _reversed_transform := Transform3D(get_basis_with_orthogonal_index(REVERSED_ORIENTATION))

## Generate [Dictionary] of cell tile type and orientation
static func generate_tile_configuration_dictionary(map: GridMap) -> Dictionary[Vector3i,Array]:
	var dict: Dictionary[Vector3i,Array]
	
	var tiles_used: Array[Vector3i] = map.get_used_cells()
	
	for location: Vector3i in tiles_used:
		dict[location] = [map.get_cell_item(location),map.get_cell_item_orientation(location)]
	
	return dict

func _validate_property(property: Dictionary) -> void:
	if property.name == "dev_item_name" && possible_item_resource:
		property.hint = PROPERTY_HINT_ENUM_SUGGESTION
		property.hint_string = ",".join(_possible_items.keys())

var _spawner: MultiplayerSpawner
var _is_multiplayer: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if multiplayer.has_multiplayer_peer():
		_initialize_multiplayer_support()
	
	if is_multiplayer_authority():
		if possible_segments:
			_dev_clear_map()
			_generate()
		
		var item_dict := generate_item_configuration_dictionary()
		
		for location in item_dict:
			_instance_item_on_cell(item_dict[location][0],location)
		
		var random_item_dict := generate_random_item_configuration_dictionary()
		
		for location in random_item_dict:
			_instance_item_on_cell(random_item_dict[location][0],location)
		
		# ensure there is a spawn point on the map
		if find_children("spawn_point*").is_empty():
			var floors: Array = get_used_cells_by_item(mesh_library.find_item_by_name("Floor"))
			
			if not floors.is_empty():
				_instance_item_on_cell("spawn_point",floors.pick_random())
			else:
				_instance_item_on_cell("spawn_point",get_used_cells().pick_random())
		
		print(_serialize_items())
	else:
		_request_map_configuration.rpc_id(1)


## Generate [Dictionary] of grid cell tiles and items from [member place_dict] and [member location_place_dict]
func generate_static_configuration_dictionary() -> Dictionary[Vector3i,Array]:
	var serialized_dict: Dictionary[Vector3i,Array] = generate_tile_configuration_dictionary(self)
	var item_dict: Dictionary[Vector3i,Array] = generate_item_configuration_dictionary()
	
	for location: Vector3i in item_dict:
		if serialized_dict.has(location):
			serialized_dict[location].append_array(item_dict[location])
	
	return serialized_dict


## Generate [Dictionary] of items and their offset transforms from [member place_dict] and [member location_place_dict]
func generate_item_configuration_dictionary() -> Dictionary[Vector3i,Array]:
	var item_dict: Dictionary[Vector3i,Array] = {}
	
	for index: int in place_dict:
		var instance_array: Array[Vector3i] = get_used_cells_by_item(index)
		for inst: Vector3i in instance_array:
			item_dict.get_or_add(inst,[]).append_array([place_dict[index],Transform3D.IDENTITY])
	
	for location: Vector3i in location_place_dict:
		item_dict.get_or_add(location,[]).append_array([location_place_dict[location],Transform3D.IDENTITY])
	
	return item_dict


## Generate [Dictionary] of instances of random items and their transforms from [member random_placer_dict]
func generate_random_item_configuration_dictionary() -> Dictionary[Vector3i,Array]:
	var item_dict: Dictionary[Vector3i,Array] = {}
	
	for index: int in random_place_dict:
			var instance_array: Array[Vector3i] = get_used_cells_by_item(index)
			for inst: Vector3i in instance_array:
				var random_scene: StringName = random_place_dict[index].pick_item()
				if random_scene:
					item_dict.get_or_add(inst,[]).append_array([random_scene,Transform3D.IDENTITY])
	
	return item_dict


## Generate [Dictionary] representing a randomly assembled map made up of [GridMapConfiguration] segments in [param segments]
func generate_map(segments: Array[GridMapConfiguration], _max_instances: int, _origin: Vector3i = Vector3i(0,0,0)) -> Dictionary[Vector3i,Array]:
	var generated_map: Dictionary[Vector3i,Array] = {}
	
	var edge_pool: Dictionary[Vector3i,int] = {}
	
	var first_segment: GridMapConfiguration = segments.pick_random()
	generated_map.merge(first_segment.configuration_dict)
	
	edge_pool = first_segment.edge_locations.duplicate()
	
	for i in range(_max_instances - 1):
		if edge_pool.is_empty():
			break
		var source_edge: Vector3i = edge_pool.keys().pick_random()
		var source_edge_transform: Transform3D = _make_grid_transform(source_edge,edge_pool[source_edge])
		var new_segment: GridMapConfiguration = segments.pick_random()
		
		var segment_edge: Vector3i = new_segment.edge_locations.keys().pick_random()
		var segment_edge_transform: Transform3D = _make_grid_transform(segment_edge,new_segment.edge_locations[segment_edge])
		
		var total_transform: Transform3D = _get_true_grid_transform(Transform3D.IDENTITY,source_edge_transform,segment_edge_transform)
		
		if _find_overlap_in_range(
			generated_map,
			Vector3i(total_transform * Vector3(new_segment.map_minimum)),
			Vector3i(total_transform * Vector3(new_segment.map_maximum))
			):
			print("overlap at " + str(i) + " iterations")
			break
		
		for loc in new_segment.configuration_dict:
			var true_tile_array: Array = _get_transformed_grid_loc_orient([loc,new_segment.configuration_dict[loc][1]],total_transform)
			if not generated_map.has(true_tile_array[0]):
				var new_array: Array = new_segment.configuration_dict[loc].duplicate()
				new_array[1] = true_tile_array[1]
				generated_map[true_tile_array[0]] = new_array
		
		for edge in new_segment.edge_locations:
			if edge == segment_edge:
				continue
			var true_edge_array: Array = _get_transformed_grid_loc_orient([edge,new_segment.edge_locations[edge]],total_transform)
			if not edge_pool.has(true_edge_array[0]):
				edge_pool[true_edge_array[0]] = true_edge_array[1]
		
		edge_pool.erase(source_edge)
	
	return generated_map


func _get_transformed_grid_loc_orient(loc_and_orient: Array, _transform: Transform3D) -> Array:
	var tile_transform: Transform3D = _make_grid_transform.callv(loc_and_orient)
	var true_transform: Transform3D = _transform * tile_transform
	
	return [Vector3i(true_transform.origin),get_orthogonal_index_from_basis(true_transform.basis)]


func _find_overlap_in_range(_map: Dictionary[Vector3i,Array],segment_min: Vector3i,segment_max: Vector3i) -> bool:
	for x: int in range(segment_min.x,segment_max.x+1):
		for y: int in range(segment_min.y,segment_max.y+1):
			for z: int in range(segment_min.z,segment_max.z+1):
				if _map.has(Vector3i(x,y,z)):
					return true
	
	return false


func _make_grid_transform(location: Vector3i, orientation: int) -> Transform3D:
	var _basis: Basis = get_basis_with_orthogonal_index(orientation)
	
	return Transform3D(_basis,location)


func _get_true_grid_transform(tile_transform: Transform3D, source_edge_transform: Transform3D, segment_edge_transform: Transform3D) -> Transform3D:
	var true_transform: Transform3D = source_edge_transform * _reversed_transform * segment_edge_transform.inverse() * tile_transform
	true_transform.origin -= source_edge_transform.basis.z
	
	return true_transform


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
	var dict := generate_static_configuration_dictionary()
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


# Creates and adds to the tree the item given by [param item_name]
func _instance_item_on_cell(item_name: String, location: Vector3i, orientation: int = 0,offset_transform: Transform3D = Transform3D.IDENTITY) -> void:
	var instance: Node = null
	if _is_multiplayer:
		instance = _spawner.spawn([item_name,location,orientation,offset_transform])
	else:
		instance = _instantiate_item_at_cell_position(item_name,location,orientation,offset_transform)
		add_child(instance)
	
	_post_spawn_item_processing(instance)


# Called on server and clients to perform any spawned item processing after the node is added to the tree
func _post_spawn_item_processing(item: Node) -> void:
	if item:
		item.owner = owner


# Creates and returns the node for the given item
func _instantiate_item_at_cell_position(item_name: String, location: Vector3i, orientation: int = 0, offset_transform: Transform3D = Transform3D.IDENTITY) -> Node:
	var scene: PackedScene = _possible_items[item_name]
	assert(scene.can_instantiate())
	var inst_scene := scene.instantiate() as Node3D
	assert(inst_scene, "Scene to be instantiated was not derived from Node3D")
	_place_item_on_map(inst_scene,location,orientation,offset_transform)
	inst_scene.name = _name_item(item_name)
	
	inst_scene.add_to_group(name + "_items")
	
	inst_scene.set_meta("is_placer_item",true)
	
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


func _dev_clear_map() -> void:
	clear()
	var items: Array[Node] = get_tree().get_nodes_in_group(name + "_items")
	for item: Node in items:
		if item.has_meta("is_placer_item"):
			item.queue_free()


func _generate() -> void:
	_dev_clear_map()
	_apply_map_configuration(generate_map(possible_segments,dev_segments))


# Serailize item children into a configuration dictionary
func _serialize_items() -> Dictionary[Vector3i,Array]:
	var serialized_dict: Dictionary[Vector3i,Array]
	
	var children: Array[Node] = get_children()
	
	for child: Node in children:
		if child.has_meta("is_placer_item"):
			var info_array: Array = _get_grid_location_orientation_and_offset_from_node_transform(child.transform)
			
			var item_name: String = child.name.get_slice("=",0)
			
			serialized_dict.get_or_add(info_array[0],[]).append(item_name)
			serialized_dict[info_array[0]].append(info_array[2])
	return serialized_dict


# convert a local node transform into a grid location, orientation, and offset transform for serailization
func _get_grid_location_orientation_and_offset_from_node_transform(item_transform: Transform3D) -> Array:
	var grid_location: Vector3i = local_to_map(item_transform.origin)
	var grid_center_position: Vector3 = map_to_local(grid_location)
	var grid_item_orientation: int = get_cell_item_orientation(grid_location)
	var grid_item_basis: Basis = get_cell_item_basis(grid_location)
	
	var offset_transform := item_transform
	offset_transform.origin = offset_transform.origin - grid_center_position - Vector3(0,vertical_offset,0)
	offset_transform.basis = grid_item_basis.inverse() * offset_transform.basis
	
	return [grid_location,grid_item_orientation,offset_transform]


# Apply map configuration defined in [param config] with optional [param offset]
func _apply_map_configuration(config: Dictionary[Vector3i,Array], offset: Vector3i = Vector3i(0,0,0)) -> void:
	for location: Vector3i in config:
		var tile_type: int = config[location][0]
		var tile_orientation: int = config[location][1]
		var items: Array = config[location].slice(2)
		
		var true_location: Vector3i = location + offset
		
		set_cell_item(true_location,tile_type,tile_orientation)
		
		assert(items.size() % 2 == 0, "Item array not made of item transform pairs")
		for i in range(0,items.size(),2):
			_instance_item_on_cell(items[i],true_location,tile_orientation,items[i+1]) #TODO: ensure this will actually work from serializing key index position

func _spawn_item(args: Array) -> Node:
	assert(args is Array)
	assert(args.size() == 4)
	
	return _instantiate_item_at_cell_position.callv(args)


func _name_item(item_name: String) -> String:
	return item_name + "=" + str(randi())


func _place_item_on_map(item: Node3D, location: Vector3i, orientation: int = 0, offset_transform: Transform3D = Transform3D.IDENTITY) -> void:
	item.transform = _create_local_item_transform(location,orientation,offset_transform)


func _create_local_item_transform(location: Vector3i, orientation: int, offset_transform: Transform3D = Transform3D.IDENTITY) -> Transform3D:
	var inst_location: Vector3 = map_to_local(location)
	inst_location.y += vertical_offset
	var item_transform: Transform3D = offset_transform
	item_transform.basis = get_basis_with_orthogonal_index(orientation) * item_transform.basis
	item_transform.origin += inst_location
	
	return item_transform


func _initialize_multiplayer_support() -> void:
	_spawner = _create_multiplayer_spawner()
	if _spawner:
		_spawner.spawn_function = _spawn_item
		_spawner.spawned.connect(_post_spawn_item_processing)
		_is_multiplayer = true


func _create_multiplayer_spawner() -> MultiplayerSpawner:
	var spawner := MultiplayerSpawner.new()
	
	spawner.spawn_path = ^".."
	spawner.name = "PlacerSpawner"
	add_child(spawner)
	
	return spawner


@rpc("any_peer","reliable","call_remote")
func _request_map_configuration() -> void:
	_recieve_map_configuration.rpc_id(multiplayer.get_remote_sender_id(),generate_tile_configuration_dictionary(self))


@rpc("authority","reliable","call_remote")
func _recieve_map_configuration(configuration: Dictionary[Vector3i,Array]) -> void:
	_apply_map_configuration(configuration)
