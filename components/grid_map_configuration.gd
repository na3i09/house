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

static func generate_configuration_resource(configuration: Dictionary[Vector3i,Array], edge_id: int) -> GridMapConfiguration:
	var config_resource: GridMapConfiguration = GridMapConfiguration.new()
	
	config_resource.configuration_dict = configuration.duplicate()
	
	if edge_id != -1:
		for location in configuration.keys():
			if configuration[location][0] == edge_id:
				config_resource.edge_locations[location] = configuration[location][1]
				config_resource.configuration_dict.erase(location)
	
	#TODO: replace this with something less dumb
	for location in config_resource.configuration_dict:
		if location.x > config_resource.map_maximum.x:
			config_resource.map_maximum.x = location.x
		if location.y > config_resource.map_maximum.y:
			config_resource.map_maximum.y = location.y
		if location.z > config_resource.map_maximum.z:
			config_resource.map_maximum.z = location.z
		
		if location.x < config_resource.map_minimum.x:
			config_resource.map_minimum.x = location.x
		if location.y < config_resource.map_minimum.y:
			config_resource.map_minimum.y = location.y
		if location.z < config_resource.map_minimum.z:
			config_resource.map_minimum.z = location.z
	
	return config_resource
