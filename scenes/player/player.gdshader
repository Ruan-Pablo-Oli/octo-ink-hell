shader_type canvas_item;

uniform vec4 effect_color : source_color = vec4(0.3, 0.8, 1.0, 1.0);
uniform float effect_strength : hint_range(0.0, 1.0) = 0.0;

uniform vec4 damage_color : source_color = vec4(1.0, 0.15, 0.15, 1.0);
uniform float damage_strength : hint_range(0.0, 1.0) = 0.0;


void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// =====================================================
	// EXISTING EFFECT
	// =====================================================

	vec3 final_color = mix(
		tex.rgb,
		effect_color.rgb,
		effect_strength
	);


	// =====================================================
	// DAMAGE FLASH
	// =====================================================

	final_color = mix(
		final_color,
		damage_color.rgb,
		damage_strength
	);


	COLOR = vec4(
		final_color,
		tex.a
	);
}