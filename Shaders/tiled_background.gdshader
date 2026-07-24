shader_type canvas_item;

uniform vec2 offset;
uniform float zoom = 1.0;

void fragment() {
	// Folosim fract pentru a forța repetarea texturii chiar dacă modul de import nu e setat pe Repeat
	vec2 uv = fract(UV * zoom + offset);
	COLOR = texture(TEXTURE, uv);
}
