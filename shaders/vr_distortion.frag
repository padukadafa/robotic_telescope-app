#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D uTexture;
uniform float uK1;
uniform float uK2;
uniform float uOffsetX; // Horizontal offset for shifting left/right

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // Apply horizontal offset to shift the image
    uv.x = uv.x - uOffsetX;
    
    vec2 center = vec2(0.5, 0.5);
    vec2 delta = uv - center;
    
    float r2 = dot(delta, delta);
    float distortion = 1.0 + uK1 * r2 + uK2 * r2 * r2;
    
    vec2 distortedUV = center + delta * distortion;
    
    if (distortedUV.x < 0.0 || distortedUV.x > 1.0 || 
        distortedUV.y < 0.0 || distortedUV.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        fragColor = texture(uTexture, distortedUV);
    }
}
