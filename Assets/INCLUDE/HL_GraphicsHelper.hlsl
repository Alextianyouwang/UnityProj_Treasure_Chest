#ifndef GRAPHIC_HELPER_INCLUDE
#define GRAPHIC_HELPER_INCLUDE

#ifndef UNITY_PI
#define UNITY_PI 3.1415926535
#endif
// github.com/GarrettGunnell/Grass/blob/main/Assets/Shaders/ModelGrass.shader
float4 RotateAroundYInDegrees(float4 vertex, float degrees)
{
    float alpha = degrees * UNITY_PI / 180.0;
    float sina, cosa;
    sincos(alpha, sina, cosa);
    float2x2 m = float2x2(cosa, -sina, sina, cosa);
    return float4(mul(m, vertex.xz), vertex.yw).xzyw;
}
float4 RotateAroundXInDegrees(float4 vertex, float degrees)
{
    float alpha = degrees * UNITY_PI / 180.0;
    float sina, cosa;
    sincos(alpha, sina, cosa);
    float2x2 m = float2x2(cosa, -sina, sina, cosa);
    return float4(mul(m, vertex.yz), vertex.xw).zxyw;
}

float4 RotateAroundAxis(float4 vertex, float3 axis, float angle)
{
    float radians = angle * UNITY_PI / 180.0;
    float sina, cosa;
    sincos(radians, sina, cosa);

    // Rodrigues' rotation formula
    float3 rotatedVertex = vertex.xyz * cosa +
                           cross(axis, vertex.xyz) * sina +
                           axis * dot(axis, vertex.xyz) * (1 - cosa);

    return float4(rotatedVertex, vertex.w);
}
float4 RotateAroundAxis(float4 vertex, float3 axis, float angle, float3 center)
{

    float3 translatedVertex = vertex.xyz - center;
    float radians = angle * UNITY_PI / 180.0;
    float sina, cosa;
    sincos(radians, sina, cosa);
    
    float3 rotatedTranslatedVertex = translatedVertex * cosa +
                                     cross(axis, translatedVertex) * sina +
                                     axis * dot(axis, translatedVertex) * (1 - cosa);

    float3 rotatedVertex = rotatedTranslatedVertex + center;
    return float4(rotatedVertex, vertex.w);
}

float2 Rotate2D(float2 uv, float angle)
{
    float alpha = angle * UNITY_PI / 180.0;
    float sina, cosa;
    sincos(alpha, sina, cosa);
    float2x2 m = float2x2(cosa, -sina, sina, cosa);
    return mul(m, uv);

}

void CubicBezierCurve(float3 P0, float3 P1, float3 P2, float3 P3, float t, out float3 pos, out float3 tangent)
{
    float t2 = t * t;
    float t3 = t * t * t;
    float4x3 input =
    {
        P0.x, P0.y, P0.z,
        P1.x, P1.y, P1.z,
        P2.x, P2.y, P2.z,
        P3.x, P3.y, P3.z
    };

    float1x4 bernstein =
    {
         1 - 3 * t + 3 * t2 - 3 * t3,
         3 * t - 6 * t2 + 3 * t3,
         3 * t2 - 3 * t3,
         t3
    };

    float1x4 d_bernstein =
    {
        -3 + 6 * t - 9 * t2,
        3 - 12 * t + 9 * t2,
        6 * t - 9 * t2,
        3 * t2
    };
    pos = mul(bernstein, input);
    tangent = mul(d_bernstein, input);
}
void CubicBezierCurve_Tilt_Bend(float3 P2, float3 P3, float t, out float3 pos, out float3 tangent)
{
    float t2 = t * t;
    float t3 = t * t * t;
    float1x2 bernstein =
    {
         3 * t2 - 3 * t3,
         t3
    };

    float2x3 input =
    {
        P2.x, P2.y, P2.z,
        P3.x, P3.y, P3.z
    };


    float1x2 d_bernstein =
    {
        6 * t - 9 * t2,
        3 * t2
    };
    pos = mul(bernstein, input);
    tangent = mul(d_bernstein, input);
}

