shader_type canvas_item;

uniform float wave_strength = 2.0;
uniform float wave_speed = 5.0;
uniform float transparency = 0.2; // 0 (invizibil) - 1 (complet opac)
uniform vec2 wave_scale = vec2(10.0, 10.0); // Scara valurilor

void fragment() {
    vec2 uv = UV;

    // Deformează UV-ul pentru efect de val
    uv.x += sin(uv.y * wave_scale.y + TIME * wave_speed) * 0.01 * wave_strength;
    uv.y += cos(uv.x * wave_scale.x + TIME * wave_speed) * 0.01 * wave_strength;

    // Textura normală
    vec4 tex = texture(TEXTURE, uv);

    // Aplică transparența
    COLOR = tex;
    COLOR.a *= transparency;
}
