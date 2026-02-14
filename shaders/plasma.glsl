// Plasma Waves
// A colorful animated plasma effect

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (2.0 * fragCoord - iResolution.xy) / min(iResolution.x, iResolution.y);

    float t = iTime * 0.5;

    vec3 col = vec3(0.0);
    for (float i = 1.0; i < 5.0; i++) {
        vec2 q = p * i;
        q.x += sin(q.y + t) * 0.3;
        q.y += cos(q.x + t) * 0.3;
        float d = abs(sin(q.x + q.y + t) * 0.5 + 0.5);
        col += vec3(0.5, 0.3, 0.7) / (d * 10.0 + 0.1) / i;
    }

    fragColor = vec4(col, 1.0);
}
