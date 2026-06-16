extends Node
class_name HealthManager

signal health_changed(new_value: float)
signal health_depleated

@export var max_health: float = 100.0


@onready var health: float = max_health:
	get:
		return health
	set(value):
		if value == health:
			return
		health = clampf(value,0.0,max_health)
		if value <= 0.0:
			health_depleated.emit()
		health_changed.emit(health)
