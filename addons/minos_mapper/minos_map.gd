@tool
extends GridMap
class_name MinosMap
## [GridMap] with support for placing packed scenes into locations on the grid map
##
## Replication of grid map item configuration is handled via multiplayer spawner synchronization, 
## while replication of tile configuration is handled via rpc call.

enum LoadFlags {
	NONE = 0,
	INCLUDE_EDGES = 1,
	ALL = INCLUDE_EDGES,
}

const REVERSED_ORIENTATION: int = 10

const RETRY_LIMIT: int = 4

## [Array] of randomly spawned item definitions
@export var random_items: Array[RandomItemSelection]

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

@export var possible_segments: Array[MinosMapConfiguration]

@export var minos_mesh_library: MinosMeshLibrary:
	get:
		return mesh_library
	set(value):
		mesh_library = value
		update_configuration_warnings()

@export_group("Settings")
@export var auto_generate: bool = false
@export_range(1,20,1,"or_greater") var auto_generation_segments: int = 1

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
	if property.name == "mesh_library":
		property.usage &= ~PROPERTY_USAGE_EDITOR

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if mesh_library is not MinosMeshLibrary:
		warnings.append("Using standard mesh libraries not fully supported, switch to a MinosMeshLibrary resource")
	
	return warnings

var _spawn_function: Callable = _spawn_item


## Generate [Dictionary] of instances of random items and their transforms from [member random_placer_dict]
func generate_random_item_configuration_dictionary() -> Dictionary[Vector3i,Array]:
	var item_dict: Dictionary[Vector3i,Array] = {}
	
	for random_item: RandomItemSelection in random_items:
		var location_array: Array[Vector3i] = get_used_cells_by_item(mesh_library.find_item_by_name(random_item.spawned_tile))
		for location: Vector3i in location_array:
			var item: Array = random_item.instance_item()
			if item:
				item_dict.get_or_add(location,[]).append_array(item)
	
	return item_dict


## Generate [Dictionary] representing a randomly assembled map made up of [MinosMapConfiguration] segments in [param segments]
func generate_map(segments: Array[MinosMapConfiguration], _max_instances: int, _origin: Vector3i = Vector3i(0,0,0)) -> Dictionary[Vector3i,Array]:
	var generated_map: Dictionary[Vector3i,Array] = {}
	
	var edge_pool: Dictionary[Vector3i,Array] = {}
	
	var first_segment: MinosMapConfiguration = segments.pick_random()
	generated_map.merge(first_segment.configuration_dict)
	
	edge_pool = first_segment.edge_locations.duplicate()
	
	var retries: int = 0
	
	for i in range(_max_instances - 1):
		var success: bool = _generate_segment(generated_map,edge_pool,segments)
		
		if not success:
			while retries < RETRY_LIMIT:
				retries += 1
				success = _generate_segment(generated_map,edge_pool,segments)
				if success:
					retries = 0
					break
			
			if retries >= RETRY_LIMIT:
				push_warning("failed to retry on iteration: " + str(i))
				break
	
	return generated_map

func _generate_segment(map: Dictionary[Vector3i,Array], edge_pool: Dictionary, segments: Array[MinosMapConfiguration]) -> bool:
	if edge_pool.is_empty():
		return false
	var source_edge: Vector3i = edge_pool.keys().pick_random()
	var source_edge_transform: Transform3D = _make_grid_transform(source_edge,edge_pool[source_edge][1])
	var new_segment: MinosMapConfiguration = segments.pick_random()
	
	var segment_edge: Vector3i = new_segment.edge_locations.keys().pick_random()
	var segment_edge_transform: Transform3D = _make_grid_transform(segment_edge,new_segment.edge_locations[segment_edge][1])
	
	var total_transform: Transform3D = _get_true_grid_transform(Transform3D.IDENTITY,source_edge_transform,segment_edge_transform)
	
	if _find_overlap_in_range(
		map,
		Vector3i(total_transform * Vector3(new_segment.map_minimum)),
		Vector3i(total_transform * Vector3(new_segment.map_maximum))
		):
		push_warning("Overlap")
		return false
	
	for loc in new_segment.configuration_dict:
		var true_tile_array: Array = _get_transformed_grid_loc_orient([loc,new_segment.configuration_dict[loc][1]],total_transform)
		if not map.has(true_tile_array[0]):
			var new_array: Array = new_segment.configuration_dict[loc].duplicate()
			new_array[1] = true_tile_array[1]
			map[true_tile_array[0]] = new_array
	
	for edge in new_segment.edge_locations:
		if edge == segment_edge:
			continue
		var true_edge_array: Array = _get_transformed_grid_loc_orient([edge,new_segment.edge_locations[edge][1]],total_transform)
		if not edge_pool.has(true_edge_array[0]):
			var true_edge_value_array: Array = new_segment.edge_locations[edge].duplicate()
			true_edge_value_array[1] = true_edge_array[1]
			edge_pool[true_edge_array[0]] = true_edge_value_array
	
	edge_pool.erase(source_edge)
	
	return true


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


## Generate [MinosMapConfiguration] resource using the current map configuration 
## and items from [member place_dict], [member location_place_dict], and items currently placed in the scene.
## The parameter [param make_reliable] saves the configuration in a more reliable, but larger and slower, format.
func generate_configuration_resource(make_reliable: bool = false) -> MinosMapConfiguration:
	var dict := generate_tile_configuration_dictionary(self)
	var item_dict := _serialize_items()
	for item_loc in item_dict:
		if dict.has(item_loc):
			dict[item_loc].append_array(item_dict[item_loc])
	return MinosMapConfiguration.generate_configuration_resource(
		dict,
		mesh_library,
		make_reliable
		)


