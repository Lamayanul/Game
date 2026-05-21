shader_type canvas_item;

uniform float cutoff_y = 1.0;
uniform bool is_active = false;
uniform vec4 water_tint : source_color = vec4(0.0, 0.5, 1.0, 0.4);

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    if (is_active && UV.y > cutoff_y) {
        // Efectul de apă (tentă albastră + semi-transparență)
        color.rgb = mix(color.rgb, water_tint.rgb, water_tint.a);
        color.a *= 0.7; 
    }
    
    COLOR = color;
}
