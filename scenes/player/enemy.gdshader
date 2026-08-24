shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(0.56, 0.0, 1.0, 1.0); // Roxo (ou mude para branco 1,1,1,1)
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    // Mistura a cor original com a cor do flash baseada no modificador
    color.rgb = mix(color.rgb, flash_color.rgb, flash_modifier);
    COLOR = color;
}