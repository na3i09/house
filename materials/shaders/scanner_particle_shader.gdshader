shader_type spatial;
render_mode unshaded,blend_add,depth_draw_never,fog_disabled,shadows_disabled,diffuse_toon,specular_disabled;

global uniform vec3 player_position;

#include "world_aware.gdshaderinc"

uniform sampler2D color_gradient;
uniform float max_range = 40.0;

varying vec3 world_coords;

void vertex() {
	world_coords = get_coords(MODEL_MATRIX,VERTEX);
}

void fragment() {
	float player_dist = distance(world_coords,player_position);
	float dist_ratio = player_dist / max_range;
	
	ALBEDO = texture(color_gradient,vec2(dist_ratio,0.5)).rgb;
	//ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
