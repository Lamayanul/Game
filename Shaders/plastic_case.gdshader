shader_type canvas_item;

uniform vec4 plastic_color : source_color = vec4(1.0, 1.0, 1.0, 0.05);
uniform vec4 ray_color : source_color = vec4(1.0, 1.0, 1.0, 0.4);
uniform float ray_speed : hint_range(0.0, 5.0) = 0.5;
uniform float ray_width : hint_range(0.0, 1.0) = 0.08;
uniform float ray_angle : hint_range(0.0, 6.28) = 0.7;
uniform float ray_count : hint_range(1.0, 15.0) = 4.0;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;
uniform float dust_amount : hint_range(0.0, 1.0) = 0.3;

// Helper for noise/dust
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void fragment() {
    // 1. Refraction Simulation (UV distortion)
    vec2 distorted_uv = UV;
    distorted_uv.x += sin(UV.y * 10.0 + TIME) * distortion_strength * 0.2;
    distorted_uv.y += cos(UV.x * 10.0 + TIME) * distortion_strength * 0.2;

    vec4 final_color = plastic_color;

    // 2. Complex Multi-Layered Rays
    float rotated_uv = UV.x * cos(ray_angle) - UV.y * sin(ray_angle);
    float rays = 0.0;

    for (float i = 0.0; i < ray_count; i++) {
        float offset = i * (1.33 / ray_count);
        // Primary Ray
        float line = fract(rotated_uv + TIME * ray_speed + offset);
        float strength = smoothstep(0.5 - ray_width, 0.5, line) * smoothstep(0.5 + ray_width, 0.5, line);

        // Secondary softer ray (glare)
        float secondary = smoothstep(0.5 - ray_width * 2.0, 0.5, line) * smoothstep(0.5 + ray_width * 2.0, 0.5, line);

        rays += strength + secondary * 0.3;
    }

    // Chromatic Aberration on rays (Simulated)
    final_color.r += rays * ray_color.r * 0.6;
    final_color.g += rays * ray_color.g * 0.7;
    final_color.b += rays * ray_color.b * 0.8;
    final_color.a += rays * ray_color.a;

    // 3. Frozen Dust Specks
    float dust = hash(floor(UV * 200.0));
    if (dust > 1.0 - (dust_amount * 0.01)) {
        final_color.rgb += 0.2;
    }

    // 4. Fresnel / Edge Shine
    float edge_x = smoothstep(0.0, 0.05, UV.x) * smoothstep(1.0, 0.95, UV.x);
    float edge_y = smoothstep(0.0, 0.05, UV.y) * smoothstep(1.0, 0.95, UV.y);
    float fresnel = 1.0 - (edge_x * edge_y);
    final_color.rgb += vec3(fresnel) * 0.15;

    // 5. Corner Glint
    float glint = smoothstep(0.1, 0.0, length(UV - vec2(0.1, 0.1)));
    final_color.rgb += glint * 0.3;

    COLOR = final_color;
}
