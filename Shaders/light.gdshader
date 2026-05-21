shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 4.0;
uniform float dust_density : hint_range(0.0, 100.0) = 40.0;
uniform float particle_size : hint_range(0.0, 0.5) = 0.1;
uniform float speed : hint_range(0.0, 2.0) = 0.3;
uniform vec4 light_color : source_color = vec4(1.0, 0.9, 0.6, 1.0);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // Luăm culoarea și transparența texturii tale de con
    vec4 tex = texture(TEXTURE, UV);
    
    // 1. BLUR PROCESAT (Soft Edges)
    // Creăm un degrade la margini bazat pe alpha-ul texturii
    float mask = smoothstep(0.0, blur_amount * 0.1, tex.a);
    
    // 2. PARTICULE PROCEDURALE
    vec2 st = UV * dust_density;
    vec2 ipos = floor(st);
    vec2 fpos = fract(st);
    
    float time = TIME * speed;
    // Mișcare Browniană simplă
    vec2 offset = vec2(
        sin(time + hash(ipos) * 6.28), 
        cos(time + hash(ipos + 1.0) * 6.28)
    ) * 0.3;
    
    float p = 0.0;
    if (hash(ipos) > 0.9) { // Doar 10% din celule au particule
        float d = length(fpos - 0.5 - offset);
        p = smoothstep(particle_size, 0.0, d);
    }
    
    // 3. COMBINARE FINALĂ
    // Particulele apar doar unde textura conului este vizibilă (tex.a)
    vec3 color_with_dust = light_color.rgb + (p * 0.5); 
    float alpha = tex.a * mask * light_color.a;
    
    COLOR = vec4(color_with_dust, alpha);
}