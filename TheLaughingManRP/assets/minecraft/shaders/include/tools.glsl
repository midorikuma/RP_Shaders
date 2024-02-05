#define PI 3.1415926535897932

const vec2 corners[4] = vec2[4](vec2(-1.0, -1.0),vec2(1.0, -1.0),vec2(1.0, 1.0),vec2(-1.0, 1.0));

bool isgui(mat4 ProjMat) {return ProjMat[2][3] == -2.0;}
bool ishand(float FogStart) {return FogStart*0.000001 > 1;}
mat3 localRot(mat3 ivrm, vec3 norm) {
    vec3 localZ = ivrm * norm;
    vec3 localX = normalize(cross(vec3(0, 1, 0), localZ));
    vec3 localY = cross(localZ, localX);
    return mat3(localX, localY, localZ);
}