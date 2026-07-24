shader_type canvas_item;

// --- PARAMETRI ---
uniform float rotation_speed : hint_range(-5.0, 5.0) = 0.2;
uniform float mineral_blend : hint_range(0.0, 1.0) = 0.7; // Cât de mult vrei să se vadă culorile minerale (0 = gri normal, 1 = ca în poză)
uniform float shadow_sharpness : hint_range(0.0, 1.0) = 0.03;
uniform vec2 light_direction = vec2(1.0, 0.0);

void fragment() {
    // 1. Coordonate centrate și decupaj cerc perfect
    vec2 centered_uv = UV * 2.0 - 1.0;
    float dist = length(centered_uv);
    if (dist > 1.0) {
        discard;
    }

    // 2. Rotație planetară corectă (fără efect de vortex/warp)
    float z = sqrt(1.0 - centered_uv.x * centered_uv.x - centered_uv.y * centered_uv.y);
    vec2 sphere_uv;
    sphere_uv.x = (asin(centered_uv.x) / 1.570796326) * 0.5 + 0.5;
    sphere_uv.y = UV.y;
    sphere_uv.x += TIME * rotation_speed;
    
    // Citim textura originală (care probabil e gri)
    vec4 tex_color = texture(TEXTURE, sphere_uv);

    // 3. GENERARE SEPARATĂ A CULORILOR (Procedural Mineral Map)
    // Calculăm luminozitatea pură a pixelului (0.0 = negru, 1.0 = alb pur)
    float luma = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    
    // Definim culorile exacte din fotografia ta
    vec3 mineral_blue = vec3(0.05, 0.25, 0.85);   // Albastrul electric din mări
    vec3 mineral_orange = vec3(0.85, 0.4, 0.15); // Portocaliul de fier de pe uscat
    vec3 mineral_white = vec3(0.9, 0.9, 0.95);   // Zonele înalte, crestele albe
    
    // Creăm harta de minerale bazată pe relief (luma)
    vec3 mineral_map;
    if (luma < 0.4) {
        // Zonele joase și întunecate (mările) primesc albastru intens
        float t = smoothstep(0.0, 0.4, luma);
        mineral_map = mix(mineral_blue, mineral_orange, t);
    } else {
        // Zonele înalte trec de la portocaliu spre albul prăfos de pe margini
        float t = smoothstep(0.4, 0.8, luma);
        mineral_map = mix(mineral_orange, mineral_white, t);
    }
    
    // Combinăm textura originală cu harta minerală în funcție de slider
    vec3 final_color = mix(tex_color.rgb, mineral_map, mineral_blend);
    
    // Păstrăm un contrast puternic ca în imaginea ta
    final_color = mix(vec3(dot(final_color, vec3(0.299, 0.587, 0.114))), final_color, 1.5);

    // 4. Iluminare (Umbra ascuțită, terminatorul zimțat)
    vec3 sphere_normal = normalize(vec3(centered_uv, z));
    vec3 light_dir_3d = normalize(vec3(light_direction.x, light_direction.y, 0.4));
    
    float NdotL = dot(sphere_normal, light_dir_3d);
    float light_intensity = smoothstep(-shadow_sharpness, shadow_sharpness, NdotL);

    // Rezultat final curat
    COLOR = vec4(final_color * light_intensity, tex_color.a);
}