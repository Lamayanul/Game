shader_type canvas_item;

// --- PARAMETRI EXPUSI ÎN INSPECTOR ---
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Negru implicit
uniform float outline_width : hint_range(0.0, 10.0) = 1.0; // Grosimea conturului

void fragment() {
	// Citim culoarea originală a texturii
	vec4 original_color = texture(TEXTURE, UV);
	
	// Calculăm mărimea unui pixel pentru a ști cât de departe să căutăm marginile
	vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
	
	float outline_alpha = 0.0;
	
	// Verificăm transparența în cele 8 direcții din jurul pixelului curent
	outline_alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
	outline_alpha += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
	outline_alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	outline_alpha += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
	outline_alpha += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
	outline_alpha += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
	outline_alpha += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
	outline_alpha += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
	
	// Ne asigurăm că valoarea maximă a opacității conturului nu depășește 1.0
	outline_alpha = min(outline_alpha, 1.0);
	
	// Amestecăm culoarea de contur cu imaginea originală
	vec4 final_color = mix(outline_color, original_color, original_color.a);
	
	// Setați culoarea finală. Opacitatea este maximul dintre imaginea ta și contur.
	COLOR = vec4(final_color.rgb, max(outline_alpha, original_color.a));
}