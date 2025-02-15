#ifndef UTILITY
#define UTILITY
#ifndef PI
#define PI 3.14159265359f
#endif
//#include "UnityCG.cginc"
float ConvertDegToRad(float degrees)
{
    return PI / (float) 180 * degrees;
}
float4 RotationFromAToB(float3 A, float3 B)
{
    float3 normA = normalize(A);
    float3 normB = normalize(B);
    float3 axis = cross(normA, normB);
    float dotProduct = dot(normA, normB);
    float angle = acos(dotProduct);
    float4 q;
    q.xyz = axis * sin(angle / 2.0f);
    q.w = cos(angle / 2.0f);
    return q;
}

float3 RotateVectorByQuaternion(float4 rotation, float3 v)
{
    float3 q = 2.0 * cross(rotation.xyz, v);
    return v + rotation.w * q + cross(rotation.xyz, q);
}
float3 RotateVector(float3 vec, float3 originalUp, float3 targetUp )
{
    return RotateVectorByQuaternion(RotationFromAToB(originalUp,targetUp),vec);
}
float3 QuaternionToEuler(float4 q)
{
    float3 euler;
    
    float sqw = q.w*q.w;
    float sqx = q.x*q.x;
    float sqy = q.y*q.y;
    float sqz = q.z*q.z;

    euler.x = atan2(2 * (q.y*q.z + q.x*q.w),(-sqx - sqy + sqz + sqw));
    euler.y = asin(-2 * (q.x*q.z - q.y*q.w));
    euler.z = atan2(2 * (q.x*q.y + q.z*q.w),(sqx - sqy - sqz + sqw));

    return euler;
}

float2x2 UVRotMatrix (float angle)
{
    return float2x2(float2(cos(angle), sin(angle)),float2(-sin(angle), cos(angle))); 
} 
float4x4 GetRotationMatrix(float3 anglesDeg)
{
    //anglesDeg = float3(ConvertDegToRad(anglesDeg.x), ConvertDegToRad(anglesDeg.y), ConvertDegToRad(anglesDeg.z));

    float4x4 rotationX = float4x4(float4(1, 0, 0, 0), 
                                        float4(0, cos(anglesDeg.x), sin(anglesDeg.x), 0), 
                                        float4(0, -sin(anglesDeg.x), cos(anglesDeg.x), 0),
                                        float4(0, 0, 0, 1));

    float4x4 rotationY = float4x4(float4(cos(anglesDeg.y), 0, -sin(anglesDeg.y), 0),
                                        float4(0, 1, 0, 0),
                                        float4(sin(anglesDeg.y), 0, cos(anglesDeg.y), 0),
                                        float4(0, 0, 0, 1));

    float4x4 rotationZ = float4x4(float4(cos(anglesDeg.z), sin(anglesDeg.z), 0, 0),
                                        float4(-sin(anglesDeg.z), cos(anglesDeg.z), 0, 0),
                                        float4(0, 0, 1, 0),
                                        float4(0, 0, 0, 1));

    return rotationX * rotationY * rotationZ;
}
float Random (float2 uv)
{
    return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123) * 2 -1;
}
void Refraction_float(float3 viewDir, float3 normal, float refractionIndex,out float3 refractedNormal)
{
    float cosi = dot(-viewDir, normal);
    float cost2 = 1.0f - refractionIndex * refractionIndex * (1.0f - cosi*cosi);
    float3 t = refractionIndex*viewDir + ((refractionIndex*cosi - sqrt(abs(cost2))) * normal);
    refractedNormal=  t * (float3)(cost2 > 0);
}
float3 ReorientNormal(in float3 u, in float3 t, in float3 s)
{
    // Build the shortest-arc quaternion
    float4 q = float4(cross(s, t), dot(s, t) + 1) / sqrt(2 * (dot(s, t) + 1));
 
    // Rotate the normal
    return u * (q.w * q.w - dot(q.xyz, q.xyz)) + 2 * q.xyz * dot(q.xyz, u) + 2 * q.w * cross(q.xyz, u);
}
// Unity URP Nodes Example Code.
float3 TransformObjectToWorld(float3 positionOS)
{
    return mul(UNITY_MATRIX_M, float4(positionOS, 1.0)).xyz;
}
float3 TransformWorldToTangent(float3 dirWS, float3x3 worldToTangent)
{
    return mul(worldToTangent, dirWS);
}
void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
{
    Out = (In.rg * Strength, lerp(1, In.b, saturate(Strength)));
}
void Unity_NormalBlend_float(float3 A, float3 B, out float3 Out)
{
    Out = normalize(float3(A.rg + B.rg, A.b * B.b));
}

void Unity_Remap_float4(float4 In, float2 InMinMax, float2 OutMinMax, out float4 Out)
{
    Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
}
float2 unity_gradientNoise_dir(float2 p)
{
    p = p % 289;
    float x = (34 * p.x + 1) * p.x % 289 + p.y;
    x = (34 * x + 1) * x % 289;
    x = frac(x / 41) * 2 - 1;
    return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}
float unity_gradientNoise(float2 p)
{
    float2 ip = floor(p);
    float2 fp = frac(p);
    float d00 = dot(unity_gradientNoise_dir(ip), fp);
    float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
    float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
    float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
    fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
    return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
}
void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
{
    Out = unity_gradientNoise(UV * Scale) + 0.5;
}
void Unity_NormalBlend_Reoriented_float(float3 A, float3 B, out float3 Out)
{
    float3 t = A.xyz + float3(0.0, 0.0, 1.0);
    float3 u = B.xyz * float3(-1.0, -1.0, 1.0);
    Out = (t / t.z) * dot(t, u) - u;
}

float3 blend_unity(float4 n1, float4 n2)

{
    n1 = n1.xyzz*float4(2, 2, 2, -2) + float4(-1, -1, -1, 1);

    n2 = n2*2 - 1;

    float3 r;

    r.x = dot(n1.zxx,  n2.xyz);

    r.y = dot(n1.yzy,  n2.xyz);

    r.z = dot(n1.xyw, -n2.xyz);

    return normalize(r);
}

inline float2 unity_voronoi_noise_randomVector (float2 UV, float offset)
{
    float2x2 m = float2x2(15.27, 47.63, 99.41, 89.98);
    UV = frac(sin(mul(UV, m)) * 46839.32);
    return float2(sin(UV.y*+offset)*0.5+0.5, cos(UV.x*offset)*0.5+0.5);
}

void Unity_Voronoi_float(float2 UV, float AngleOffset, float CellDensity, out float Out, out float Cells)
{
    float2 g = floor(UV * CellDensity);
    float2 f = frac(UV * CellDensity);
    float t = 8.0;
    float3 res = float3(8.0, 0.0, 0.0);

    for(int y=-1; y<=1; y++)
    {
        for(int x=-1; x<=1; x++)
        {
            float2 lattice = float2(x,y);
            float2 offset = unity_voronoi_noise_randomVector(lattice + g, AngleOffset);
            float d = distance(lattice + offset, f);
            if(d < res.x)
            {
                res = float3(d, offset.x, offset.y);
                Out = res.x;
                Cells = res.y;
            }
        }
    }
}
#endif