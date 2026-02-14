// Gare de l'Est Facade - Iteration 10
// Synthesis: timeless presence, breathing stone, jeweled light, quiet water

float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdColumn(vec2 p, float w, float h, float time, float id) {
    // Gentle individual breathing
    float breath = 1.0 + 0.018 * sin(time * 0.5 + id * 1.2);
    float sway = sin(time * 0.3 + id * 0.6) * 0.003;
    p.x += sway * (p.y + h);
    float shaft = sdBox(p, vec2(w * 0.35 * breath, h));
    float capital = sdBox(p - vec2(0.0, h), vec2(w * 0.5 * breath, h * 0.08));
    float base = sdBox(p + vec2(0.0, h), vec2(w * 0.5 * breath, h * 0.08));
    return min(min(shaft, capital), base);
}

float sdTriangle(vec2 p, float w, float h) {
    p.x = abs(p.x);
    return max(p.y - h + p.x * (h / w), -p.y);
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = noise(i);
    float b = noise(i + vec2(1.0, 0.0));
    float c = noise(i + vec2(0.0, 1.0));
    float d = noise(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float f = 0.0;
    f += 0.5 * smoothNoise(p); p *= 2.0;
    f += 0.25 * smoothNoise(p); p *= 2.0;
    f += 0.125 * smoothNoise(p); p *= 2.0;
    f += 0.0625 * smoothNoise(p);
    return f;
}

vec2 waterRipple(vec2 uv, float time) {
    float ripple1 = sin(uv.x * 12.0 + time * 1.2) * 0.0025;
    float ripple2 = sin(uv.y * 10.0 + time) * 0.003;
    float ripple3 = sin(length(uv) * 18.0 - time * 1.5) * 0.0015;
    return vec2(ripple1 + ripple3, ripple2);
}

// The heart of the building - a jeweled window of light
vec4 roseWindow(vec2 p, float radius, float time) {
    float r = length(p);
    float a = atan(p.y, p.x);

    // Gentle, living radius
    radius *= 1.0 + 0.01 * sin(time * 0.4);

    if (r > radius) return vec4(0.0, 0.0, 0.0, 0.0);

    // Outer ring breathes slowly
    float ringRadius = radius * (0.95 + 0.015 * sin(time * 0.5));
    float ring = abs(r - ringRadius) - radius * 0.015;

    // Main spokes flow like time itself
    float mainSpokes = 12.0;
    float spokeAngle = a + sin(r * 8.0 + time * 0.2) * 0.06 + time * 0.025;
    float spoke = abs(mod(spokeAngle / 6.28318 * mainSpokes + 0.5, 1.0) - 0.5);
    spoke = spoke * r * 3.5 - 0.009;

    // Secondary structure
    float subSpokes = 24.0;
    float subAngle = a + cos(r * 5.0 - time * 0.15) * 0.08 - time * 0.015;
    float subSpoke = abs(mod(subAngle / 6.28318 * subSpokes, 1.0) - 0.5);
    subSpoke = subSpoke * r * 5.0 - 0.004;

    // Concentric circles ripple outward
    float circles = abs(mod(r / radius * 5.0 - time * 0.08 + sin(a * 3.0) * 0.05, 1.0) - 0.5) - 0.055;
    float inner1 = abs(r - radius * (0.5 + 0.015 * sin(time * 0.6))) - radius * 0.009;
    float inner2 = abs(r - radius * (0.3 + 0.012 * sin(time * 0.8))) - radius * 0.007;

    // Center blooms eternally
    float centerA = atan(p.y, p.x);
    float petals = abs(r - radius * 0.12 * (1.0 + 0.25 * sin(centerA * 8.0 + time * 0.35))) - radius * 0.012;

    float pattern = min(ring, min(spoke, min(subSpoke, min(circles, min(inner1, min(inner2, petals))))));

    // Colors like memories of light through cathedral glass
    float hue = mod(a / 6.28318 + r / radius * 0.28 + time * 0.035, 1.0);
    vec3 glassColor;

    // Sapphire, gold, ruby, amethyst
    if (hue < 0.25) {
        glassColor = mix(vec3(0.15, 0.38, 0.82), vec3(0.42, 0.62, 0.95), hue * 4.0);
    } else if (hue < 0.5) {
        glassColor = mix(vec3(0.88, 0.78, 0.38), vec3(1.0, 0.92, 0.52), (hue - 0.25) * 4.0);
    } else if (hue < 0.75) {
        glassColor = mix(vec3(0.78, 0.28, 0.22), vec3(0.95, 0.42, 0.32), (hue - 0.5) * 4.0);
    } else {
        glassColor = mix(vec3(0.52, 0.28, 0.62), vec3(0.72, 0.45, 0.82), (hue - 0.75) * 4.0);
    }

    float luminosity = 0.82 + 0.18 * sin(a * 5.0 + r * 7.0 + time * 0.3);
    glassColor *= luminosity * 1.15;

    return vec4(glassColor, pattern);
}

float facade(vec2 p, float time) {
    float d = 1e10;

    vec2 dp = p;
    float slowTime = time * 0.18;

    // The building breathes like a sleeping giant
    float wave1 = sin(p.y * 2.2 + slowTime * 1.0) * 0.015;
    float wave2 = cos(p.x * 1.8 + slowTime * 0.85) * 0.012;
    float wave3 = sin(p.x * p.y * 1.0 + slowTime * 0.7) * 0.008;
    dp.x += wave1 + wave3;
    dp.y += wave2;

    float centralWidth = 0.32 * (1.0 + 0.01 * sin(time * 0.35));
    float centralHeight = 0.55;
    float centerBlock = sdBox(dp - vec2(0.0, 0.05), vec2(centralWidth, centralHeight));
    d = min(d, centerBlock);

    // Cornices
    float upperCornice = sdBox(dp - vec2(0.0, 0.48), vec2(centralWidth + 0.02, 0.011));
    d = min(d, upperCornice);

    // The great arch
    vec2 archPos = dp - vec2(0.0, 0.15);
    float archRadius = 0.25 + 0.008 * sin(time * 0.45);
    float mainArch = abs(sdCircle(archPos, archRadius)) - 0.015;
    d = min(d, mainArch);

    float innerArch1 = abs(sdCircle(archPos, archRadius * 0.92)) - 0.006;
    d = min(d, innerArch1);

    // Pediment reaching toward sky
    vec2 pedPos = dp - vec2(0.0, 0.52);
    float pedHeight = 0.13 + 0.007 * sin(time * 0.5);
    float pediment = sdTriangle(pedPos, centralWidth + 0.1, pedHeight);
    float pedFill = max(-pediment, -pedPos.y);
    d = min(d, pedFill);

    float pedBase = sdBox(pedPos + vec2(0.0, 0.01), vec2(centralWidth + 0.11, 0.015));
    d = min(d, pedBase);

    float pedOutline = abs(pediment) - 0.016;
    pedOutline = max(pedOutline, -pedPos.y - pedHeight);
    d = min(d, pedOutline);

    // Wings spread wide
    float wingWidth = 0.35;
    float wingHeight = 0.42;
    float wingOffset = 0.58;

    float leftBreath = 1.0 + 0.008 * sin(time * 0.45);
    float rightBreath = 1.0 + 0.008 * sin(time * 0.45 + 0.7);

    float leftWing = sdBox(dp - vec2(-wingOffset, -0.02), vec2(wingWidth * leftBreath, wingHeight));
    d = min(d, leftWing);

    float rightWing = sdBox(dp - vec2(wingOffset, -0.02), vec2(wingWidth * rightBreath, wingHeight));
    d = min(d, rightWing);

    // Windows like watching eyes
    for (float row = 0.0; row < 4.0; row++) {
        for (float col = 0.0; col < 5.0; col++) {
            float wx = 0.065 * (col - 2.0);
            float wy = 0.09 * row - 0.22;
            float phase = row * 0.45 + col * 0.28;
            float pulse = 0.002 * sin(time * 0.5 + phase);

            vec2 lwPos = vec2(-wingOffset + wx, wy);
            float lw = sdBox(dp - lwPos, vec2(0.024 + pulse, 0.035));
            d = min(d, lw);

            vec2 rwPos = vec2(wingOffset + wx, wy);
            float rw = sdBox(dp - rwPos, vec2(0.024 + pulse, 0.035));
            d = min(d, rw);
        }
    }

    // Colonnade - ancient, patient
    float colY = -0.38;
    float colSpacing = 0.08;

    for (float i = -8.0; i <= 8.0; i++) {
        if (abs(i) < 1.5) continue;
        float cx = i * colSpacing;
        vec2 colPos = dp - vec2(cx, colY);
        float col = sdColumn(colPos, 0.026, 0.085, time, i);
        d = min(d, col);
    }

    float entablature = sdBox(dp - vec2(0.0, colY + 0.1), vec2(0.75, 0.013));
    d = min(d, entablature);

    float baseLevel = sdBox(dp - vec2(0.0, colY - 0.1), vec2(0.78, 0.016));
    d = min(d, baseLevel);

    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float t = iTime;

    // Water line - a still mirror
    float waterLine = -0.5;
    bool isReflection = uv.y < waterLine;

    vec2 duv = uv;
    if (isReflection) {
        duv.y = 2.0 * waterLine - duv.y;
        duv += waterRipple(duv, t);
    }

    duv.y += 0.05;

    // Global breathing
    float breathe = sin(t * 0.25) * 0.5 + 0.5;
    duv.x += sin(duv.y * 3.0 + t * 0.35) * 0.007 * (0.9 + 0.2 * breathe);
    duv.y += cos(duv.x * 2.2 + t * 0.28) * 0.005 * (0.9 + 0.2 * breathe);

    float d = facade(duv, t);
    vec4 rose = roseWindow(duv - vec2(0.0, 0.15), 0.22, t);

    // The eternal twilight - neither day nor night
    vec3 skyTop = vec3(0.3, 0.4, 0.58);
    vec3 skyMid = vec3(0.58, 0.52, 0.52);
    vec3 skyLow = vec3(0.85, 0.7, 0.55);
    vec3 skyHorizon = vec3(0.95, 0.8, 0.58);

    float skyY = duv.y * 0.5 + 0.5;
    vec3 col;
    if (skyY > 0.6) {
        col = mix(skyMid, skyTop, (skyY - 0.6) / 0.4);
    } else if (skyY > 0.35) {
        col = mix(skyLow, skyMid, (skyY - 0.35) / 0.25);
    } else {
        col = mix(skyHorizon, skyLow, skyY / 0.35);
    }

    // Clouds like thoughts drifting
    vec2 cloudUV = duv * vec2(1.6, 3.0) + vec2(t * 0.012, 0.0);
    float clouds = fbm(cloudUV);
    clouds = smoothstep(0.42, 0.62, clouds);
    vec3 cloudColor = mix(vec3(1.0, 0.94, 0.88), vec3(0.88, 0.75, 0.62), skyY);
    col = mix(col, cloudColor, clouds * 0.28);

    // Soft sun glow behind
    vec2 sunPos = vec2(0.0, -0.25);
    float sunDist = length(duv - sunPos);
    float sunGlow = exp(-sunDist * 2.8) * 0.3;
    col += vec3(1.0, 0.9, 0.65) * sunGlow;

    // Stone - warm limestone touched by time
    vec3 stoneLight = vec3(0.96, 0.91, 0.82);
    vec3 stoneMid = vec3(0.84, 0.78, 0.7);
    vec3 stoneDark = vec3(0.56, 0.51, 0.46);

    if (d < 0.0) {
        float noise1 = sin(duv.x * 55.0 + t * 0.05) * sin(duv.y * 55.0 + t * 0.07) * 0.011;
        float noise2 = sin(duv.x * 28.0 + duv.y * 22.0) * 0.014;
        float gradient = duv.y * 0.22 + 0.5;

        col = mix(stoneLight, stoneMid, gradient + noise1 + noise2);

        // Warm light from the eternal sunset
        float lightDir = (duv.x + duv.y + 1.0) * 0.28;
        col = mix(col, col * vec3(1.08, 1.02, 0.94), clamp(lightDir, 0.0, 1.0) * 0.22);

        // Window recesses hold shadow
        if (d > -0.032 && d < -0.01) {
            col = mix(col, stoneDark * 0.72, 0.58);
        }

        float edgeDarkness = smoothstep(0.0, -0.055, d);
        col = mix(col, stoneDark * 0.68, edgeDarkness * 0.32);
    }

    // Rose window - the heart that glows
    vec2 archCenter = vec2(0.0, 0.15);
    float archDist = length(duv - archCenter);
    float archAngle = atan(duv.y - 0.15, duv.x);

    // Light emanates like grace
    if (d >= 0.0) {
        float rayIntensity = 0.0;
        for (float i = 0.0; i < 12.0; i++) {
            float rayAngle = i * 3.14159 / 6.0 + t * 0.05;
            float angleDiff = abs(mod(archAngle - rayAngle + 3.14159, 6.28318) - 3.14159);
            float rayWidth = 0.08 + 0.015 * sin(t * 0.5 + i * 0.5);
            float ray = smoothstep(rayWidth, 0.0, angleDiff);
            ray *= smoothstep(0.75, 0.25, archDist);
            ray *= smoothstep(0.22, 0.28, archDist);
            rayIntensity += ray;
        }
        float pulse = 0.88 + 0.12 * sin(t * 0.35);
        rayIntensity *= 0.07 * pulse;
        col += vec3(0.98, 0.9, 0.72) * rayIntensity;
    }

    // Soft halo
    float halo = smoothstep(0.35, 0.22, archDist);
    col += vec3(0.25, 0.28, 0.35) * halo * 0.18 * (0.92 + 0.08 * sin(t * 0.4));

    if (archDist < 0.23) {
        vec3 tracery = vec3(0.26, 0.23, 0.2);

        if (rose.a < 0.0) {
            col = tracery + 0.025 * sin(archDist * 16.0 + t * 0.25);
        } else {
            float glow = 0.92 + 0.08 * sin(t * 0.4 + archDist * 3.5);
            col = rose.rgb * glow;

            float sparkle = pow(0.5 + 0.5 * sin(archDist * 32.0 + t * 1.8), 4.0) * 0.12;
            col += vec3(sparkle) * vec3(1.0, 0.97, 0.92);
        }
    }

    // Edge definition
    float edge = smoothstep(0.011, 0.0, abs(d));
    col = mix(col, stoneDark * 0.48, edge * 0.65);

    // Water reflection - the mirror below
    if (isReflection) {
        vec3 waterColor = vec3(0.28, 0.35, 0.45);
        col = mix(waterColor, col * 0.65, 0.55);

        float rippleNoise = fbm(vec2(uv.x * 6.0 + t * 0.2, uv.y * 1.5));
        col *= 0.88 + 0.12 * rippleNoise;

        float fade = smoothstep(waterLine, waterLine - 0.45, uv.y);
        col = mix(waterColor * 0.75, col, 1.0 - fade * 0.45);
    } else {
        // Water's edge
        if (uv.y < waterLine + 0.015 && uv.y > waterLine - 0.015) {
            vec3 waterEdge = vec3(0.38, 0.45, 0.55);
            float edgeFactor = 1.0 - abs(uv.y - waterLine) / 0.015;
            col = mix(col, waterEdge, edgeFactor * 0.45);
        }
    }

    // Vignette - intimate, focused
    float vig = 1.0 - 0.26 * pow(length(uv * 0.48), 2.4);
    col *= vig;

    // Final color grading - warmth, peace, presence
    col = pow(col, vec3(0.94, 0.96, 0.99));
    col = col * 0.91 + 0.09 * col * col;

    fragColor = vec4(col, 1.0);
}
