shader_type canvas_item;

uniform float speed;

uniform sampler2D backImg: repeat_enable;

uniform sampler2D palette;
uniform float palette_speed = 0.1;

void fragment(){
	
	vec2 scroll = vec2(1.0,0.0) * TIME * speed;
	vec4 tex = texture(TEXTURE, (UV));
	float palette_swap = mod(tex.r - TIME * palette_speed, 1.0);
	COLOR = vec4(texture(palette, vec2(palette_swap, 0)).rgb, tex.a);
	
}