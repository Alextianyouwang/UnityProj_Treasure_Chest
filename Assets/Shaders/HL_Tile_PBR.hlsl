#ifndef TILE_PBR_INCLUDE
#define  TILE_PBR_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "../INCLUDE/HL_GraphicsHelper.hlsl"
#include "../INCLUDE/HL_Noise.hlsl"
#include "../INCLUDE/HL_ShadowHelper.hlsl"
#include "../INCLUDE/HL_Quaternion.hlsl"

struct VertexInput
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    
};
struct VertexOutput
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float3 groundNormalWS : TEXCOOR2;
    float4 tangentWS : TEXCOORD3;
    float3 positionWS : TEXCOORD4;
    float3 bakedGI : TEXCOORD8;
};
////////////////////////////////////////////////
// Spawn Data
struct SpawnData
{
    float3 positionWS;
    float hash;
    float4 clumpInfo;
    float4 postureData;
};
StructuredBuffer<SpawnData> _SpawnBuffer;
////////////////////////////////////////////////

////////////////////////////////////////////////
// Field Data
StructuredBuffer<float3> _GroundNormalBuffer;
StructuredBuffer<float3> _WindBuffer;
StructuredBuffer<float4> _MaskBuffer;
Texture2D<float> _InteractionTexture;
Texture2D<float4> _FlowTexture;
int _NumTilePerClusterSide;
float _ClusterBotLeftX, _ClusterBotLeftY, _TileSize;
////////////////////////////////////////////////

TEXTURE2D( _MainTex);SAMPLER (sampler_MainTex);float4 _MainTex_ST;
TEXTURE2D( _Normal);SAMPLER (sampler_Normal);float4 _Normal_ST;
TEXTURE2D( _Mask);SAMPLER (sampler_Mask);float4 _Mask_ST;

float _MasterScale;

VertexOutput vert(VertexInput v, uint instanceID : SV_INSTANCEID)
{
    VertexOutput o;
    
    ////////////////////////////////////////////////
    // Fetch Input
    float3 spawnPosWS = _SpawnBuffer[instanceID].positionWS;
    
    int x = (spawnPosWS.x - _ClusterBotLeftX) / _TileSize;
    int y = (spawnPosWS.z - _ClusterBotLeftY) / _TileSize;
    // Sample Buffers Based on xy
    float3 groundNormalWS = _GroundNormalBuffer[x * _NumTilePerClusterSide + y];
    float rand = _SpawnBuffer[instanceID].hash * 2 - 1; // [-1,1]
 
    float3 posOS = v.positionOS;
    float viewDist = length(_WorldSpaceCameraPos - spawnPosWS);
     ////////////////////////////////////////////////
   
    // Apply Transform

    float xRot = 15;
    float zRot = 15;
    float3 posWS = spawnPosWS + posOS * _MasterScale ;
    


    float3 normalWS = v.normalOS;
    float4 tangentWS = v.tangentOS;
    
    posWS = RotateAroundAxis(float4(posWS, 1), float3(0, 1, 0), rand * 360, spawnPosWS).xyz;
    normalWS = RotateAroundAxis(float4(normalWS, 0), float3(0, 1, 0), rand * 360).xyz;
    tangentWS.xyz = RotateAroundAxis(float4(tangentWS.xyz, 0), float3(0, 1, 0), rand * 360).xyz;
    
    AlignToGroundNormal(groundNormalWS,spawnPosWS, posWS, normalWS, tangentWS.xyz);
    
    posWS = RotateAroundAxis(float4(posWS, 1), float3(1, 0, 0), rand * xRot, spawnPosWS).xyz;
    posWS = RotateAroundAxis(float4(posWS, 1), float3(0, 0, 1), rand * zRot, spawnPosWS).xyz;
    
    normalWS = RotateAroundXInDegrees(float4(normalWS, 0),  rand * xRot).xyz;
    normalWS = RotateAroundYInDegrees(float4(normalWS, 0), rand * zRot).xyz;
    
    tangentWS.xyz = RotateAroundXInDegrees(float4(tangentWS.xyz, 0),  rand * xRot).xyz;
    tangentWS.xyz = RotateAroundYInDegrees(float4(tangentWS.xyz, 0), rand * zRot).xyz;
    
    
    
    
    ////////////////////////////////////////////////
    
    ////////////////////////////////////////////////
    // GI
    float2 lightmapUV;
    OUTPUT_LIGHTMAP_UV(v.uv1, unity_LightmapST, lightmapUV);
    float3 vertexSH;
      OUTPUT_SH(normalWS, vertexSH);
    ////////////////////////////////////////////////

    o.bakedGI = SAMPLE_GI(lightmapUV, vertexSH, normalWS);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.positionWS = posWS;
    o.normalWS = normalWS;
    o.tangentWS = tangentWS;
    o.groundNormalWS = groundNormalWS;

    #ifdef SHADOW_CASTER_PASS
        o.positionCS = CalculatePositionCSWithShadowCasterLogic(posWS,normalWS);
    #else
        o.positionCS = mul(UNITY_MATRIX_VP, float4(posWS, 1));
    #endif
    return o;
   
}

