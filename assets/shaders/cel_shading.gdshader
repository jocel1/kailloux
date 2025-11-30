shader_type canvas_item;

// Cel-shading shader pour Kailloux Adventures
// Crée un effet toon/cartoon avec couleurs quantifiées et contours

uniform vec4 outline_color : source_color = vec4(0.1, 0.08, 0.06, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform int color_levels : hint_range(2, 8) = 4;
uniform float brightness : hint_range(0.5, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.2;

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	if (col.a < 0.01) {
		// Check for outline
		float alpha_sum = 0.0;
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				if (x == 0 && y == 0) continue;
				vec2 offset = vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE * outline_width;
				alpha_sum += texture(TEXTURE, UV + offset).a;
			}
		}

		if (alpha_sum > 0.0) {
			COLOR = outline_color;
		} else {
			COLOR = vec4(0.0);
		}
	} else {
		// Quantize colors for cel-shading effect
		float levels = float(color_levels);
		col.rgb = floor(col.rgb * levels + 0.5) / levels;

		// Adjust brightness
		col.rgb *= brightness;

		// Adjust saturation
		float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		col.rgb = mix(vec3(gray), col.rgb, saturation);

		COLOR = col;
	}
}
