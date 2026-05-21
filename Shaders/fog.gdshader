shader_type canvas_item;

// --- PARAMETRI CEATĂ ---
uniform vec4 fog_color : source_color = vec4(0.15, 0.15, 0.2, 0.98);
uniform sampler2D cloud_noise : repeat_enable; // Textura de nori
uniform float fog_speed : hint_range(0.0, 0.5) = 0.02; // Viteza de plutire a norilor
uniform float cloud_density : hint_range(0.0, 2.0) = 1.0; // Intensitatea texturii

// --- PARAMETRI GAURĂ (PLAYER) ---
// Poziția playerului în coordonate normalizate de ecran (0.0 la 1.0)
uniform vec2 player_screen_pos; 
uniform float mask_radius : hint_range(0.0, 1.0) = 0.2; // Dimensiunea zonei clare
uniform float mask_softness : hint_range(0.0, 1.0) = 0.2; // Tranziția moale

void fragment() {
	// 1. Efectul de Norisori care plutesc
	// Luăm două mostre din textura de zgomot, la scări și viteze diferite,
	// și le înmulțim pentru a crea complexitate.
	vec2 speed_vec = vec2(TIME * fog_speed);
	float noise1 = texture(cloud_noise, UV * 1.0 + speed_vec).r;
	float noise2 = texture(cloud_noise, UV * 2.5 - speed_vec * 1.5).r;
	
	float combined_noise = noise1 * noise2 * cloud_density;
	combined_noise = clamp(combined_noise, 0.0, 1.0);

	// 2. Efectul de mascare (gaura moale) în jurul playerului
	// Ajustăm raportul de aspect ca gaura să fie rotundă pe ecrane widescreen
	vec2 aspect_ratio_correct = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
	vec2 current_uv = UV * aspect_ratio_correct;
	vec2 target_uv = player_screen_pos * aspect_ratio_correct;
	
	float dist_to_player = distance(current_uv, target_uv);
	
	//smoothstep decupează gaura moale
	float mask = smoothstep(mask_radius, mask_radius + mask_softness, dist_to_player);

    // 3. Combinarea finală
	COLOR = fog_color;
	// Înmulțim opacitatea ceții cu textura de nori ȘI cu masca playerului
	COLOR.a *= combined_noise * mask;
}