extends Resource
class_name RandomItemSelection
## Resource defining parameters for a randomly spawned item,
## defining what tile the item can spawn on, its chance to spawn, and its range of offset transform.


## Name of the spawned item
@export var spawned_item: StringName
## Name of the tile type to spawn item on
@export var spawned_tile: StringName
## Chance for item to spawn
@export var spawn_chance: float = 0.2

## Minimum rotational offset for spawned item
@export_range(-180,0,0.1,"radians_as_degrees") var min_rotation: float = deg_to_rad(0.0)
## Maximum rotational offset for spawned item
@export_range(0,180,0.1,"radians_as_degrees") var max_rotation: float = deg_to_rad(0.0)
## Axis of rotation for rotational offset
@export var rotation_axis: Vector3 = Vector3.UP

## Minimum location offset for spawned item
@export var min_location_offset: Vector3 = Vector3.ZERO
## Maximum location offset for spawned item
@export var max_location_offset: Vector3 = Vector3.ZERO

## Create an instance of the random item returning an item transform pair
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
