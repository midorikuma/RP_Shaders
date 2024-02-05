#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform float FogStart;
uniform float FogEnd;
uniform int FogShape;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightMapColor;
out vec4 overlayColor;
out vec2 texCoord0;
out vec3 normal;
out vec2 coord;

flat out int isModel;

#moj_import <tools.glsl>

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    lightMapColor = texelFetch(Sampler2, UV2 / 16, 0);
    overlayColor = texelFetch(Sampler1, UV1, 0);
    texCoord0 = UV0;
    normal = Normal;

    isModel = 0;
    vec2 texsize = textureSize(Sampler0, 0);
    int vid = (gl_VertexID % (72*4))/4;
    vec2 nUV = UV0*64.0;
    if (texsize == vec2(64.0) && vertexColor.a>0.9 && texelFetch(Sampler0, ivec2(9, 9), 0).a>0.9) {
        if (vid==39) {
            int isGui = int(isgui(ProjMat));
            int isHand = int(ishand(FogStart));

            isModel = 1;
            coord = corners[gl_VertexID % 4];

            vec3 pos = Position + localRot(IViewRotMat, Normal) * vec3(coord, 0.0) * 0.25 * IViewRotMat;
            gl_Position = ProjMat * ModelViewMat * vec4(pos-vec3(coord,0.0)*0.5, 1.0);
            gl_Position.z = 0.0;
        }
    }
}
