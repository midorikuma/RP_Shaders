#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec3 ChunkOffset;
uniform int FogShape;

uniform mat3 IViewRotMat;
uniform float GameTime;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec4 normal;

const vec2 corners[4] = vec2[4](vec2(-1.0, 1.0),vec2(-1.0, -1.0),vec2(1.0, -1.0),vec2(1.0, 1.0));
mat3 localRot(mat3 ivrm, vec3 norm) {
    vec3 localZ = ivrm * norm;
    vec3 localX = normalize(cross(vec3(0, 1, 0), localZ));
    vec3 localY = cross(localZ, localX);
    if (0.0<abs(localZ.y)){
    localY = -normalize(cross(vec3(1, 0, 0), localZ));
    localX = cross(localY,localZ);
    }

    return mat3(localX, localY, localZ);
}
void main() {
    vec3 pos = Position + ChunkOffset;
    float t = (1.0-abs(sin(GameTime*24000.0/2.5)));

    vec2 coord = corners[gl_VertexID % 4];
    vec3 volume = vec3(1.0,2.0,1.0)*0.15;
    pos = pos + localRot(IViewRotMat, Normal) * vec3(coord, 1) * volume * IViewRotMat*t;
    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);

    vertexDistance = fog_distance(ModelViewMat, pos, FogShape);
    vertexColor = Color * minecraft_sample_lightmap(Sampler2, UV2);
    texCoord0 = UV0;
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
}
