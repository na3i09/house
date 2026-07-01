extends Marker3D
class_name SpawnPoint
## Marker for possible spawn point for players

const GROUP_NAME: StringName = &"SpawnPoints"

## Picks a random spawn point from all available spawn points
static func pick_random_spawn_point(active_tree: SceneTree) -> SpawnPoint:
	var all_points: Array = active_tree.get_nodes_in_group(GROUP_NAME)
	
	if all_points.is_empty():
		return null
	
	return all_points.get(randi_range(0,all_points.size() - 1))

func _ready() -> void:
	add_to_group(GROUP_NAME)
