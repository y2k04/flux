#define PI 3.1415926535897932384626433832795

precision highp float;
precision highp sampler2D;

// static input
in vec2 basepoint;

// dynamic input
in vec2 iEndpointVector;
in vec2 iVelocityVector;
in vec4 iColor;
in float iLineWidth;
in float iOpacity;

uniform float deltaT;
uniform float uSpringStiffness;
uniform float uSpringVariance;
uniform float uSpringMass;
uniform float uSpringRestLength;
uniform float uLineFadeOutLength;
uniform float uMaxLineVelocity;
uniform float uAdjustAdvection;
uniform float uAdvectionDirection;
uniform mediump vec4 uColorWheel[6];
uniform mat4 uProjection;

uniform sampler2D velocityTexture;

// transform feedback output
out vec2 vEndpointVector;
out vec2 vVelocityVector;
out vec4 vColor;
out float vLineWidth;
out float vOpacity;


float clampTo(float value, float max) {
  float current = value + 0.0001;
  return min(current, max) / current;
}

vec3 getColor(vec4 wheel[6], float angle) {
  float slice = 2.0 * PI / 6.0;
  float rawIndex = angle / slice;
  float index = floor(rawIndex);
  float nextIndex = mod(index + 1.0, 6.0);
  float interpolate = fract(rawIndex);

  vec3 currentColor = wheel[int(index)].rgb;
  vec3 nextColor = wheel[int(nextIndex)].rgb;
  return mix(currentColor, nextColor, interpolate);
}

float springForce(float stiffness, float mass, float displacement) {
  return (-stiffness * displacement) / mass;
}

float random1f(in vec2 st) {
  return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float easeInCirc(float x) {
  return 1.0 - sqrt(1.0 - pow(x, 2.0));
}

void main() {
  // Velocity
  vec2 basepointInClipSpace = (uProjection * vec4(basepoint, 0.0, 1.0)).xy;
  vec2 currentVelocityVector = texture(velocityTexture, basepointInClipSpace * 0.5 + 0.5).xy;
  vec2 deltaVelocity = currentVelocityVector - iVelocityVector;

  float mass = uSpringMass * (1.0 + uSpringVariance * random1f(basepoint));
  vVelocityVector = iVelocityVector + (deltaVelocity / mass) * deltaT;

  // Spring forces
  float currentLength = length(iEndpointVector);
  vec2 direction;
  if (currentLength == 0.0) {
    direction = vec2(0.0);
  } else {
    direction = normalize(iEndpointVector);
  }

  // Main spring
  vVelocityVector += uAdvectionDirection * springForce(
    uSpringStiffness,
    mass,
    currentLength - uSpringRestLength
  ) * direction * deltaT;

  // Cap line velocity
  vVelocityVector *= clampTo(length(vVelocityVector), uMaxLineVelocity);

  // Advect forward
  vEndpointVector = iEndpointVector + uAdjustAdvection * uAdvectionDirection * vVelocityVector * deltaT;
  currentLength = length(vEndpointVector);

  // Color
  float angle = mod(
    PI / 6.0 * currentLength + (PI + atan(iEndpointVector.y, iEndpointVector.x)),
    2.0 * PI
  );
  vec4 newColor = vec4(getColor(uColorWheel, angle), 0.0);
  vec4 colorDiff = newColor - iColor;
  vColor = clamp(
    iColor + colorDiff * deltaT,
    vec4(0.0),
    vec4(1.0)
  );
  // Debug spring extension
  // vColor = mix(vColor, vec4(1.0), smoothstep(0.95, 1.05, currentLength));

  // Width
  vec2 velocityDirection = normalize(uAdvectionDirection * vVelocityVector);
  vec2 lineDirection = normalize(vEndpointVector);
  float directionAlignment = clamp(dot(lineDirection, velocityDirection), -1.0, 1.0);

  float clampedLength = clamp(currentLength, 0.0, 1.0);
  vLineWidth = clamp(
    iLineWidth + (1.0 - easeInCirc(clampedLength)) * 1.35 *  uAdjustAdvection * directionAlignment * length(vVelocityVector) * deltaT,
    0.0,
    1.0
  );

  // Opacity
  // This is only for the line. The endpoints have their own fade out curve.
  // TODO can we improve this?
  vOpacity = smoothstep(uLineFadeOutLength, 0.7, currentLength);
}
