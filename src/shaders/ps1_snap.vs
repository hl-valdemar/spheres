#version 330

in vec3 vertexPosition;
in vec3 vertexNormal;

uniform mat4 mvp;
uniform mat4 matModel;
uniform vec2 snapResolution;
uniform vec3 lightDirection;
uniform vec4 baseColor;
uniform vec3 cameraPosition;
uniform float fogStart;
uniform float fogEnd;
uniform float ambientStrength;

out vec4 fragColor;
out float fogVisibility;

void main()
{
    vec4 clip = mvp * vec4(vertexPosition, 1.0);
    vec3 ndc = clip.xyz / clip.w;
    vec2 halfResolution = snapResolution * 0.5;

    ndc.xy = floor(ndc.xy * halfResolution + 0.5) / halfResolution;

    gl_Position = vec4(ndc * clip.w, clip.w);

    vec3 normal = normalize(mat3(matModel) * vertexNormal);
    float diffuse = max(dot(normal, normalize(lightDirection)), 0.0);
    float light = clamp(ambientStrength + diffuse * (1.0 - ambientStrength), 0.0, 1.0);

    fragColor = vec4(baseColor.rgb * light, baseColor.a);

    vec3 worldPosition = (matModel * vec4(vertexPosition, 1.0)).xyz;
    float cameraDistance = distance(worldPosition, cameraPosition);
    float linearFogVisibility = clamp((fogEnd - cameraDistance) / (fogEnd - fogStart), 0.0, 1.0);
    fogVisibility = smoothstep(0.0, 1.0, linearFogVisibility);
}
