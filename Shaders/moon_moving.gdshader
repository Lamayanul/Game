shader_type canvas_item;

// --- PARAMETRI EXISTENȚI ---
uniform float rotation_speed : hint_range(-5.0, 5.0) = 0.2;
uniform float mineral_blend : hint_range(0.0, 1.0) = 0.7; 
uniform float shadow_sharpness : hint_range(0.0, 1.0) = 0.03;
uniform vec2 light_direction = vec2(1.0, 0.0);

// --- PARAMETRI NOI PENTRU MIȘCAREA GENERALĂ ---
uniform vec2 movement_vector = vec2(0.3, 0.2); // Amplitudinea mișcării pe axa X și Y (cât de departe se mișcă)
uniform float movement_speed : hint_range(0.0, 5.0) = 1.0; // Viteza mișcării generale a elementului

void fragment() {
    // 1. Calculăm un offset dinamic pe X și Y pe baza timpului
    vec2 general_offset = vec2(
        sin(TIME * movement_speed) * movement_vector.x,
        cos(TIME * movement_speed) * movement_vector.y
    );

    // Aplicăm offset-ul pe UV-ul centrat pentru a mișca tot obiectul
    vec2 centered_uv = (UV * 2.0 - 1.0) - general_offset;
    
    // Decupaj cerc perfect (acum cercul se mișcă odată cu offset-ul)
    float dist = length(centered_uv);
    if (dist > 1.0) {
        discard;
    }

    // 2. Rotație planetară corectă
    float z = sqrt(1.0 - centered_uv.x * centered_uv.x - centered_uv.y * centered_uv.y);
    vec2 sphere_uv;
    
    // Corectăm sphere_uv.y pentru a urmări mișcarea generală pe Y
    sphere_uv.x = (asin(centered_uv.x) / 1.570796326) * 0.5 + 0.5;
    sphere_uv.y = UV.y - (general_offset.y * 0.5); 
    sphere_uv.x += TIME * rotation_speed;
    
    vec4 tex_color = texture(TEXTURE, sphere_uv);

    // 3. GENERARE SEPARATĂ A CULORILOR (Procedural Mineral Map)
    float luma = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    
    vec3 mineral_blue = vec3(0.05, 0.25, 0.85);   
    vec3 mineral_orange = vec3(0.85, 0.4, 0.15); 
    vec3 mineral_white = vec3(0.9, 0.9, 0.95);   
    
    vec3 mineral_map;
    if (luma < 0.4) {
        float t = smoothstep(0.0, 0.4, luma);
        mineral_map = mix(mineral_blue, mineral_orange, t);
    } else {
        float t = smoothstep(0.4, 0.8, luma);
        mineral_map = mix(mineral_orange, mineral_white, t);
    }
    
    vec3 final_color = mix(tex_color.rgb, mineral_map, mineral_blend);
    final_color = mix(vec3(dot(final_color, vec3(0.299, 0.587, 0.114))), final_color, 1.5);

    // 4. Iluminare (Umbra rămâne stabilă în spațiu în timp ce luna se mișcă)
    vec3 sphere_normal = normalize(vec3(centered_uv, z));
    vec3 light_dir_3d = normalize(vec3(light_direction.x, light_direction.y, 0.4));
    
    float NdotL = dot(sphere_normal, light_dir_3d);
    float light_intensity = smoothstep(-shadow_sharpness, shadow_sharpness, NdotL);

    // Rezultat final
    COLOR = vec4(final_color * light_intensity, tex_color.a);
}