#ifndef WORLD_AWARE
#define WORLD_AWARE

vec3 get_coords(mat4 matrix, vec3 vert) {
	return (matrix * vec4(vert, 1.0)).xyz;
}

#endif //WORLD_AWARE