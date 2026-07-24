shader_type canvas_item;
render_mode unshaded;

uniform vec4 light_color : source_color = vec4(1.0, 1.0, 0.8, 0.6);
uniform float falloff : hint_range(0.1, 5.0) = 2.0;
uniform float spread : hint_range(0.1, 2.0) = 1.0;

void fragment() {
	// UV.y este distanța de sus în jos (0 la 1)
	// UV.x este distanța de la stânga la dreapta (0 la 1)
	
	float vertical_fade = pow(1.0 - UV.y, falloff);
	
	// Facem lumina să fie mai lată la bază și mai îngustă sus, sau invers
	float horizontal_center = abs(UV.x - 0.5) * 2.0;
	float horizontal_fade = smoothstep(spread, 0.0, horizontal_center);
	
	float final_mask = vertical_fade * horizontal_fade;
	
	COLOR = vec4(light_color.rgb, final_mask * light_color.a);
}
