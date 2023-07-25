#iChannel0 "file://skin.png"
const int numFaces = 256;

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
vec2 fp(in int x, in int y) {
    return vec2(float(x) + 0.5, 63.0 - float(y) + 0.5);
}
vec3 ftov(in int f, in vec3 pos, in vec2 texsize) {
    vec3 v = pos + texture(iChannel0, fp(16 + f % 32, 48 + f / 32) / texsize).rgb;
    ivec3 va = ivec3(texture(iChannel0, fp(f / 8 % 32, 29 + f / 8 / 32) / texsize).rgb * 255.1) % (1 << (f % 8 + 1)) / (1 << (f % 8));
    return v * vec3(1 - va * 2);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (-iResolution.xy + 2.0 * fragCoord.xy) / iResolution.y;

     // camera movement	
    float an = 0.4 * iTime;
    float zoom = 2.0;
    vec3 ro = vec3(sin(an), sin(an), cos(an)) * zoom;
    //vec3 ro = vec3(0, 0, 1) * zoom;

    vec3 ta = vec3(0.0, 0.0, 0.0);

    // camera matrix
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = normalize(cross(uu, ww));
	// create view ray
    vec3 rd = normalize(p.x * uu + p.y * vv + zoom * ww) * zoom * 10.0;

    // raytrace
    float tmin = 1000.0;
    int index = 0;
    vec3 pos = vec3(0.0);
    vec3 res;
    vec3 col = vec3(1.0);
    vec3 lit = normalize(vec3(-0.5, 1.0, 0.5));
    vec2 texsize = vec2(textureSize(iChannel0, 0));
    for(int i = 0; i < numFaces; i++) {
        ivec4 fs = ivec4(texture(iChannel0, fp(i % 32, 4 + int(i / 32)) / texsize) * 255.0);
        int f1 = (fs.r - 1);
        int f2 = (fs.g - 1);
        int f3 = (fs.b - 1);

        vec3 v0 = ftov(f1, pos, texsize);
        vec3 v1 = ftov(f2, pos, texsize);
        vec3 v2 = ftov(f3, pos, texsize);

        res = triIntersect(ro, rd, v0, v1, v2);
        float t2 = res.x;
        if(0.0 < t2 && t2 < tmin) {
            tmin = t2;
            vec3 nor = normalize(cross(v1 - v0, v2 - v0));
            vec3 uvx = texture(iChannel0, fp(i * 2 % 32, 13 + int(i * 2 / 32)) / texsize).rgb;
            vec3 uvy = texture(iChannel0, fp((i * 2 + 1) % 32, 13 + int((i * 2 + 1) / 32)) / texsize).rgb;
            float uvxa = uvx.r * (1.0 - (res.g + res.b)) + uvx.g * res.g + uvx.b * res.b;
            float uvya = uvy.r * (1.0 - (res.g + res.b)) + uvy.g * res.g + uvy.b * res.b;
            ivec2 uv = ivec2(uvxa * 32.0, uvya * 32.0);
            vec4 texcol = texture(iChannel0, fp(uv.x + 32, 31 - uv.y) / texsize);
            col = texcol.rgb;
        }
        index += 3;
    }

    // shading/lighting	
    fragColor = vec4(col, 1.0);
}