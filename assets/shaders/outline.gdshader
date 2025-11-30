shader_type canvas_item;

// Outline shader pour mettre en évidence les objets interactifs

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.5, 1.0);
uniform float outline_width : hint_range(0.0, 8.0) = 3.0;
uniform bool enabled = false;

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	if (enabled && col.a < 0.5) {
		float alpha_sum = 0.0;

		// Sample surrounding pixels
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
			COLOR = col;
		}
	} else {
		COLOR = col;
	}
}
