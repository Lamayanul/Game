shader_type canvas_item;

// --- CONTROALE ---
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture,filter_linear_mipmap;
uniform int  bars_count : hint_range(1, 200) = 12;
uniform float bar_thickness : hint_range(0.01, 1.0) = 0.45;
uniform float softness     : hint_range(0.0, 0.5)  = 0.12;

uniform float speed : hint_range(-5.0, 5.0) = 0.6;          // + sus, – jos
uniform float color_cycle_speed : hint_range(0.0, 5.0) = 0.3;

uniform float sat : hint_range(0.0, 1.0) = 1.0;
uniform float val : hint_range(0.0, 2.0) = 1.0;

uniform float bars_opacity : hint_range(0.0, 1.0) = 0.75;   // transparența benzilor
uniform float bg_dim : hint_range(0.0, 1.0) = 0.25;         // cât întunecăm sub bandă

// dacă nodul are TEXTURE (ex. TextureRect), setăm pe true ca să o vedem dedesubt.
// pe noduri fără textură (ex. Panel), lasă false ca să se ia din ecranul deja desenat.
uniform bool use_local_texture = true;

// opțional: mică deplasare globală pentru “a prinde faza”
uniform float global_offset_y = 0.0;

// --- HSV helper ---
vec3 hsv2rgb(vec3 c){
    vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
    vec3 rgb = clamp(p - 1.0, 0.0, 1.0);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

// dimensiune ecran (px) – robust în 4.4.1
vec2 screen_size_px(){ return vec2(textureSize(SCREEN_TEXTURE, 0)); }

void fragment() {
    // 1) bază: TEXTURE dacă există, altfel ce e deja randat pe ecran
    vec3 base = use_local_texture ? texture(TEXTURE, UV).rgb
                                  : texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

    // 2) coordonate pentru benzi din ecran, nu din UV local
    float cells = float(max(bars_count, 1));
    float t = TIME * speed;

    // folosim SCREEN_UV (0..1 pe ecran), astfel toate instanțele au aceeași fază
    float rel = fract((SCREEN_UV.y + global_offset_y) * cells + t);

    // mască bandă
    float halfw = clamp(bar_thickness * 0.5, 0.001, 0.499);
    float d = abs(rel - 0.5);
    float m = smoothstep(halfw + softness, halfw, d);
    float m_glow = smoothstep(halfw + softness*2.5, halfw*1.6, d) * 0.35;

    // culoare care curge în timp, sincronizată între noduri
    float idx = floor((SCREEN_UV.y + global_offset_y) * cells + t);
    float hue = fract(idx / cells + TIME * color_cycle_speed);
    vec3 bar_col = hsv2rgb(vec3(hue, sat, val));

    // 3) compunere: ușor întunecăm sub bandă + adăugăm banda cu opacitate
    vec3 under = mix(base, base * (1.0 - bg_dim), 1.0 - m);
    vec3 color = under + (bar_col * (m + m_glow)) * bars_opacity;

    COLOR = vec4(color, 1.0);
}
