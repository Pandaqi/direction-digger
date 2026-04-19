shader_type canvas_item;

uniform sampler2D noise_tex;
uniform float scroll_speed = 0.25;
uniform bool blend_enabled = false;

void fragment() {
	vec2 uv = 4.0 * UV;
	uv += vec2(1.0,1.0)*TIME * scroll_speed;
	uv -= vec2(floor(uv.x), floor(uv.y));
	
	float alpha_mult = 1.0;
	if (blend_enabled) { alpha_mult = texture(noise_tex, uv).r; }
	COLOR.a *= alpha_mult;
}