## Apply configuration from [param config] to current map with optional [param offset] and optional [member LoadFlags]
func apply_map_configuration_resource(config: MinosMapConfiguration, offset: Vector3i = Vector3i(0,0,0), flags: LoadFlags = LoadFlags.NONE) -> void:
	var loaded_dict: Dictionary[Vector3i,Array] = config.configuration_dict
	if flags & LoadFlags.INCLUDE_EDGES:
		loaded_dict = config.configuration_dict.duplicate()
		for edge in config.edge_locations:
			var edge_id: int
			if mesh_library is MinosMeshLibrary:
				edge_id = mesh_library.edge_info.keys()[0]
			else:
				edge_id = mesh_library.find_item_by_name("Edge")
			loaded_dict[edge] = [edge_id,config.edge_locations[edge][1]]
	_apply_map_configuration(loaded_dict,offset)


# Creates and adds to tree all items in the [param items] array at thier specified offsets
func _instance_item_array(location: Vector3i, orientation: int, items: Array) -> void:
	assert(items.size() % 2 == 0, "Item array not made of item transform pairs")
	for i in range(0,items.size(),2):
		_instance_item_on_cell(items[i],location,orientation,items[i+1])


# Creates and adds to the tree the item given by [param item_name].
# Returns the spawned item added to the tree and with owner set to match the owner of the [MinosMap].
# Called only on the authority of the [MinosMap].
func _instance_item_on_cell(item_name: String, location: Vector3i, orientation: int = 0,offset_transform: Transform3D = Transform3D.IDENTITY) -> Node:
	var instance: Node = null
	var random_id: int = randi() #TODO: add collision guards to random id creation
	
	instance = _spawn_function.call([item_name,location,random_id,orientation,offset_transform])
	
	if not instance.is_inside_tree():
		add_child(instance)
	
	_post_spawn_item_processing(instance)
	
	return instance


# Called on server and clients to perform any spawned item processing after the node is added to the tree
func _post_spawn_item_processing(item: Node) -> void:
	if item:
		item.owner = owner


# Creates and returns the node for the given item
func _instantiate_item_at_cell_position(item_name: String, location: Vector3i, random_id: int, orientation: int = 0, offset_transform: Transform3D = Transform3D.IDENTITY) -> Node:
	var scene: PackedScene = _possible_items[item_name]
	assert(scene.can_instantiate())
	var inst_scene := scene.instantiate() as Node3D
	assert(inst_scene, "Scene to be instantiated was not derived from Node3D")
	_place_item_on_map(inst_scene,location,orientation,offset_transform)
	inst_scene.name = _name_item(item_name,random_id)
	
	inst_scene.add_to_group(name + "_items")
	
	inst_scene.set_meta("is_placer_item",true)
	
	return inst_scene


## Clear all cells and placed items
func clear_map() -> void:
	clear()
	var items: Array[Node] = get_tree().get_nodes_in_group(name + "_items")
	for item: Node in items:
		if item.has_meta("is_placer_item"):
			item.queue_free()


func generate(generation_segments: int = -1) -> void:
	clear_map()
	_apply_map_configuration(generate_map(possible_segments,generation_segments))


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


func _get_tile_id_from_id_or_name(value: Variant) -> int:
	assert(value is int or value is String, "Malformed argument")
	if value is int:
		return value
	elif value is String:
		var item_id: int = mesh_library.find_item_by_name(value)
		assert(item_id != -1)
		if item_id == -1:
			push_error("Could not find matching mesh library item for name: " + value)
		return item_id
	else:
		push_error("Malformed argument")
		return -1


# Apply map configuration defined in [param config] with optional [param offset]
func _apply_map_configuration(config: Dictionary[Vector3i,Array], offset: Vector3i = Vector3i(0,0,0)) -> void:
	for location: Vector3i in config:
		var tile_type: int = _get_tile_id_from_id_or_name(config[location][0])
		var tile_orientation: int = config[location][1]
		var items: Array = config[location].slice(2)
		
		var true_location: Vector3i = location + offset
		
		set_cell_item(true_location,tile_type,tile_orientation)
		
		_instance_item_array(true_location,tile_orientation,items)

func _spawn_item(args: Array) -> Node:
	assert(args is Array)
	assert(args.size() == 5)
	
	return _instantiate_item_at_cell_position.callv(args)


func _name_item(item_name: String, random_id: int) -> String:
	return item_name + "=" + str(random_id)


func _place_item_on_map(item: Node3D, location: Vector3i, orientation: int = 0, offset_transform: Transform3D = Transform3D.IDENTITY) -> void:
	item.transform = _create_local_item_transform(location,orientation,offset_transform)


func _create_local_item_transform(location: Vector3i, orientation: int, offset_transform: Transform3D = Transform3D.IDENTITY) -> Transform3D:
	var inst_location: Vector3 = map_to_local(location)
	inst_location.y += vertical_offset
	var item_transform: Transform3D = offset_transform
	item_transform.basis = get_basis_with_orthogonal_index(orientation) * item_transform.basis
	item_transform.origin += inst_location
	
	return item_transform
