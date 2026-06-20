shader_type canvas_item;

uniform float dash_length : hint_range(1.0, 100.0) = 20.0;
uniform float gap_length : hint_range(1.0, 100.0) = 20.0;
instance uniform float speed : hint_range(-50.0, 50.0) = 0.0;
instance uniform vec4 line_color : source_color = vec4(0.3, 0.2, 0.1, 0.6);

void fragment() {
    // We use the UV.x to get the distance along the line.
    // If the line is drawn using Line2D with a generic texture or blank texture,
    // we need to know its length. 
    // Godot 4 Line2D provides the normalized distance in UV.x if texture_mode is tile or stretch.
    // Actually, if we use LINE_TEXTURE_TILE, UV.x goes up based on the length.
    
    float total_length = dash_length + gap_length;
    float mod_val = mod(UV.x + TIME * speed, total_length);
    
    if (mod_val > dash_length) {
        discard;
    }
    
    COLOR = line_color;
}
