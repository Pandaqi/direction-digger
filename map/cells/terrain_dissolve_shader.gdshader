shader_type canvas_item;

uniform sampler2D texture1: filter_nearest;
uniform float factor: hint_range(0.0, 1.0);
uniform sampler2D dissolve_map: filter_nearest;

void fragment() 
{
	vec4 colorA = COLOR;
	vec4 colorB = vec4(0,0,0,0);
	vec4 map = texture(dissolve_map, UV);
	// adding 0.1 * (1. - factor) to compensate for pure black on dissolve map
	// not disappearing when factor is 0
	COLOR = mix(colorA, colorB, step(map.r + 0.1 * (1. - factor), factor));
}