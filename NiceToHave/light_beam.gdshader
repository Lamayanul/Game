shader_type canvas_item;


uniform vec4 beam_color : source_color = vec4(1.0, 0.95, 0.8, 0.5);
uniform float top_width : hint_range(0.0, 1.0) = 0.1;
uniform float bottom_width : hint_range(0.0, 1.0) = 0.6;
uniform float fade_strength : hint_range(0.0, 5.0) = 1.0;
uniform float side_softness : hint_range(0.0, 0.5) = 0.15;

void fragment() {
    float x = abs(UV.x - 0.5);
    float current_half_width = mix(top_width, bottom_width, UV.y) * 0.5;
    
    // Horizontal fade (left/right softness)
    float horizontal_fade = smoothstep(current_half_width, current_half_width - side_softness, x);
    
    // Vertical fade (bottom softness)
    float vertical_fade = pow(1.0 - UV.y, fade_strength);
    
    COLOR = vec4(beam_color.rgb, horizontal_fade * vertical_fade * beam_color.a);
}
