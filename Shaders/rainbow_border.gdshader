shader_type canvas_item;

uniform float speed : hint_range(0.0, 10.0) = 1.0;
uniform float frequency : hint_range(0.0, 10.0) = 1.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.2;
uniform bool is_border = false;
uniform float line_width : hint_range(0.0, 20.0) = 4.0; // Grosimea în pixeli
uniform vec2 rect_size; // Dimensiunea ferestrei trimisă din script

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Calculăm culoarea curcubeu
    float hue = UV.x * frequency + UV.y * frequency + TIME * speed;
    vec3 rainbow = vec3(
        0.5 + 0.5 * cos(6.28318 * (hue + 0.0)),
        0.5 + 0.5 * cos(6.28318 * (hue + 0.33)),
        0.5 + 0.5 * cos(6.28318 * (hue + 0.66))
    );
    
    if (is_border) {
        // Convertim UV în coordonate de pixeli
        vec2 pixel_pos = UV * rect_size;
        
        // Verificăm dacă suntem în zona bordurii folosind pixeli reali
        bool x_border = pixel_pos.x < line_width || pixel_pos.x > (rect_size.x - line_width);
        bool y_border = pixel_pos.y < line_width || pixel_pos.y > (rect_size.y - line_width);
        
        if (x_border || y_border) {
            COLOR = vec4(rainbow * brightness, 1.0);
        } else {
            discard; // Interiorul rămâne gol
        }
    } else {
        COLOR = vec4(rainbow * brightness, tex_color.a);
    }
}
