Shader "Custom/SimpleUnlit_Opaque_Scale"
{
    Properties
    {
        _Albedo("Albedo", 2D) = "Black"{}
        _Tint("Tint",Color) = (0,1,0,1)
        _Scale("Scale",Range(0,1)) = 0.5
        _Lerp("Lerp",Range(0,1)) = 0
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque"  "RenderPipeline" = "UniversalPipeline"}
        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _EffectCenter;
            float _Lerp;

             float MoveUp(float3 pos) 
            {
                  float dist = distance(pos, _EffectCenter);

                  return 1 - smoothstep(0,10, dist);
            }
            
        ENDHLSL
        Pass
        {
            Name "ForwardLit"
            Tags {"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

                        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                              #pragma multi_compile _ _SHADOWS_SOFT
            TEXTURE2D(_Albedo); SAMPLER(sampler_Albedo);
            StructuredBuffer<float3> _PositionBuffer;
            float4 _Tint;
            float _Scale;

            struct Input
            {
                float3 positionOS : POSITION;
                float4 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                uint id : SV_InstanceID;
            };
            
            struct Interpolator
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD02;
               float3 bakedGI : TEXCOORD3;

            };

  
            Interpolator vert(Input i)
            {
                Interpolator o;
                       float3 spawnPos =       _PositionBuffer[i.id];
                      // spawnPos +=normalize(spawnPos- _EffectCenter) * lerp (0.7,MoveUp(_PositionBuffer[i.id]),_Lerp)* 5;

                float3 worldPos= spawnPos + i.positionOS * _Scale;
                o.positionWS = worldPos;
                 //worldPos.y += lerp (0,MoveUp(_PositionBuffer[i.id]),_Lerp)* 5;
                 
                 o.positionWS = worldPos;
                o.positionCS = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
                o.uv = i.uv;
                o.normalWS = i.normalOS;
                 float3 vertexSH;
                OUTPUT_SH(i.normalOS, vertexSH);
                o.bakedGI =SAMPLE_GI(0, vertexSH,i.normalOS);
                return o;
            }
            
            half4 frag(Interpolator i) : SV_Target
            {
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(i.positionWS));

                half4 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, i.uv.xy);
                albedo.a = 0.1;
                albedo *= _Tint;
                albedo *= mainLight.shadowAttenuation;
                return i.normalWS.xyzz;
                return mainLight.color.xyzz * mainLight.shadowAttenuation * mainLight.distanceAttenuation* _Tint + i.bakedGI.xyzz;
            }

            ENDHLSL
        }
         Pass
        {
          Name "ShadowCaster"
          Tags {"LightMode" = "ShadowCaster"}
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #define SHADOW_CASTER_PASS
            StructuredBuffer<float3> _PositionBuffer;
            float _Scale;
             float3 _LightDirection;

            float4 CalculatePositionCSWithShadowCasterLogic(float3 positionWS, float3 normalWS)
{
    float4 positionCS;

#ifdef SHADOW_CASTER_PASS
    // From URP's ShadowCasterPass.hlsl
    // If this is the shadow caster pass, we need to adjust the clip space position to account
    // for shadow bias and offset (this helps reduce shadow artifacts)
    positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif
#else
    // This built in function transforms from world space to clip space
    positionCS = TransformWorldToHClip(positionWS);
#endif

    return positionCS;
}
            struct Input
            {
                float3 positionOS : POSITION;
                 float3 normalOS : NORMAL;
                uint id : SV_InstanceID;
            };

            struct Interpolator
            {
                float4 positionCS : SV_POSITION;
            };

            
            Interpolator vert(Input i)
            {
                Interpolator o;
                                                   float3 spawnPos =       _PositionBuffer[i.id];
                     // spawnPos +=normalize(spawnPos- _EffectCenter) * lerp (0.7,MoveUp(_PositionBuffer[i.id]),_Lerp)* 5;

                float3 worldPos= spawnPos + i.positionOS * _Scale;
                 // worldPos.y += lerp (0,MoveUp(_PositionBuffer[i.id]),_Lerp)* 5;
      
                o.positionCS =  CalculatePositionCSWithShadowCasterLogic(worldPos, i.normalOS);
                  //o.positionCS = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
                return o;
            }
            
            half4 frag(Interpolator i) : SV_Target
            {
                return 0;
            }

            ENDHLSL
        }
    }  
}
    

