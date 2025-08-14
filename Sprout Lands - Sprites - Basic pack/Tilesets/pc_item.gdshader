shader_type canvas_item;
render_mode unshaded;

uniform float shear_top_px    : hint_range(-400.0, 400.0) = 140.0;
uniform float shear_bottom_px : hint_range(-400.0, 400.0) =  10.0;

uniform float scale_y_top    : hint_range(0.3, 7.0) = 2.75; // sus turtit
uniform float scale_y_bottom : hint_range(-7.0, 2.0) = 1.18; // jos înălțat

uniform float taper_x_top : hint_range(0.0, 0.4) = 0.01;    // sus mai îngust
uniform bool  use_rect_size = false;
uniform vec2  rect_size = vec2(0.0, 0.0);

void vertex() {
    // v=0 sus, v=1 jos
    float v = UV.y;

    vec2 size_px = use_rect_size ? rect_size : (1.0 / TEXTURE_PIXEL_SIZE);
    float cx = 0.5 * size_px.x;
    float cy = 0.5 * size_px.y;

    // 1) trapez: sus mai îngust -> jos normal
    float sx = mix(1.0 - taper_x_top, 1.0, v);
    VERTEX.x = (VERTEX.x - cx) * sx + cx;

    // 2) shear mai mare sus, mai mic jos
    float shear = mix(shear_top_px, shear_bottom_px, v);
    VERTEX.x += shear * (v - 0.5);
	//VERTEX.x -= shear * (v - 0.5);
    // 3) scale pe Y (sus turtit, jos înălțat)
    float sy = mix(scale_y_top, scale_y_bottom, v);
    VERTEX.y = (VERTEX.y - cy) * sy + cy;
}

void fragment() {
    // clamp UV ca să nu se repete textura la margini -> fără „dubluri”
    vec2 uv = clamp(UV, vec2(0.001), vec2(0.999));
    COLOR = texture(TEXTURE, uv);
}
