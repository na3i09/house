shader_type spatial;
render_mode unshaded,blend_add;

uniform vec4 albedo_color : source_color;
uniform float power = 5.0;
instance uniform float opacity = 1.0;

void fragment() {
	ALBEDO = albedo_color.rgb * power;
	ALPHA = opacity;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
