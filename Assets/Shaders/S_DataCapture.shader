Shader "Utility/S_DataCapture"
{
    Properties
    {
         [KeywordEnum(Normal, Albedo, Mask, Depth)] _Display("DisplayMode", Float) = 0
        _Normal("Normal", 2D) = "bump"{}
        _Albedo("Albedo", 2D) = "Black"{}
        _ARMA("ARMA", 2D) = "black"{}
        _Blend("Blend",Range(0,1)) = 1
    }
        SubShader
    {
             Tags {"RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"}
      Pass
        {
            Name "DataCapture"
            Cull back
            ZWrite On
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _DISPLAY_NORMAL _DISPLAY_ALBEDO _DISPLAY_MASK _DISPLAY_DEPTH

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_Normal); SAMPLER(sampler_Normal);
            TEXTURE2D(_Albedo); SAMPLER(sampler_Albedo);
            TEXTURE2D(_ARMA); SAMPLER(sampler_ARMA);

            struct Input 
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Interpolator 
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;

            };

            float  _Blend;

            Interpolator vert(Input i)
            {
                Interpolator o;
                o.positionCS = mul(UNITY_MATRIX_MVP, float4(i.positionOS, 1));
                o.positionWS = mul(UNITY_MATRIX_M, float4(i.positionOS, 1));
                o.normalWS = mul(UNITY_MATRIX_M, float4 (i.normalOS, 0)).xyz;
                o.tangentWS = mul(UNITY_MATRIX_M, i.tangentOS);
                o.uv = i.uv;

                return o;
            }

            float4 frag(Interpolator i) : SV_Target
            {
      
                float3 normalWS = normalize(i.normalWS);
                float3 tangentWS = normalize(i.tangentWS).xyz;
                float3 bitangentWS = cross(normalWS, tangentWS);
                float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, i.uv), 1);


                float sgn = i.tangentWS.w; 
                float3 bitangent = sgn * cross(normalWS.xyz, tangentWS.xyz);
                half3x3 tangentToWorld = half3x3(tangentWS.xyz, bitangent.xyz, normalWS.xyz);
                float3 finalNormalWS = normalize( mul(normalTS, tangentToWorld));

                normalWS = lerp(normalWS,finalNormalWS,_Blend) ;

                float NdotL = dot(GetMainLight().direction, normalWS);

                float3 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, i.uv).xyz;
                float4 ARMA = SAMPLE_TEXTURE2D(_ARMA, sampler_ARMA, i.uv);





                float3 posWS = i.positionWS;
                float3 viewDirWS = normalize( _WorldSpaceCameraPos - posWS);
                float3 lightDirWS =  GetMainLight().direction;


                //return posWS.xyzz;
                //return viewDirWS.xyzz;
                //return lightDirWS.xyzz;

 
                //return dot(lightDirWS, normalWS);














      
#if _DISPLAY_NORMAL
        // return float4 (normalWS, 1);
                return float4 ((normalWS + 1) * 0.5, 1);
#elif _DISPLAY_ALBEDO
                return float4 (albedo, 1);
#elif _DISPLAY_MASK
                return ARMA;
#elif _DISPLAY_DEPTH
                return float4 (distance(posWS,_WorldSpaceCameraPos) * 0.01.xxx,1);
#else 
                return 0;
#endif



  
            }
            ENDHLSL
        }
    }
}
