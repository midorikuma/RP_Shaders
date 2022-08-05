#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform mat3 IViewRotMat;
uniform mat4 ProjMat;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;
in vec3 normal;

in float CMHtype;
in vec3 position;

out vec4 fragColor;

//const values
const vec2 ts = vec2(64.0);

// Reference
// https://www.shadertoy.com/view/MlGcDz
// https://www.shadertoy.com/view/WdBGWR

// Triangle intersection. Returns { t, u, v }
// http://iquilezles.org/www/articles/intersectors/intersectors.htm
vec3 triIntersect(in vec3 ro, in vec3 rd, in vec3 v0, in vec3 v1, in vec3 v2) {
    vec3 v1v0 = v1 - v0;
    vec3 v2v0 = v2 - v0;
    vec3 rov0 = ro - v0;

    vec3 n = cross(v1v0, v2v0);
    vec3 q = cross(rov0, rd);
    float d = 1.0 / dot(rd, n);
    float u = d * dot(-q, v2v0);
    float v = d * dot(q, v1v0);
    float t = d * dot(-n, rov0);

    if(u < 0.0 || v < 0.0 || (u + v) > 1.0)
        t = -1.0;

    return vec3(t, u, v);
}

vec3 ftov(in int f, in mat3 R) {
    vec3 vs = texture(Sampler0, vec2(16 + f % 32, 48 + f / 32) / ts).rgb;
    ivec3 va = ivec3(texture(Sampler0, vec2(f / 8 % 32, 29 + f / 8 / 32) / ts).rgb * 255.1) % (1 << (f % 8 + 1)) / (1 << (f % 8));
    return vs * vec3(1 - va * 2) * R;
}

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if(CMHtype != 0.0) {
        vec4 main1 = texture(Sampler0, vec2(16.0, 1.0) / ts) * 255.0;
        float pc = main1.r;
        float vc = main1.g + main1.b;
        vec2 p = (mod(texCoord0 * 64.0, 8.0) / 8.0 * 2.0 - 1.0);

        mat3 rotmat = IViewRotMat;

        vec3 vx = vec3(0.0, 0.0, -1.0);
        vec3 vz = vec3(1.0, 0.0, 0.0);
        mat3 V = mat3(vx, vz, cross(vx, vz));
        vec3 w = IViewRotMat * normalize(normal);
        vec3 wx = vec3(w.x, 0.0, w.z);
        vec3 wz = vec3(w.z, 0.0, -w.x);
        mat3 W = mat3(wx, wz, cross(wx, wz));
        mat3 R = W * inverse(V);
        vec3 rot = vec3(position.xyz / length(position.xyz)) * 2.0;

        vec3 ro = IViewRotMat * rot;

        float zoom = length(position.xyz) * 2.0;
        ro = ro * zoom;
        vec3 ta = vec3(0.0, 0.0, 0.0);

    // camera matrix
        //vec3 ry = IViewRotMat * vec3(position.x * position.y / length(position.xyz) / length(position.xy), 2.0, 0.0);
        vec3 ry = rotmat * vec3(0.0, 1.0, 0.0);

        float lit = 1.0;
        vec3 litd = -Light0_Direction;
        if(CMHtype == 2.0) {
            ry = vec3(0.0, 1.0, 0.0);
            ro = vec3(0.0, 0.0, 10.0);
            R = mat3(1.0);
            zoom = 10.0;
            lit = 1.0;
            litd = Light1_Direction;
        }
        if(CMHtype == 3.0) {
            ry = vec3(0.0, 1.0, 0.0);
            ro = vec3(1.0, 1.0, 6.0);
            R = mat3(1.0);
            zoom = 2.0;
            litd = Light1_Direction;
        }
        vec3 ww = normalize(ta - ro);
        vec3 uu = normalize(cross(ww, vec3(ry)));
        vec3 vv = normalize(cross(uu, ww));
	// create view ray
        vec3 rd = normalize(p.x * uu + p.y * vv + zoom * ww) * zoom;

    // raytrace
        float tmin = 1000.0;
        int index = 0;
        vec3 res;
        vec3 col = vec3(1.0);
        float flag = 0.0;
        for(int i = 0; i < pc; i++) {
            ivec4 fs = ivec4(texture(Sampler0, vec2(i % 32, 4 + int(i / 32)) / ts) * 255.1) - 1;

            vec3 v0 = ftov(fs.r, R);
            vec3 v1 = ftov(fs.g, R);
            vec3 v2 = ftov(fs.b, R);

            res = triIntersect(ro, rd, v0, v1, v2);
            float t2 = res.x;
            if(0.0 < t2 && t2 < tmin) {
                vec3 uvx = texture(Sampler0, vec2(i * 2 % 32, 13 + int(i * 2 / 32)) / ts).rgb;
                vec3 uvy = texture(Sampler0, vec2((i * 2 + 1) % 32, 13 + int((i * 2 + 1) / 32)) / ts).rgb;
                float uvxa = uvx.r * (1.0 - (res.g + res.b)) + uvx.g * res.g + uvx.b * res.b;
                float uvya = uvy.r * (1.0 - (res.g + res.b)) + uvy.g * res.g + uvy.b * res.b;
                ivec2 uv = ivec2(uvxa * 32.0, uvya * 32.0);
                vec4 texcol = texture(Sampler0, vec2(uv.x + 32, 31 - uv.y) / ts);
                col = texcol.rgb;

                tmin = t2;
                vec3 nor = normalize(cross(v1 - v0, v2 - v0));
                col *= dot(litd, nor) * faceforward(-vec3(1.0), -rd, nor) / 5.0 + lit;
                flag = 1.0;
            }
            index += 3;
        }
        color = vec4(col, flag);
    }
    if(color.a < 0.1) {
        discard;
        //color = vec4(1.0);
    }
    //color *= vertexColor;
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= lightMapColor;
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);

    // if(CMHtype == 2.0) {
    //     fragColor = vec4(0.0, 0.0, 1.0, 1.0);
    // } else if(CMHtype == 3.0) {
    //     fragColor = vec4(0.0, 1.0, 0.0, 1.0);
    // } else if(CMHtype == 1.0) {
    //     fragColor = vec4(1.0, 0.0, 0.0, 1.0);
    // } else if(CMHtype == 0.0) {
    //     fragColor = vec4(1.0);
    // }
}
