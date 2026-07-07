extends Resource
class_name GridMapConfiguration

@export_storage var configuration_dict: Dictionary[Vector3i,Array]

@export_storage var edge_locations: Dictionary[Vector3i,int]


static func generate_configuration_resource(configuration: Dictionary[Vector3i,Array], edge_id: int) -> GridMapConfiguration:
	var config_resource: GridMapConfiguration = GridMapConfiguration.new()
	
	config_resource.configuration_dict = configuration.duplicate()
	
	if edge_id != -1:
		for location in configuration.keys():
			if configuration[location][0] == edge_id:
				config_resource.edge_locations[location] = configuration[location][1]
				config_resource.configuration_dict.erase(location)
		
	return config_resource
