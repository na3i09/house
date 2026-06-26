extends Node
class_name AmmoManager

@export var weapon_list: Array[Node]

@export var detection_area: Area3D

var ammo_list: Array[int]

func _ready() -> void:
	if is_multiplayer_authority():
		detection_area.area_entered.connect(_on_detection_area_entered)
	ammo_list.resize(weapon_list.size())
	for i in range(weapon_list.size()):
		if weapon_list[i].has_node_and_resource(":ammo_type"):
			ammo_list[i] = weapon_list[i].ammo_type.default_ammo
			
			weapon_list[i].get_ammo = get_current_ammo.bind(i)
			weapon_list[i].consume_ammo = attempt_consume_ammo.bind(i)
			weapon_list[i].reload_ammo = reload_ammo.bind(i)


func get_current_ammo(index: int) -> int:
	return ammo_list[index]

func set_current_ammo(value: int, index: int) -> void:
	if is_multiplayer_authority():
		ammo_list[index] = value

func attempt_consume_ammo(value: int, index: int) -> bool:
	var current_ammo: int = ammo_list[index]
	
	if current_ammo >= value:
		_update_ammo_value.rpc_id(1,current_ammo - value,index)
		
		return true
	else:
		return false

## Remove ammo from pool, either full requested value, or all ammo remainging in pool
func reload_ammo(value: int, index: int) -> int:
	var remaining_ammo: int = mini(value,ammo_list[index])
	attempt_consume_ammo(remaining_ammo,index)
	return remaining_ammo

@rpc("any_peer","reliable","call_local")
func _update_ammo_value(new_value: int,index: int) -> void:
	ammo_list[index] = new_value

func _on_detection_area_entered(area: Area3D) -> void:
	var area_owner: Node3D = area.owner
	
	ammo_list[area_owner.weapon_index] += area_owner.amount
	area_owner.pickup_ammo()
