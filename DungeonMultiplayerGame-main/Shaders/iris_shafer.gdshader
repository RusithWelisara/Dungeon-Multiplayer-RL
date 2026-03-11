shader_type canvas_item;

uniform float radius: hint_range(0.0, 2000.0) = 256.0;
uniform vec2 center = vec2(128.0, 112.0);

void fragment() {
	float x = UV.x * 1920.0;
	float y = UV.y * 1080.0;

	float alpha = float((x - center.x) * (x - center.x) + (y - center.y) * (y - center.y) > radius * radius);

	COLOR.a = alpha;
}
