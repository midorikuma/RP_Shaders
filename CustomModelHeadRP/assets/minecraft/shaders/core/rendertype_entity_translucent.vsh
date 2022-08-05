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
uniform int FogShape;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightMapColor;
out vec4 overlayColor;
out vec2 texCoord0;
out vec3 normal;

out float CMHtype;
out vec3 position;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    lightMapColor = texelFetch(Sampler2, UV2 / 16, 0);
    overlayColor = texelFetch(Sampler1, UV1, 0);
    texCoord0 = UV0;

    vec2 texsize = textureSize(Sampler0, 0);
    bool CMHflag = false;
    if(texsize == vec2(64.0)) {
        CMHflag = ivec4(texture(Sampler0, vec2(0.0, 0.0) / texsize) * 255.0) == ivec4(112, 134, 156, 255);
        CMHflag = CMHflag && ivec4(texture(Sampler0, vec2(1.0, 0.0) / texsize) * 255.0) == ivec4(112, 134, 156, 255);
        CMHflag = CMHflag && ivec4(texture(Sampler0, vec2(2.0, 0.0) / texsize) * 255.0) == ivec4(112, 134, 156, 255);
        CMHflag = CMHflag && ivec4(texture(Sampler0, vec2(3.0, 0.0) / texsize) * 255.0) == ivec4(112, 134, 156, 255);
    }
    //0:none, 1:OnWorld, 2:OnGUI, 3:HoldingHand
    CMHtype = 0.0;
    if(CMHflag) {
        CMHtype = 1.0;
        vec2 pm;
        switch(gl_VertexID % 48) {
            case 16:
                pm = vec2(-1.0, -1.0);
                break;
            case 17:
                pm = vec2(1.0, -1.0);
                break;
            case 18:
                pm = vec2(1.0, 1.0);
                break;
            case 19:
                pm = vec2(-1.0, 1.0);
                break;
        }

        float ry = pm.x * 3.14 * 1 / 2;
        float offy = pm.y * 0.25;
        mat3 rotatey = mat3(cos(ry), 0.0, sin(ry), 0.0, 1.0, 0.0, -sin(ry), 0.0, cos(ry));
        vec3 offx = (IViewRotMat * Normal * rotatey) * IViewRotMat / 4.0;
        position = Position - (Normal / 4.0 - vec3(0.0, offy, 0.0) * IViewRotMat - offx);
        //position = Position - (Normal / 4.0 - vec3(0.0, offy, 0.0) * IViewRotMat - offx) / 2.0;
        bool selitem = 1625.0 <= vertexDistance && vertexDistance < 1750.0;
        bool ininv = 1750.0 <= vertexDistance && vertexDistance < 1850.0;
        bool inhotbar = 1850.0 <= vertexDistance && vertexDistance < 2000.0;

        offx = Normal * rotatey / 4.0;
        vec3 pos = Position - Normal / 4.0 + vec3(0.0, offy, 0.0) + offx;

        vec3 p = vec3(0.56, -0.76, -0.72);
        float pl = 0.2;
        bool handitem = p.x - pl < pos.x && pos.x < p.x + pl;
        handitem = handitem && p.y - pl < pos.y && pos.y < p.y + pl;
        handitem = handitem && p.z - pl < pos.z && pos.z < p.z + pl;
        handitem = handitem && 0.9 <= Normal.z && Normal.z <= 1.0;

        if(inhotbar || ininv || selitem) {
            CMHtype = 2.0;
            gl_Position = ProjMat * ModelViewMat * vec4(pm * 0.5, -1.0, 1.0);
        } else if(handitem) {
            CMHtype = 3.0;
            vec2 offset = pm * vec2(0.75, -0.75);
            gl_Position = vec4(pos, 1.0) - ProjMat * vec4(offset, 0.0, 1.0);
        } else {
            vec2 offset = pm * vec2(0.5);
            normal = IViewRotMat * Normal;
            if(-0.05 <= normal.y && normal.y <= -0.01) {
                position = Position - (Normal / 4.0 - vec3(0.0, offy, 0.0) * IViewRotMat - offx) / 2.0;
            }
            gl_Position = ProjMat * vec4(position - vec3(offset, 0.0), 1.0);
            if(0.01 <= normal.y && normal.y <= 0.05) {
                position = Position - (Normal / 4.0 - vec3(0.0, offy, 0.0) * IViewRotMat) / 2.0;
                gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
            }
        }

        if(gl_VertexID % 48 < 16 || 20 <= gl_VertexID % 48) {
            gl_Position = vec4(0.0);
        }
    }
    normal = Normal;
}
