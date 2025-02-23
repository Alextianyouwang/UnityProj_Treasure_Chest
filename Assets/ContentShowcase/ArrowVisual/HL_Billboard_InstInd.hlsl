#ifndef BILLBOARD_INST_IND_INCLUDED
#define  BILLBOARD_INST_IND_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "../../INCLUDE/HL_GraphicsHelper.hlsl"
#include "../../INCLUDE/HL_Noise.hlsl"
#include "../../INCLUDE/HL_ShadowHelper.hlsl"

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
    float3 forwardWS : TEXCOORD1;
};

TEXTURE2D( _MainTex);SAMPLER (sampler_MainTex);float4 _MainTex_ST;

float _MasterScale;
float _ViewNormalBlend;

struct SpawnData
{
    float3 positionWS;
    float hash;
    float4 clumpInfo;
    float4 postureData;
};
StructuredBuffer<SpawnData> _SpawnBuffer;

  
int _NumTilePerClusterSide;
float _ClusterBotLeftX, _ClusterBotLeftY, _TileSize;
StructuredBuffer<float3> _GroundNormalBuffer;
StructuredBuffer<float3> _WindBuffer;
StructuredBuffer<float4> _MaskBuffer;
Texture2D<float> _InteractionTexture;
Texture2D<float4> _FlowTexture;

VertexOutput vert(VertexInput v, uint instanceID : SV_InstanceID)
{
    VertexOutput o;
    
    float3 spawnPosWS = _SpawnBuffer[instanceID].positionWS;
    
    int x = (spawnPosWS.x - _ClusterBotLeftX) / _TileSize;
    int y = (spawnPosWS.z - _ClusterBotLeftY) / _TileSize;
    float3 groundNormalWS = _GroundNormalBuffer[x * _NumTilePerClusterSide + y];
    float3 spawnDir = normalize( groundNormalWS);
    float length = distance(float2(spawnDir.x, spawnDir.z),0);
    float3 posOS = v.positionOS * length * 1.5 ;
    float3 viewDirectionWS = normalize(_WorldSpaceCameraPos - spawnPosWS);
    //viewDirectionWS.y = -viewDirectionWS.y;
    float3 newSpawnDir = lerp(normalize(spawnDir), viewDirectionWS, _ViewNormalBlend);
    
    posOS = TransformWithAlignment(float4(posOS, 1), float3(0, 1, 0),normalize(spawnDir));
    
    posOS = lerp( posOS,TransformWithAlignment(float4(posOS, 1), float3(0, 0, 1), viewDirectionWS).xyz,_ViewNormalBlend);
    
    
    //posOS = lerp(posOS, mul(UNITY_MATRIX_V, float4(posOS, 1)), _ViewNormalBlend);

    
    float3 posWS = spawnPosWS + posOS * _MasterScale;
    
 
        
   //normalOS = -mul(UNITY_MATRIX_V, float4(normalOS, 0));

    

    
    o.positionCS = mul(UNITY_MATRIX_VP, float4(posWS, 1));
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.forwardWS = newSpawnDir;
    return o;
}

half4 frag(VertexOutput v, bool frontFace : SV_IsFrontFace) : SV_Target
{
    
    half2 uv = v.uv;
    return v.forwardWS.xyzz ;
    
    half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
    clip(albedo.a  -  0.5);
   
    return half4(uv, 0, 1);
   
}

#endif