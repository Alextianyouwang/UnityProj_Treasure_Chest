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
        #include "../INCLUDE/HL_Quaternion.hlsl"
        #ifndef UNITY_PI
#define UNITY_PI 3.1415926535
#endif
            TEXTURE2D(_Normal); SAMPLER(sampler_Normal);
            TEXTURE2D(_Albedo); SAMPLER(sampler_Albedo);
            TEXTURE2D(_ARMA); SAMPLER(sampler_ARMA);
            float4 RotateAroundYInDegrees(float4 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float4(mul(m, vertex.xz), vertex.yw).xzyw;
            }
            struct Input 
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 normalOS : NORMAL;
            };

            struct Interpolator 
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;

            };

            Interpolator vert(Input i)
            {
                Interpolator o;
                o.positionCS = mul(UNITY_MATRIX_MVP, float4(i.positionOS, 1));
                o.positionWS = mul(UNITY_MATRIX_M, float4(i.positionOS, 1));
                o.normalWS = mul(UNITY_MATRIX_M, float4(i.normalOS, 0));
                o.uv = i.uv;
                o.uv1 = i.uv1;

                return o;
            }

            float4 frag(Interpolator i) : SV_Target
            {

                float4 MADS = SAMPLE_TEXTURE2D(_ARMA, sampler_ARMA, i.uv);
        
                float4 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, i.uv);
                clip(albedo.z - 0.0001);

                float3 objectWorldPosition = unity_ObjectToWorld._m03_m13_m23;
                float3 camDirection  = UNITY_MATRIX_IT_MV[2].xyz;
                float3 normalOS = SAMPLE_TEXTURE2D(_Normal, sampler_Normal, i.uv).xyz * 2 - 1;
                float4 fromToRot = from_to_rotation(float3 (0, 0, 1), camDirection);
                normalOS = -rotate_vector(normalOS, fromToRot);
                float3 posNDS = i.positionCS / i.positionCS.w;
                float2 uvSS = posNDS.xy / 2 + 0.5;

     

                InputData data = (InputData)0;

                data.positionWS = i.positionWS;
                data.positionCS = i.positionCS;
                data.normalWS = normalize(normalOS);
                data.viewDirectionWS = normalize(_WorldSpaceCameraPos - i.positionWS);
                data.shadowCoord = CalculateShadowCoord(i.positionWS, i.positionCS);


                SurfaceData surf = (SurfaceData)0;


                surf.albedo = albedo.xyz;
                surf.metallic = MADS.x;
                surf.smoothness = MADS.w;
                surf.occlusion = MADS.y;
                surf.alpha = albedo.w;

                float4 finalColor = UniversalFragmentPBR(data, surf);
                return finalColor;
            }
            ENDHLSL
        }
    }
}
