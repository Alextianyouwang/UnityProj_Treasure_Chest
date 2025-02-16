Shader "Custom/SimpleUnlit"
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
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            TEXTURE2D(_Albedo); SAMPLER(sampler_Albedo);
            StructuredBuffer<float3> _PositionBuffer;
            struct Input
            {
                float3 positionOS : POSITION;
                float4 uv : TEXCOORD0;
                uint id : SV_InstanceID;
            };
            
            struct Interpolator
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
            };
            
            Interpolator vert(Input i)
            {
                Interpolator o;
                float3 worldPos = mul (UNITY_MATRIX_M, float4 (i.positionOS,1)) ;
                
                worldPos = _PositionBuffer[i.id] + i.positionOS;
                o.positionCS = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
                o.uv = i.uv;
                return o;
            }
            
            half4 frag(Interpolator i) : SV_Target
            {
                half4 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, i.uv.xy);
                return albedo;
            }

            ENDHLSL
        }
    }  
}
    

