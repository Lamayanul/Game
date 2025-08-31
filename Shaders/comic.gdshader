shader_type canvas_item;
render_mode unshaded;

uniform bool outlines_on = true;
uniform float edge_strength : hint_range(0.0, 5.0) = 1.6;
uniform float edge_threshold : hint_range(0.0, 1.0) = 0.25;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float posterize_levels : hint_range(2.0, 16.0) = 6.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.2;
uniform float contrast   : hint_range(0.0, 2.0) = 1.05;

uniform bool  halftone_on = true;
uniform float halftone_cell_px   : hint_range(2.0, 64.0) = 10.0;
uniform float halftone_strength  : hint_range(0.0, 1.0)  = 0.7;
uniform float halftone_angle_deg : hint_range(0.0, 90.0) = 45.0;

// (opțional) e implicit, poți și să-l lași nedeclarat:
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// helper pentru rotație
mat2 rot2(float deg) {
    float a = radians(deg);
    float s = sin(a);
    float c = cos(a);
    // mat2 primește coloanele ca doi vec2
    return mat2(vec2(c, s), vec2(-s, c));
}

void fragment() {
    vec2 res = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 uv  = SCREEN_UV;

    vec4 src = texture(SCREEN_TEXTURE, uv);
    vec3 col = src.rgb;

    // saturation + contrast
    float g = luma(col);
    col = mix(vec3(g), col, saturation);
    col = (col - 0.5) * contrast + 0.5;

    // posterizare
    float lev = max(2.0, posterize_levels);
    col = floor(col * lev) / lev;

    // halftone
    if (halftone_on) {
        mat2 R = rot2(halftone_angle_deg);

        vec2 cell = (uv * res) / max(1.0, halftone_cell_px);
        cell = R * cell;

        vec2 gv = fract(cell) - 0.5;

        float Y = luma(col);
        float r = clamp(1.0 - Y, 0.0, 1.0);
        float d = length(gv) * 1.4142;
        float dot_mask = smoothstep(r, r - 0.25, d);

        col *= mix(1.0, 1.0 - dot_mask, halftone_strength);
    }

    // contur (Sobel)
    if (outlines_on) {
        vec2 texel = 1.0 / res;

        float s00 = luma(texture(SCREEN_TEXTURE, uv + texel * vec2(-1.0, -1.0)).rgb);
        float s10 = luma(texture(SCREEN_TEXTURE, uv + texel * vec2( 0.0, -1.0)).rgb);
        float s20 = luma(texture(SCREEN_TEXTURE, uv + texel * vec2( 1.0, -1.0)).rgb);
        float s01 = luma(texture(SCREEN_TEXTURE, uv + texel * vec2(-1.0,  0.0)).rgb);
        float s21 = luma(texture(SCREEN_TEXTURE, uv + texel * vec2( 1.0,  0.0)).rgb);
        float s02 = luma(texture(SCREEN_TEXTURE, uv + texel * vec2(-1.0,  1.0)).rgb);
        float s12 = luma(texture(SCREEN_TEXTURE, uv + texel * vec2( 0.0,  1.0)).rgb);
        float s22 = luma(texture(SCREEN_TEXTURE, uv + texel * vec2( 1.0,  1.0)).rgb);

        float gx = -s00 - 2.0*s01 - s02 + s20 + 2.0*s21 + s22;
        float gy = -s00 - 2.0*s10 - s20 + s02 + 2.0*s12 + s22;
        float mag = length(vec2(gx, gy)) * edge_strength;

        float edge = smoothstep(edge_threshold, edge_threshold + 0.2, mag);
        col = mix(col, outline_color.rgb, edge);
    }

    COLOR = vec4(col, src.a);
}
