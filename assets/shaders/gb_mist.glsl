extern float time;
extern float white_amount;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    local = local * local * (3.0 - 2.0 * local);

    float bottom = mix(hash(cell), hash(cell + vec2(1.0, 0.0)), local.x);
    float top = mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), local.x);
    return mix(bottom, top, local.y);
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    vec2 position = screen_coords * 0.012;
    vec2 scroll = vec2(time * 0.70, time * 0.34);
    float mist = noise(position + scroll);
    mist = mix(mist, noise(position * 2.1 - scroll * 0.65), 0.45);
    mist = smoothstep(0.18, 0.88, mist);

    vec3 dark_blue = vec3(0.008, 0.025, 0.10);
    vec3 mist_blue = vec3(0.025, 0.10, 0.30);
    vec3 mist_color = mix(dark_blue, mist_blue, mist);
    vec3 output_color = mix(mist_color, vec3(1.0), clamp(white_amount, 0.0, 1.0));

    return vec4(output_color, color.a);
}
