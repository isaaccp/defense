shader_type canvas_item;

instance uniform float highlight_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(1.0, 0.9, 0.2, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    
    if (highlight_intensity > 0.0) {
        vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
        
        float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
        outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
        outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
        outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
        outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
        outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
        outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
        outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
        
        outline = min(outline, 1.0);
        
        vec4 outline_pixel = vec4(outline_color.rgb, outline * outline_color.a);
        
        // Blend outline with original color
        col = mix(outline_pixel, col, col.a);
        
        // Also tint the sprite itself slightly based on intensity
        col.rgb = mix(col.rgb, outline_color.rgb, highlight_intensity * 0.3 * col.a);
        col.a = min(col.a + outline_pixel.a * highlight_intensity, 1.0);
    }
    
    COLOR = col;
}
