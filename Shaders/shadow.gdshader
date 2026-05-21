shader_type canvas_item;

uniform float sun_angle : hint_range(0.0, 6.28318) = 1.57; 
uniform float sun_elevation : hint_range(0.1, 1.5) = 0.5;
uniform float shadow_length_modifier : hint_range(0.0, 3.0) = 1.0;

// Cât de scurtă să fie umbra la punctul maxim din spate (ex: 0.5 = jumătate)
uniform float back_shadow_scale : hint_range(0.1, 1.0) = 0.6;

uniform float shadow_opacity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float pivot_offset : hint_range(0.0, 1.0) = 0.95; 

void vertex() {
	float shadow_length = (1.0 / tan(max(sun_elevation, 0.1))) * shadow_length_modifier;
	
	// Direcția brută
	vec2 dir = vec2(cos(sun_angle), sin(sun_angle)) * shadow_length;
	
	// --- LOGICA DE TRANZIȚIE FLUIDĂ ---
	// sin(sun_angle) este -1.0 când umbra e maxim în spate (sus)
	// și 1.0 când e maxim în față (jos).
	// Calculăm un factor de scalare progresiv:
	float vertical_factor = sin(sun_angle); // [-1.0 ... 1.0]
	
	// Mapăm factorul astfel încât:
	// Când e în față (vertical_factor > 0), scala e 1.0
	// Când e în spate (vertical_factor < 0), scala scade spre back_shadow_scale
	float lerp_factor = clamp(vertical_factor, -1.0, 0.0); // Luăm doar partea negativă
	// Transformăm intervalul [-1, 0] în [back_shadow_scale, 1.0]
	float smooth_scale = mix(1.0, back_shadow_scale, abs(lerp_factor));
	
	// Aplicăm scala progresivă pe ambele axe pentru a păstra forma
	dir *= smooth_scale;
	
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	float dist_from_pivot = (pivot_offset - UV.y) * size.y;

	VERTEX.x += dist_from_pivot * dir.x;
	VERTEX.y += dist_from_pivot * dir.y;
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a < 0.01) {
		discard;
	}
	COLOR = vec4(shadow_color.rgb, col.a * shadow_opacity);
}