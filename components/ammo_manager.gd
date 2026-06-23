extends Node
class_name AmmoManager

@export var weapon_list: Array[Node]

var ammo_list: Array[int]

func _ready() -> void:
	ammo_list.resize(weapon_list.size())
	for i in range(weapon_list.size()):
		if weapon_list[i].has_node_and_resource(":ammo_definition"):
			ammo_list[i] = weapon_list[i].ammo_definition.default_ammo
			
			weapon_list[i].get_ammo = get_current_ammo.bind(i)
			weapon_list[i].consume_ammo = attempt_consume_ammo.bind(i)
			print("success")


func get_current_ammo(index: int) -> int:
	return ammo_list[index]


func attempt_consume_ammo(value: int, index: int) -> bool:
	var current_ammo: int = ammo_list[index]
	
	if current_ammo >= value:
		_update_ammo_value.rpc_id(1,current_ammo - value,index)
		
		return true
	else:
		return false

@rpc("any_peer","reliable","call_local")
func _update_ammo_value(new_value: int,index: int) -> void:
	ammo_list[index] = new_value
