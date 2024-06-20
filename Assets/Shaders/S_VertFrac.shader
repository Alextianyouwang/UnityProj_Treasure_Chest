Shader "Custom/S_VertFrac"
{
    Properties
    {

        _Normal("Normal", 2D) = "bump"{}
        _Albedo("Albedo", 2D) = "Black"{}
        _Roughness("ARMA", 2D) = "White"{}
        _MaskCenter("MaskCenter", Vector) = (0,0,0,0)
        _MaskRadius("MaskRadius", Float) = 0
        _MaskFalloff("MaskFalloff", Float) = 0
        _CrackMultiplier("CrackMultiplier",Range (0,1)) = 0
    }
        SubShader
    {
             Tags {"RenderType" = "Opaque""RenderPipeline" = "UniversalRenderPipeline"}
      Pass
        {
            Name "VertFrac"
                 Tags {"LightMode" = "UniversalForward"}
            Cull back
            ZWrite On
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex vert
            #pragma fragment frag

                    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
             #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _SHADOWS_SOFT


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "../INCLUDE/HL_Noise.hlsl"
        #include "../INCLUDE/HL_ShadowHelper.hlsl"

            TEXTURE2D(_Normal); SAMPLER(sampler_Normal);
            TEXTURE2D(_Albedo); SAMPLER(sampler_Albedo);
            TEXTURE2D(_Roughness); SAMPLER(sampler_Roughness);
            float3 _MaskCenter;
            float _MaskRadius;
            float _MaskFalloff;
            float  _CrackMultiplier;
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
                float3 noise = (rand3dTo3d(objectWorldPosition) - 0.5) *_CrackMultiplier;
                float mask = 1- SphereMask(_MaskCenter, _MaskRadius, _MaskFalloff, objectWorldPosition);
                positionWS += noise * mask;

                o.positionWS = positionWS;
                o.positionCS = mul(UNITY_MATRIX_VP, float4(positionWS, 1));
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
                float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, i.uv), -1);


                float sgn = i.tangentWS.w; 
                float3 bitangent = sgn * cross(normalWS.xyz, tangentWS.xyz);
                half3x3 tangentToWorld = half3x3(tangentWS.xyz, bitangent.xyz, normalWS.xyz);
                normalWS = normalize( mul(normalTS, tangentToWorld));


                float3 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, i.uv).xyz;
                float4 ARMA = SAMPLE_TEXTURE2D(_Roughness, sampler_Roughness, i.uv);


                float3 posNDS = i.positionCS / i.positionCS.w;
                float2 uvSS = posNDS.xy / 2 + 0.5;
                InputData data = (InputData)0;

                data.positionWS = i.positionWS;
                data.positionCS = i.positionCS;
                data.normalWS = normalWS;
                data.viewDirectionWS = normalize(_WorldSpaceCameraPos - i.positionWS);
                data.shadowCoord = CalculateShadowCoord(i.positionWS, i.positionCS);
                data.fogCoord = 0;
                data.vertexLighting = 0;
                data.bakedGI = 0;
                data.normalizedScreenSpaceUV = uvSS;
                data.shadowMask = 0;
                data.tangentToWorld = tangentToWorld;

                SurfaceData surf = (SurfaceData)0;

                surf.albedo = albedo.xyz;
                surf.specular = 1;
                surf.metallic = 0;
                surf.smoothness = 1 - ARMA.r;
                surf.normalTS = normalTS;
                surf.emission = 0;
                surf.occlusion = 1;
                surf.alpha = 1;
                surf.clearCoatMask = 0;
                surf.clearCoatSmoothness = 0;

                float4 finalColor = UniversalFragmentPBR(data, surf);
                return finalColor;
                return float4 (albedo, 1);

            }
            ENDHLSL
        }
    }
}
