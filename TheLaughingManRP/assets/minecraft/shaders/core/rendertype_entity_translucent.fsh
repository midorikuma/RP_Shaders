#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;
in vec4 normal;

out vec4 fragColor;

uniform float GameTime;
flat in int isModel;

vec2 iResolution;
float iTime;
#moj_import <pic.glsl>

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a < 0.1 && isModel != 1) {
        discard;
    }
    color *= vertexColor * ColorModulator;
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= lightMapColor;
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);

    if (isModel == 1) {
        iResolution = vec2(1.0);
        iTime = GameTime*24000.0/20.0;
        mainImage(fragColor,mod(vec2(texCoord0.x,1.0-texCoord0.y),1.0/8.0)*8.0);
        if (fragColor.rgb==vec3(0.0)) discard;
    }
}
