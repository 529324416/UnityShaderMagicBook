Shader "RedSaw/Lake Simulation"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1,1,1,1)
        [HDR]_SpecularColor("Specular Color", Color) = (1,1,1,1)
        _SpecularPower("Specular Power", Range(1, 200)) = 32
        _Skybox("Skybox", Cube) = ""{}
        _FresnelFactor("Fresnel Factor", Range(0, 1)) = 0.04
        _WaterAbsorption("Water Absorption", Range(0, 10)) = 1
        _WaterAbsorptionToLight("Water Absorption To Light", Range(0, 10)) = 1
        _ScatteringCofficient("Scattering Cofficient", Vector) = (4, 1.61, 1, 0.1)
        _RefractionIndex("Refraction Index", Range(0, 0.1)) = 0.02
        _WaterCaustics("Water Caustics", 2D) = ""{}
        _WaterCausticsAbsorptionScale("Water Caustics Absorption", Range(0, 2)) = 1
        [HDR]_WaterCausticsColor("Water Caustics Color", Color) = (1,1,1,1)
        _WaterCausticsSpeed("Water Caustics Speed", Range(0, 10)) = 1
        _WaterCausticsChromaticAberration("Water Caustics Chromatic Aberration", Range(0, 0.1)) = 0.01
    }
    SubShader
    {
        Tags{ "RenderType" = "Opaque" "Queue" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" }
        LOD 100
        ZWrite Off
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            float FresnelSchlick(float3 V, float3 N, float f0)
            {
                return f0 + (1 - f0) * pow(1 - saturate(dot(V, N)), 5);
            }

            /*  通过boundsMin和boundsMax锚定一个长方体包围盒
                从rayOrigin朝rayDir发射一条射线，计算出射线到包围盒的距离
                https://jcgt.org/published/0007/03/04/ */
            float2 RayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 rayDir){

                float3 t0 = (boundsMin - rayOrigin) / rayDir;
                float3 t1 = (boundsMax - rayOrigin) / rayDir;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);

                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(tmax.x, min(tmax.y, tmax.z));

                float dstToBox = max(0, dstA);
                float dstInsideBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }

            float3 GetWorldPositionFromDepth(float3 positionHCS)
            {
                /* get world space position */
            
                float2 UV = positionHCS.xy / _ScaledScreenParams.xy;
                #if UNITY_REVERSED_Z
                    real depth = SampleSceneDepth(UV);
                #else
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif
                return ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);
            }

            float3 RayleighPhaseFunction(float3 N, float V)
            {
                return 0.75 * (1 + pow(dot(N, V), 2));
            }

            struct VertexInput
            {
                float4 vertex           : POSITION;
                float2 uv               : TEXCOORD0;
                float3 normal           : NORMAL;
            };

            struct VertexOutput
            {
                float4 positionHCS      : SV_POSITION;
                float2 uv               : TEXCOORD0;
                float3 normalWS         : TEXCOORD1;
                float3 positionWS       : TEXCOORD2;
            };

            half4 _BaseColor;
            half4 _SpecularColor;
            half _SpecularPower;
            TEXTURECUBE(_Skybox);
            SAMPLER(sampler_Skybox);
            float _FresnelFactor;
            float3 _BoundsMin;
            float3 _BoundsMax;
            float _WaterAbsorption;
            float _WaterAbsorptionToLight;
            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);
            float3 _ScatteringCofficient;
            float _RefractionIndex;
            TEXTURE2D(_WaterCaustics);
            SAMPLER(sampler_WaterCaustics);
            float4 _WaterCaustics_ST;
            float _WaterCausticsAbsorptionScale;
            float4x4 _SunMatrix;
            half4 _WaterCausticsColor;
            float _WaterCausticsSpeed;
            float _WaterCausticsChromaticAberration;

            VertexOutput vert(VertexInput input)
            {
                VertexOutput output;
                output.positionHCS = TransformObjectToHClip(input.vertex.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normal);
                output.positionWS = TransformObjectToWorld(input.vertex.xyz);
                output.uv = input.uv;
                return output;
            }

            half4 frag(VertexOutput IN) : SV_Target
            {

                /* Surface Shading，Including Diffuse, Specular, Ambient and Skybox
                 * 表面着色，包括漫反射、高光、环境光和天空盒
                 */

                Light light = GetMainLight();

                half3 diffuse = saturate(dot(IN.normalWS, light.direction)) * _BaseColor.rgb;
                float3 viewDir = normalize(_WorldSpaceCameraPos - IN.positionWS);
                half3 halfDir = normalize(light.direction + viewDir);
                half3 specular = pow(saturate(dot(IN.normalWS, halfDir)), _SpecularPower) * _SpecularColor.rgb;
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT;
                half3 cs_ = ambient + light.color * (diffuse + specular);
                half4 skyColor = SAMPLE_TEXTURECUBE(_Skybox, sampler_Skybox, reflect(-viewDir, IN.normalWS));
                half3 cs = lerp(cs_, skyColor.rgb, FresnelSchlick(viewDir, IN.normalWS, _FresnelFactor));

                /*
                 * Volumetric Rendering, Including Transmittance and Scattering
                 * 体积渲染，包括透射和散射
                 */

                float2 rayInfo = RayBoxDst(_BoundsMin, _BoundsMax, _WorldSpaceCameraPos, -viewDir);
                float lengthToWater = length(_WorldSpaceCameraPos - IN.positionWS);
                float3 opaquePoint = GetWorldPositionFromDepth(IN.positionHCS);
                float lengthToOpaque = length(_WorldSpaceCameraPos - opaquePoint);
                float thickness = min(rayInfo.y, lengthToOpaque - lengthToWater);
                float3 Tr = exp(-thickness * _WaterAbsorption);

                float2 refractionTwist = IN.normalWS.xz * _RefractionIndex;
                float2 screenUV = IN.positionHCS.xy / _ScaledScreenParams.xy + refractionTwist;
                half3 cb = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV).rgb;

                float3 inScatteringLight = 0;
                int stepCount = 16;
                float stepLength = thickness / stepCount;
                for(float dstTravelled = stepLength; dstTravelled < thickness; dstTravelled += stepLength)
                {
                    float3 samplePoint = IN.positionWS - viewDir * dstTravelled;
                    float lightPathDensity = (_BoundsMax.y - samplePoint.y) * light.direction.y;
                    inScatteringLight += exp(-(lightPathDensity + dstTravelled) * _WaterAbsorption * _ScatteringCofficient);
                }
                inScatteringLight *= light.color * _ScatteringCofficient * RayleighPhaseFunction(IN.normalWS, -viewDir) * stepLength;

                // float3 P = float3(IN.positionWS.x, _BoundsMax.y, IN.positionWS.z) + thickness * -viewDir;
                // float3 O = _ScatteringCofficient * _WaterAbsorption;
                //
                // float Q = (P.y - IN.positionWS.y) * light.direction.y - thickness;
                // float OQ = O * Q + 0.01;
                // float3 inScatteringLight = (exp(OQ) - 1) / OQ;
                // inScatteringLight *= light.color * _ScatteringCofficient * RayleighPhaseFunction(IN.normalWS, -viewDir);

                /*
                 * Water Caustics Rendering，Base On Decal Projector
                 * 焦散效果渲染，基于贴花投影
                 */

                
                float causticsMask = step(0.001, SampleSceneDepth(screenUV)) * exp(-thickness * _WaterAbsorption * _WaterCausticsAbsorptionScale);
                float3 causticLightSpacePosition = mul(opaquePoint, _SunMatrix).xyz;
                float2 causticUV = causticLightSpacePosition.xy + refractionTwist;
                causticUV = TRANSFORM_TEX(causticUV, _WaterCaustics);
                float2 chromaticAberrationOffset = _WaterCausticsChromaticAberration;

                float2 causticUV1 = causticUV + _Time.y * _WaterCausticsSpeed;
                half causticsColor1_R = SAMPLE_TEXTURE2D(_WaterCaustics, sampler_WaterCaustics, causticUV1 + chromaticAberrationOffset).r;
                half causticsColor1_G = SAMPLE_TEXTURE2D(_WaterCaustics, sampler_WaterCaustics, causticUV1).g;
                half causticsColor1_B = SAMPLE_TEXTURE2D(_WaterCaustics, sampler_WaterCaustics, causticUV1 - chromaticAberrationOffset).b;
                half3 causticsColor1 = half3(causticsColor1_R, causticsColor1_G, causticsColor1_B);
                
                float2 causticUV2 = causticUV - _Time.y * _WaterCausticsSpeed + float2(123.456, 456.789);       // 加入偏移，避免重复
                half causticsColor2_R = SAMPLE_TEXTURE2D(_WaterCaustics, sampler_WaterCaustics, causticUV2 + chromaticAberrationOffset).r;
                half causticsColor2_G = SAMPLE_TEXTURE2D(_WaterCaustics, sampler_WaterCaustics, causticUV2).g;
                half causticsColor2_B = SAMPLE_TEXTURE2D(_WaterCaustics, sampler_WaterCaustics, causticUV2 - chromaticAberrationOffset).b;
                half3 causticsColor2 = half3(causticsColor2_R, causticsColor2_G, causticsColor2_B);

                half3 causticsColor = min(causticsColor1,causticsColor2);
                half3 caustics = causticsMask * causticsColor * _WaterCausticsColor.rgb * pow(light.color.rgb, 2);
                

                half3 co = cs + cb * (Tr + inScatteringLight) + caustics;
                return half4(inScatteringLight, 1);
            }
            
            ENDHLSL
        }
    }
}