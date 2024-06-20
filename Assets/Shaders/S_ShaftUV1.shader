Shader "Custom/S_ShaftUV1"
{
    Properties
    {
      [HDR] _Tint("Tint", Color) = (1,1,1,1)
              _MaskCenter("MaskCenter", Vector) = (0,0,0,0)
        _MaskRadius("MaskRadius", Float) = 0
        _MaskFalloff("MaskFalloff", Float) = 0
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
    float3 _MaskCenter;
    float _MaskRadius;
    float _MaskFalloff;
    float SphereMask(float3 center, float radius, float falloff, float3 position)
    {
        float mask0 = smoothstep(radius - falloff, radius, distance(position, center));
        float mask1 = smoothstep(radius, radius + falloff, distance(position, center));
        return mask0;

    }
            struct Input 
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
            };

            struct Interpolator 
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
                float2 uv1 : TEXCOORD4;

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
                o.uv1 = i.uv1;

                return o;
            }

            float4 frag(Interpolator i) : SV_Target
            {
                float2 uv = i.uv;
                float2 uv1 = i.uv1;
                float3 posWS = i.positionWS;
   
                float4 finalColor = _Tint;
                finalColor.a *= pow( uv1.x,4);
                return finalColor;

            }
            ENDHLSL
        }
    }
}
