shader_type canvas_item;

// Você pode passar a matriz diretamente pelo Inspector do Godot
uniform vec4 r_mux = vec4(0.0, 0.0, 0.0, 0.0); // Multiplicadores do Vermelho
uniform vec4 g_mux = vec4(0.0, 0.0, 0.0, 0.0); // Multiplicadores do Verde
uniform vec4 b_mux = vec4(0.0, 0.0, 0.0, 0.0); // Multiplicadores do Azul
uniform vec4 a_mux = vec4(0.0, 0.0, 0.0, 1.0); // Multiplicadores do Alfa (Transparência)
uniform vec4 add_color = vec4(0.0, 0.0, 0.0, 0.0); // Valores somados (Offset)

void fragment() {
    // Pega a cor original do pixel da textura
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Aplicação da matriz de transformação de cor
    vec4 final_color;
    final_color.r = dot(tex_color, r_mux) + add_color.r;
    final_color.g = dot(tex_color, g_mux) + add_color.g;
    final_color.b = dot(tex_color, b_mux) + add_color.b;
    final_color.a = dot(tex_color, a_mux) + add_color.a;
    
    COLOR = final_color;
}