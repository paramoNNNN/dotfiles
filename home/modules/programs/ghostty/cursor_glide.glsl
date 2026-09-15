// Source: https://gist.github.com/thdxg/e43956748b9f685492011c2e8754080d
// the cursor itself glides between cells instead of jumping.
// Unlike a trail shader, this one is the focused cursor, so it
// requires ghostty's own cursor to be hidden:
//
//     cursor-opacity = 0
//     cursor-text = cell-foreground
//     alpha-blending = linear-corrected
//     custom-shader  = "./shaders/cursor_glide.glsl"
// Do not enable cursor-invert-fg-bg: it hides the glyph before this shader runs.
// Native blending on macOS is incompatible with the linear color math below
// and can produce invalid pixels when rendering a cursor with zero alpha.


// --- CONFIGURATION ---
const float DURATION   = 0.14;  // seconds for one glide
const float AA         = 1.0;   // edge antialiasing in pixels

// Invert in sRGB, then return to the texture's linear color space.
vec3 sRGBToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 linearToSRGB(vec3 c) {
    return mix(12.92 * c, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055,
               step(vec3(0.0031308), c));
}

// EaseOutCubic — swap for any of the curves in cursor_sweep.glsl.
float ease(float x) {
    return 1.0 - pow(1.0 - x, 3.0);
}

float sdfRect(vec2 p, vec2 center, vec2 halfSize) {
    vec2 d = abs(p - center) - halfSize;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// iCurrentCursor/iPreviousCursor are (left, top-edge, width, height) in
// pixels with shadertoy's y-up convention: the rect spans [y - h, y].
vec2 rectCenter(vec4 r) {
    return vec2(r.x + r.z * 0.5, r.y - r.w * 0.5);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 tex = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = tex;

    if (iCursorVisible == 0 || iFocus == 0) return;
    if (iCurrentCursorStyle == CURSORSTYLE_BLOCK_HOLLOW ||
        iCurrentCursorStyle == CURSORSTYLE_LOCK) return;

    vec4 cur  = iCurrentCursor;
    vec4 prev = iPreviousCursor;
    // An all-zero previous cursor is the first frame after launch; don't
    // glide in from the window corner.
    if (dot(prev.zw, prev.zw) == 0.0) prev = cur;

    float t = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
    float e = ease(t);

    vec2 center   = mix(rectCenter(prev), rectCenter(cur), e);
    vec2 halfSize = mix(prev.zw, cur.zw, e) * 0.5;

    float coverage = 1.0 - smoothstep(0.0, AA, sdfRect(fragCoord, center, halfSize));
    if (coverage <= 0.0) return;

    // Preserve the actual pixels instead of guessing which ones are glyphs.
    // Vim visual selections and floating windows can use arbitrary backgrounds.
    // Inverting every pixel preserves their text, including while gliding.
    vec3 pixel = clamp(tex.rgb / max(tex.a, 0.001), 0.0, 1.0);
    vec3 inverted = sRGBToLinear(vec3(1.0) - linearToSRGB(pixel));
    vec4 cursorPixel = vec4(inverted, 1.0);

    fragColor = mix(tex, cursorPixel, coverage);
}
