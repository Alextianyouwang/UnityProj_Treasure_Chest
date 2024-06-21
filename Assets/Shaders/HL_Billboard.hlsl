#ifndef BILLBOARD_INCLUDE
#define BILLBOARD_INCLUDE


  #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../INCLUDE/HL_ShadowHelper.hlsl"
            #include "../INCLUDE/HL_Quaternion.hlsl"

            TEXTURE2D(_Normal); SAMPLER(sampler_Normal);
            TEXTURE2D(_Albedo); SAMPLER(sampler_Albedo);
            TEXTURE2D(_ARMA); SAMPLER(sampler_ARMA);

struct Input
{
    float3 positionOS : POSITION;
    
    float2 uv : TEXCOORD0;
    
};

struct Interpolator
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD2;

};

Interpolator vert(Input i)
{
    Interpolator o;

    o.positionWS = mul(UNITY_MATRIX_M, float4(i.positionOS, 1));
    o.uv = i.uv;
    
#ifdef SHADOW_CASTER_PASS
        o.positionCS = CalculatePositionCSWithShadowCasterLogic( o.positionWS , float3 (0,0,1));
#else
        o.positionCS = mul(UNITY_MATRIX_MVP, float4(i.positionOS, 1));
#endif
    return o;
}

float4 frag(Interpolator i) : SV_Target
{
    float4 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, i.uv);
    clip(albedo.z - 0.0001);
    #ifdef SHADOW_CASTER_PASS
        
    clip(albedo.z - 0.0001);
    return 0;
    #else

    float4 MADS = SAMPLE_TEXTURE2D(_ARMA, sampler_ARMA, i.uv);
        

    float3 normalOS = SAMPLE_TEXTURE2D(_Normal, sampler_Normal, i.uv).xyz * 2 - 1;
    normalOS = -mul(UNITY_MATRIX_V, float4(normalOS, 0));
    normalOS.y = -normalOS.y;


    float3 vertexSH;
    OUTPUT_SH(normalOS, vertexSH);
    
    InputData data = (InputData) 0;

    data.positionWS = i.positionWS;
    data.positionCS = i.positionCS;
    data.normalWS = normalize(normalOS);
    data.viewDirectionWS = normalize(_WorldSpaceCameraPos - i.positionWS);
    data.shadowCoord = CalculateShadowCoord(i.positionWS, i.positionCS);

    SurfaceData surf = (SurfaceData) 0;

    surf.albedo = albedo.xyz;
    surf.metallic = MADS.x;
    surf.smoothness = MADS.w;
    surf.occlusion = MADS.y;
    surf.alpha = albedo.w;

    float4 finalColor = UniversalFragmentPBR(data, surf);

    return finalColor;
    
    #endif
}
#endif