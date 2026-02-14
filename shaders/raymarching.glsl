// Raymarching Sphere
// Basic raymarching with a sphere and ground plane

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdPlane(vec3 p) {
    return p.y + 1.0;
}

float map(vec3 p) {
    float sphere = sdSphere(p - vec3(0.0, 0.0, 0.0), 1.0);
    float plane = sdPlane(p);
    return min(sphere, plane);
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // Camera
    vec3 ro = vec3(0.0, 1.0, -3.0);
    vec3 rd = normalize(vec3(uv, 1.5));

    // Rotate camera
    float angle = iTime * 0.3;
    ro.xz = mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * ro.xz;
    rd.xz = mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * rd.xz;

    // Raymarch
    float t = 0.0;
    for (int i = 0; i < 100; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);
        if (d < 0.001 || t > 100.0) break;
        t += d;
    }

    vec3 col = vec3(0.1, 0.1, 0.2);

    if (t < 100.0) {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);
        vec3 lightDir = normalize(vec3(1.0, 1.0, -1.0));
        float diff = max(dot(n, lightDir), 0.0);
        float amb = 0.2;
        col = vec3(0.8, 0.4, 0.2) * (diff + amb);
    }

    fragColor = vec4(col, 1.0);
}
