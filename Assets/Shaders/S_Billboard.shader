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
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "./HL_Billboard.hlsl"
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