float3 ScaleWithCenter(float3 pos,float scale, float3 center)
{
    pos -= center;
    pos *= scale;
    pos += center;
    return pos;
}
float3 ScaleWithCenter(float3 pos, float3 scale, float3 center)
{
    pos -= center;
    pos.x *= scale.x;
    pos.y *= scale.y;
    pos.z *= scale.z;
    pos += center;
    return pos;
}
float3 ProjectOntoPlane(float3 v, float3 planeNormal)
{
    return v - dot(v, normalize(planeNormal)) * planeNormal;
}
//gist.github.com/outsidecontext/6083f490d4bd56b3e34b7893e6a34480
float4 slerp(float4 v0, float4 v1, float t)
{
    
    // Compute the cosine of the angle between the two vectors.
    float d = dot(v0, v1);

    const float DOT_THRESHOLD = 0.9995;
    if (abs(d) > DOT_THRESHOLD)
    {
        // If the inputs are too close for comfort, linearly interpolate
        // and normalize the result.
        float4 result = v0 + t * (v1 - v0);
        normalize(result);
        return result;
    }

    // If the dot product is negative, the quaternions
    // have opposite handed-ness and slerp won't take
    // the shorter path. Fix by reversing one quaternion.
    if (d < 0.0f)
    {
        v1 = -v1;
        d = -d;
    }

    clamp(d, -1, 1); // Robustness: Stay within domain of acos()
    float theta_0 = acos(d); // theta_0 = angle between input vectors
    float theta = theta_0 * t; // theta = angle between v0 and result 

    float4 v2 = v1 - v0 * d;
    normalize(v2); // { v0, v2 } is now an orthonormal basis

    return v0 * cos(theta) + v2 * sin(theta);
}
void FastSSS_float(float3 ViewDir, float3 LightDir, float3 WorldNormal, float3 LightColor, float Flood, float Power, out float3 sss)
{
    const float3 LAddN = LightDir + WorldNormal;
    sss = saturate(pow(saturate(dot(-LAddN, -LAddN * Flood + ViewDir)), Power)) * LightColor;
    
}
// Function to create a rotation matrix that aligns the world up vector with the given ground normal
float3x3 CreateAlignmentMatrix(float3 groundNormal)
{
    // World up vector
    float3 up = float3(0, 1, 0);
    
    // If the ground normal is nearly equal to the up vector, no rotation is needed
    if (abs(dot(up, groundNormal)) > 0.999f)
    {
        return float3x3(1.0, 0.0, 0.0,
                        0.0, 1.0, 0.0,
                        0.0, 0.0, 1.0);
    }

    // Calculate the axis of rotation (cross product)
    float3 axis = normalize(cross(up, groundNormal));

    // Calculate the angle between the up vector and the ground normal
    float angle = acos(dot(up, groundNormal));

    // Compute the components of the rotation matrix using axis-angle representation
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    float oneMinusCos = 1.0 - cosAngle;

    float3x3 rotationMatrix = float3x3(
        cosAngle + axis.x * axis.x * oneMinusCos,
        axis.x * axis.y * oneMinusCos - axis.z * sinAngle,
        axis.x * axis.z * oneMinusCos + axis.y * sinAngle,

        axis.y * axis.x * oneMinusCos + axis.z * sinAngle,
        cosAngle + axis.y * axis.y * oneMinusCos,
        axis.y * axis.z * oneMinusCos - axis.x * sinAngle,

        axis.z * axis.x * oneMinusCos - axis.y * sinAngle,
        axis.z * axis.y * oneMinusCos + axis.x * sinAngle,
        cosAngle + axis.z * axis.z * oneMinusCos
    );

    return rotationMatrix;
}

// Function to align an object's position, normal, and tangent to the ground normal
void AlignToGroundNormal(float3 groundNormal, float3 pivot, inout float3 position, inout float3 normal, inout float3 tangent)
{
    // Create the alignment matrix
    float3x3 alignmentMatrix = CreateAlignmentMatrix(groundNormal);

    // Rotate the position around the pivot
    float3 relativePosition = position - pivot;
    relativePosition = mul(alignmentMatrix, relativePosition);
    position = relativePosition + pivot;

    // Apply the alignment matrix to the normal and tangent
    normal = mul(alignmentMatrix, normal);
    tangent = mul(alignmentMatrix, tangent);
}
#endif