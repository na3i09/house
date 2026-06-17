shader_type spatial;
render_mode unshaded,fog_disabled,blend_add;

uniform sampler2D depth_texture : hint_depth_texture;

uniform float divisor = 0.2;
uniform float size = 0.2;

instance uniform float max_dist = 15.0;
instance uniform float opacity = 1.0;
instance uniform float min_dist = 0.0;
instance uniform vec3 origin_point = vec3(0.0);

uniform vec4 ping_color : source_color;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	//vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	//view.xyz /= view.w;
	//float linear_depth = -view.z;

	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;

	// Visualize linear depth
	//ALBEDO.rgb = vec3(fract(linear_depth));
	
	float dist_from_orig = distance(world_position,origin_point);
	if (dist_from_orig > max_dist || dist_from_orig < min_dist) {
		discard;
	}
	
	// Visualize world coordinates
	float up_bound = (0.5 + (size/2.0)) * divisor;
	float low_bound = (0.5 - (size/2.0)) * divisor;
	vec3 world_fract = mod(fract(world_position).xyz,divisor);
	if (all(greaterThanEqual(world_fract,vec3(low_bound))) && all(lessThanEqual(world_fract,vec3(up_bound)))) {
		ALPHA = 0.7 * opacity;
		ALBEDO.rgb = ping_color.rgb;
	} else {
		discard;
	}
}
