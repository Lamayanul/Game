shader_type canvas_item;

// --- PARAMETRI EXPUSI ÎN INSPECTOR ---

// Lățimea zonei opace din centru (0.0 - 1.0)
uniform float center_width : hint_range(0.0, 1.0) = 0.6;

// Înălțimea zonei opace din centru (0.0 - 1.0)
uniform float center_height : hint_range(0.0, 1.0) = 0.6;

// Lățimea zonei de tranziție spre transparență [0.0 - 1.0]
uniform float softness : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	// 1. Obținem culoarea originală a texturii (păstrând și Alpha-ul ei original)
	vec4 color = texture(TEXTURE, UV);
	
	// 2. Calculăm distanța absolută a pixelului față de centrul imaginii (0.5, 0.5)
	vec2 dist = abs(UV - vec2(0.5));
	
	// Reconstruim vectorul din cei doi parametri separați
	vec2 opaque_center_size = vec2(center_width, center_height);
	
	// 3. Calculăm unde începe să se estompeze (fade) pe fiecare axă.
	vec2 fade_start = opaque_center_size * 0.5;
	
	// Punctul unde imaginea devine complet transparentă la margini extreme.
	vec2 fade_end = clamp(fade_start + vec2(softness), vec2(0.0), vec2(0.5));
	
	// 4. Magia smoothstep aplicată pe vectori simultan
	vec2 smooth_fade = smoothstep(fade_start, fade_end, dist);
	
	// 5. Inversăm rezultatul pentru mască: vrem opac în centru (1.0) și transparent la margini (0.0)
	vec2 alpha_mask_vec = 1.0 - smooth_fade;
	
	// 6. Alegem Alpha-ul minim dintre cele două axe pentru a crea colțurile "ramei"
	float alpha_mask = min(alpha_mask_vec.x, alpha_mask_vec.y);
	
	// 7. Aplicăm masca finală peste Alpha-ul original al imaginii
	color.a *= alpha_mask;
	
	// Setați culoarea finală a pixelului
	COLOR = color;
}