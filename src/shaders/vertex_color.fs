#version 330

in vec4 fragColor;
in float fogVisibility;

uniform vec4 fogColor;
uniform int colorLevels;
uniform float ditherStrength;

out vec4 finalColor;

float bayer4Threshold(vec2 position)
{
    int x = int(mod(position.x, 4.0));
    int y = int(mod(position.y, 4.0));
    int index = y * 4 + x;
    float matrix[16] = float[16](
         0.0,  8.0,  2.0, 10.0,
        12.0,  4.0, 14.0,  6.0,
         3.0, 11.0,  1.0,  9.0,
        15.0,  7.0, 13.0,  5.0
    );

    return (matrix[index] + 0.5) / 16.0;
}

void main()
{
    float farCoverage = smoothstep(0.0, 0.28, fogVisibility);
    if (farCoverage < bayer4Threshold(gl_FragCoord.xy)) discard;

    float levels = max(float(colorLevels), 2.0);
    float quantStep = 1.0 / (levels - 1.0);
    float fogDither = ditherStrength * smoothstep(0.18, 0.55, fogVisibility);
    float dither = (bayer4Threshold(gl_FragCoord.xy) - 0.5) * quantStep * fogDither;
    vec3 fogged = mix(fogColor.rgb, fragColor.rgb, fogVisibility);
    vec3 dithered = clamp(fogged + vec3(dither), 0.0, 1.0);
    vec3 rgb = floor(dithered * (levels - 1.0) + 0.5) / (levels - 1.0);

    finalColor = vec4(rgb, fragColor.a);
}
