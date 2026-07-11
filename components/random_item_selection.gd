extends Resource
class_name RandomItemSelection
## Resource defining parameters for a randomly spawned item,
## defining what tile the item can spawn on, its chance to spawn, and its range of offset transform.


@export var spawned_item: StringName
@export var spawned_tile: StringName
@export var spawn_chance: float = 0.2

@export var min_rotation: float = deg_to_rad(0.0)
@export var max_rotation: float = deg_to_rad(0.0)
@export var rotation_axis: Vector3 = Vector3.UP

@export var min_location_offset: Vector3 = Vector3.ZERO
@export var max_location_offset: Vector3 = Vector3.ZERO

func instance_item() -> Array:
	if randf() > spawn_chance:
		return []
	
	var item_transform: Transform3D
	
	item_transform.origin += Vector3(
		randf_range(min_location_offset.x,max_location_offset.x),
		randf_range(min_location_offset.y,max_location_offset.y),
		randf_range(min_location_offset.z,max_location_offset.z)
	)
	
	item_transform = item_transform.rotated(rotation_axis,randf_range(min_rotation,max_rotation))
	
	return [spawned_item,item_transform]
