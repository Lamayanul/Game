shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.0, 1.0);
uniform float thickness : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 size = TEXTURE_PIXEL_SIZE * thickness;
	
	float alpha = col.a;
	alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
	alpha += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
	alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
	
	alpha = clamp(alpha, 0.0, 1.0);
	
	vec4 glow = glow_color;
	glow.a *= alpha;
	
	// We want the glow to be BEHIND the icon or just the outline
	// If we use this on a separate Sprite2D, we can just return the glow
	// but with alpha subtracted by the original texture to have just the outline, 
	// OR just the glow if it's placed behind.
	
	COLOR = glow;
}
