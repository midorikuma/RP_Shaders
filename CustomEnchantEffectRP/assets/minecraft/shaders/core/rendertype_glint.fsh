#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform float GlintAlpha;

uniform float GameTime;

in float vertexDistance;
in vec2 texCoord0;

out vec4 fragColor;

vec2 rotate2d(vec2 uv, float angle){
    uv -= vec2(0.5);
    angle = radians(angle);
    return uv * mat2(cos(angle),-sin(angle),
                    sin(angle),cos(angle));
}
vec2 speedXY(vec2 speed){
    vec2 s;
    s.x = speed.x == 0.0 ? 1.0 : 1.0 / speed.x;
    s.y = speed.y == 0.0 ? 1.0 : 1.0 / speed.y;
    return mod(vec2(GameTime * 1200.0), s) * speed;
}

void main() {
    vec4 color = texture(Sampler0, texCoord0) * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }
    vec2 uv = texCoord0 * textureSize(Sampler0,0) * vec2(1.0,0.5)/4.0;
    #moj_import <values.glsl>
    uv = rotate2d(uv, Rot);
    uv += speedXY(Speed);
    uv *= Size;
    fragColor = texture(Sampler0, fract(uv));
}
