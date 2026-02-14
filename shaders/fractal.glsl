// Mandelbrot Fractal
// Classic fractal with smooth coloring and zoom

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Animated zoom and pan
    float zoom = 2.0 + sin(iTime * 0.1) * 1.5;
    vec2 c = uv * zoom + vec2(-0.5, 0.0);

    vec2 z = vec2(0.0);
    float iter = 0.0;
    const float maxIter = 100.0;

    for (float i = 0.0; i < maxIter; i++) {
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if (dot(z, z) > 4.0) {
            iter = i;
            break;
        }
        iter = i;
    }

    // Smooth coloring
    float smooth_iter = iter - log2(log2(dot(z, z))) + 4.0;

    vec3 col = vec3(0.0);
    if (iter < maxIter - 1.0) {
        float t = smooth_iter / maxIter;
        col = 0.5 + 0.5 * cos(3.0 + t * 6.28318 * 2.0 + vec3(0.0, 0.6, 1.0));
    }

    fragColor = vec4(col, 1.0);
}
