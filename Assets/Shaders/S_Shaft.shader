Shader "Custom/S_VertFrac"
{
    Properties
    {
      [HDR] _Tint("Tint", Color) = (1,1,1,1)
    }
        SubShader
    {
             Tags {"RenderType" = "Transparent""RenderPipeline" = "UniversalRenderPipeline"}
      Pass
        {
            Name "VertFrac"
                 Tags {"LightMode" = "UniversalForward"}
            Cull off
            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex vert
            #pragma fragment frag


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "../INCLUDE/HL_Noise.hlsl"
        #include "../INCLUDE/HL_ShadowHelper.hlsl"


        float4 _Tint;
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

            Interpolator vert(Input i)
            {
                Interpolator o;
                float3 positionWS = mul(UNITY_MATRIX_M, float4(i.positionOS, 1));

                float3 objectWorldPosition = unity_ObjectToWorld._m03_m13_m23;

                o.positionWS = positionWS;
                o.positionCS = mul(UNITY_MATRIX_VP, float4(positionWS, 1));
                o.normalWS = mul(UNITY_MATRIX_M, float4 (i.normalOS, 0)).xyz;
                o.tangentWS = mul(UNITY_MATRIX_M, i.tangentOS);
                o.uv = i.uv;

                return o;
            }

            float4 frag(Interpolator i) : SV_Target
            {
                float2 uv = i.uv;
                float3 posWS = i.positionWS;
                float stripe = 0; 
                float freq = 10;
                float amp = 1;
                float speed = 1;
                [unroll]
                for (int i = 0; i < 4; i++) 
                {
                    stripe += smoothstep(0.5, 1, (perlinNoise(uv.x * freq + _Time.y * speed, 12.9898) + 1) * 0.5 * amp);
                    freq *= 2;
                    amp *= 0.95;
                    speed *= -0.8;
                }
                

                float4 finalColor = _Tint;
                finalColor.a *= stripe * pow( (1 - uv.y),4);
                //return float4 (uv, 0, 1);
                return finalColor;

            }
            ENDHLSL
        }
    }
}
