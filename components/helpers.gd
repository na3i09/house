extends Object
class_name Helpers


static func string_to_vector3i(string: String) -> Vector3i:
	var vector_string: String = string.remove_chars("()")
	var vector_elements: PackedStringArray = vector_string.split(",")
	var vector: Vector3i = Vector3i(vector_elements[0].to_int(),vector_elements[1].to_int(),vector_elements[2].to_int())
	
	return vector


static func create_internal_timer(parent: Node, wait_time: float = 1.0, one_shot: bool = true, timeout_connections: Array[Callable] = []) -> Timer:
	var _timer: Timer = Timer.new()
	
	_timer.wait_time = wait_time
	_timer.one_shot = one_shot
	parent.add_child(_timer)
	
	for connection in timeout_connections:
		_timer.timeout.connect(connection)
	
	return _timer
