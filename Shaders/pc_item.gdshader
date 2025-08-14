shader_type canvas_item;

uniform float skew_strength : hint_range(-0.5, 0.5) = 0.9;

void fragment() {
    vec2 uv_skew = vec2(
        UV.x + (UV.y - 0.5) * skew_strength,
        UV.y
    );
}
