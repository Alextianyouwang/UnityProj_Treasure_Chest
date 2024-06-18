Shader "Custom/Billboard"
{
    Properties
    {
        _Normal("Normal", 2D) = "bump"{}
        _Albedo("Albedo", 2D) = "Black"{}
        _ARMA("ARMA", 2D) = "black"{}
    }
        SubShader
    {
             Tags {"RenderType" = "Opaque""RenderPipeline" = "UniversalRenderPipeline"}
      Pass
        {
            Name "Billboard"
            Cull back
            ZWrite On
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
            

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "../INCLUDE/HL_ShadowHelper.hlsl"

            TEXTURE2D(_Normal); SAMPLER(sampler_Normal);
            TEXTURE2D(_Albedo); SAMPLER(sampler_Albedo);
            TEXTURE2D(_ARMA); SAMPLER(sampler_ARMA);

            struct Input 
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
            };

            struct Interpolator 
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD0;
                float3 positionWS : TEXCOORD1;

            };

            Interpolator vert(Input i)
            {
                Interpolator o;
                o.positionCS = mul(UNITY_MATRIX_MVP, float4(i.positionOS, 1));
                o.positionWS = mul(UNITY_MATRIX_M, float4(i.positionOS, 1));
                o.uv = i.uv;
                o.uv1 = i.uv1;

                return o;
            }

            float4 frag(Interpolator i) : SV_Target
            {

                float4 MADS = SAMPLE_TEXTURE2D(_ARMA, sampler_ARMA, i.uv);
        
                float4 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, i.uv);
                clip(albedo.z - 0.0001);
                float3 normalWS = SAMPLE_TEXTURE2D(_Normal, sampler_Normal, i.uv).xyz * 2 - 1;

                float3 posNDS = i.positionCS / i.positionCS.w;
                float2 uvSS = posNDS.xy / 2 + 0.5;

     

                InputData data = (InputData)0;

                data.positionWS = i.positionWS;
                data.positionCS = i.positionCS;
                data.normalWS = normalWS;
                data.viewDirectionWS = normalize(-_WorldSpaceCameraPos + i.positionWS);
                data.shadowCoord = CalculateShadowCoord(i.positionWS, i.positionCS);
                data.fogCoord = 0;
                data.vertexLighting = 0;
                data.bakedGI = 0;
                data.normalizedScreenSpaceUV = uvSS;
                data.shadowMask = 0;
 

                SurfaceData surf = (SurfaceData)0;


                surf.albedo = albedo.xyz;
                surf.specular = 0.5;
                surf.metallic = MADS.x;
                surf.smoothness = MADS.w;
                surf.normalTS = float3 (0.5, 0.5, 1);
                surf.emission = 0;
                surf.occlusion = MADS.y;
                surf.alpha = albedo.w;
                surf.clearCoatMask = 0;
                surf.clearCoatSmoothness = 0;


                float4 finalColor = UniversalFragmentPBR(data, surf);
   
                return finalColor;
            }
            ENDHLSL
        }
    }
}
