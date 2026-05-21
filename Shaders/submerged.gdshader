shader_type canvas_item;

uniform bool is_in_water = false;
uniform float water_level = 0.65; // Proporția de sprite care este "sub apă" (0.0 - 1.0)
uniform vec4 water_color : source_color = vec4(0.0, 0.4, 0.8, 0.5);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    if (is_in_water) {
        // Dacă pixelul este în partea de jos a sprite-ului
        if (UV.y > water_level) {
            // Aplicăm o tentă albăstruie și reducem opacitatea pentru a părea sub apă
            tex_color.rgb = mix(tex_color.rgb, water_color.rgb, water_color.a);
            // Putem adăuga și un mic efect de distorsiune sau transparență aici dacă dorim
            tex_color.a *= 0.8; 
        }
    }
    
    COLOR = tex_color;
}
