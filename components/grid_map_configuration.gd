extends Resource
class_name GridMapConfiguration

@export_storage var configuration_dict: Dictionary[Vector3i,Array]

@export_storage var edge_locations: Dictionary[Vector3i,int]

@export_storage var map_minimum: Vector3i = Vector3i.ZERO

@export_storage var map_maximum: Vector3i = Vector3i.ZERO

var map_size: Vector3i:
	get:
		return map_maximum - map_minimum
	set(value):
		return

## Create a [GridMapConfiguration] based on the given [param configuration] with an optional [param edge_id]
## defining edges of the map segment to be used in map generation
static func generate_configuration_resource(configuration: Dictionary[Vector3i,Array], edge_id: int = -1) -> GridMapConfiguration:
	var config_resource: GridMapConfiguration = GridMapConfiguration.new()
	
	config_resource.configuration_dict = configuration.duplicate()
	
	if edge_id != -1:
		for location in configuration.keys():
			if configuration[location][0] == edge_id:
				config_resource.edge_locations[location] = configuration[location][1]
				config_resource.configuration_dict.erase(location)
	
	config_resource.map_maximum = config_resource.configuration_dict.keys().reduce(_max_vector)
	config_resource.map_minimum = config_resource.configuration_dict.keys().reduce(_min_vector)
	
	return config_resource

static func _max_vector(accum: Vector3i, element: Vector3i) -> Vector3i:
	if element.x > accum.x:
		accum.x = element.x
	if element.y > accum.y:
		accum.y = element.y
	if element.z > accum.z:
		accum.z = element.z
	
	return accum

static func _min_vector(accum: Vector3i, element: Vector3i) -> Vector3i:
	if element.x < accum.x:
		accum.x = element.x
	if element.y < accum.y:
		accum.y = element.y
	if element.z < accum.z:
		accum.z = element.z
	
	return accum
