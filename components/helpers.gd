extends Object
class_name Helpers


static func string_to_vector3i(string: String) -> Vector3i:
	var vector_string: String = string.remove_chars("()")
	var vector_elements: PackedStringArray = vector_string.split(",")
	var vector: Vector3i = Vector3i(vector_elements[0].to_int(),vector_elements[1].to_int(),vector_elements[2].to_int())
	
	return vector
