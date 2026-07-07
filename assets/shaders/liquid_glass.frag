#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uRadius;
uniform float uTime;
uniform vec2 uPointer;   // pixel space
uniform float uStrength; // 0..1, how much glass vs plain blur
uniform float uBulge;    // edge lens width in px
uniform float uChroma;   // chromatic aberration px

uniform sampler2D uBackdrop;

out vec4 fragColor;

float sdRoundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 p = fragCoord - uSize * 0.5;
  vec2 halfSize = uSize * 0.5;

  float d = sdRoundBox(p, halfSize, uRadius);

  float e = 1.0;
  vec2 grad = vec2(
    sdRoundBox(p + vec2(e, 0.0), halfSize, uRadius) - sdRoundBox(p - vec2(e, 0.0), halfSize, uRadius),
    sdRoundBox(p + vec2(0.0, e), halfSize, uRadius) - sdRoundBox(p - vec2(0.0, e), halfSize, uRadius)
  );
  vec2 normal = grad / (length(grad) + 1e-5);

  float band = max(uBulge, 1.0);
  float edge = 1.0 - smoothstep(-band, 0.0, d);
  edge *= 1.0 - smoothstep(0.0, 3.0, d);
  float lens = edge * edge * uStrength;

  vec2 refracted = normal * lens * band * 0.9;
  float ca = lens * uChroma;

  vec2 uvR = (fragCoord + refracted + normal * ca) / uSize;
  vec2 uvG = (fragCoord + refracted) / uSize;
  vec2 uvB = (fragCoord + refracted - normal * ca) / uSize;

  float r = texture(uBackdrop, clamp(uvR, 0.0, 1.0)).r;
  float g = texture(uBackdrop, clamp(uvG, 0.0, 1.0)).g;
  float b = texture(uBackdrop, clamp(uvB, 0.0, 1.0)).b;
  vec3 col = vec3(r, g, b);

  vec2 pointerPx = uPointer;
  float distToPointer = length(fragCoord - pointerPx);
  float spec = exp(-(distToPointer * distToPointer) / (2.0 * 130.0 * 130.0)) * 0.30;

  float rimWave = 0.5 + 0.5 * sin(uTime * 1.6 + dot(normal, vec2(1.0, 0.35)) * 3.0);
  float rim = pow(edge, 1.6) * rimWave * 0.35;

  float top = smoothstep(0.0, uSize.y * 0.6, fragCoord.y);
  float sheen = (1.0 - top) * 0.10;

  col += vec3(1.0) * (spec + rim + sheen);
  col = mix(col, vec3(1.0), 0.03 * uStrength);

  fragColor = vec4(col, 1.0);
}
