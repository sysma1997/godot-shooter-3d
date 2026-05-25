shader_type spatial;

uniform vec4 color1 : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform vec4 color2 : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform float square_size = 1.0;
uniform float plane_scale = 10.0; // El tamaño de tu plane mesh

void fragment() {
    // Escalamos las UVs según el tamaño del plano
    vec2 scaled_uv = UV * plane_scale;
    vec2 grid_pos = floor(scaled_uv / square_size);
    float checker = mod(grid_pos.x + grid_pos.y, 2.0);
    
    ALBEDO = mix(color1.rgb, color2.rgb, checker);
    ROUGHNESS = 0.9;
}