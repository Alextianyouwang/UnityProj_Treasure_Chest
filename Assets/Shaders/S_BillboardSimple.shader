Shader "Custom/Billboard_Simple"
{
    Properties
    {
        _Albedo("Albedo", 2D) = "Black"{}
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        Pass
        {
            Name "ForwardLit"
            Tags {"LightMode" = "UniversalForward"}
            Cull back
            ZWrite On
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
      
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            TEXTURE2D(_Albedo); SAMPLER(sampler_Albedo);
            struct Input
            {
                float3 positionOS : POSITION;
                float4 uv : TEXCOORD0;
                float4 custom :TEXCOORD1;
            };
            
            struct Interpolator
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 custom :TEXCOORD1;

            };
            
            Interpolator vert(Input i, uint id: SV_InstanceID)
            {
                Interpolator o;
               o.positionCS = mul(UNITY_MATRIX_MVP, float4(i.positionOS, 1));
                o.uv = i.uv;
                o.custom = i.custom;
                return o;
            }
            
            half4 frag(Interpolator i) : SV_Target
            {
                half4 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, i.uv.xy);
                clip(albedo.w - 0.0001);
                return albedo;
            }

            ENDHLSL
        }
      Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}
            ColorMask 0
            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #define SHADOW_CASTER_PASS
        

            #include "./HL_Billboard.hlsl"
            ENDHLSL
        }
    }  
}
    