struct CustomInputData
{
    float3 normalWS;
    float3 groundNormalWS;
    float3 positionWS;
    float3 viewDir;
    float viewDist;
    
    float3 albedo;
    float3 specularColor;
    float smoothness;
    
    float3 sss;
    float sssTightness;

    float3 bakedGI;
    float4 shadowCoord;
};

float3 CustomLightHandling(CustomInputData d, Light l)
{
    float atten = lerp(l.shadowAttenuation, 1, smoothstep(20, 30, d.viewDist)) * l.distanceAttenuation;
    float diffuseGround = saturate(dot(l.direction, d.groundNormalWS));
    float3 sss = 0;
    FastSSS_float(d.viewDir, l.direction, d.groundNormalWS, l.color, 0, d.sssTightness, sss);
    return saturate(sss  * d.sss * atten);
}
float3 CustomCombineLight(CustomInputData d)
{
    Light mainLight = GetMainLight(d.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, d.normalWS, d.bakedGI);
    float3 color = d.bakedGI * d.albedo;
    color += CustomLightHandling(d, mainLight);
    uint numAdditionalLights = GetAdditionalLightsCount();
    for (uint lightI = 0; lightI < numAdditionalLights; lightI++)
        color += CustomLightHandling(d, GetAdditionalLight(lightI, d.positionWS, d.shadowCoord));
    return color;
}


float4 frag(VertexOutput v, bool frontFace : SV_IsFrontFace) : SV_Target
{
    float4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, v.uv);

    float3 normalWS = normalize(v.normalWS);
    float3 tangentWS = normalize(v.tangentWS.xyz);
    float3 bitangentWS = cross(normalWS, tangentWS);
    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, v.uv), 1 );
  

    float sgn =v.tangentWS.w; // should be either +1 or -1
    float3 bitangent = sgn * cross(v.normalWS.xyz, v.tangentWS.xyz);
    half3x3 tangentToWorld = half3x3(v.tangentWS.xyz, bitangent.xyz,v.normalWS.xyz);
    normalWS = mul(normalTS, tangentToWorld);
   
    float3 posNDS = v.positionCS / v.positionCS.w;
    float2 uvSS = posNDS.xy / 2 + 0.5;
    
    
    float4 MADS = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, v.uv);

    
    InputData data = (InputData) 0;
    
    data.positionWS = v.positionWS;
    data.positionCS = v.positionCS;
    data.normalWS = normalWS;
    data.viewDirectionWS = normalize(_WorldSpaceCameraPos - v.positionWS);
    data.shadowCoord = CalculateShadowCoord(v.positionWS, v.positionCS);
    data.fogCoord = 0;
    data.vertexLighting = 0;
    data.bakedGI = v.bakedGI;
    data.normalizedScreenSpaceUV = uvSS;
    data.shadowMask = 0;
    data.tangentToWorld = tangentToWorld;
    
    SurfaceData surf = (SurfaceData) 0;
    
    
    surf.albedo = albedo.xyz;
    surf.specular = 1;
    surf.metallic = MADS.x;
    surf.smoothness =MADS.w;
    surf.normalTS = normalTS;
    surf.emission = 0;
    surf.occlusion = 0;
    surf.alpha = albedo.w;
    surf.clearCoatMask = 0;
    surf.clearCoatSmoothness = 0;
    
    //float3 customSSS = CustomCombineLight(d);
    
    float4 finalColor =  UniversalFragmentPBR(data, surf);
    //finalColor.xyz += customSSS;
    return finalColor;

   
}

#endif