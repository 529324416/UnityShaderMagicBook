Shader "URPNotes/Specular"{
    Properties{
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _Gloss("Gloss",Range(8,20)) = 8.0 
    }
    SubShader{
        Tags{
            "RenderType"="Opaqua"
            "RenderPipeline"="UniversalRenderPipeline"
        }
        pass{
            HLSLPROGRAM

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

                CBUFFER_START(UnityPerMaterial)
                    half4 _BaseColor;
                    half _Gloss;
                CBUFFER_END

                #pragma vertex Vertex
                #pragma fragment Pixel

                struct vertexInput{

                    float3 vertex:POSITION;
                    float3 normal:NORMAL;        
                };

                struct vertexOutput{
                    
                    float4 pos:SV_POSITION;
                    float3 worldNormal:TEXCOORD0;
                    float3 worldPos:TEXCOORD1;
                };

                vertexOutput Vertex(vertexInput v){

                    vertexOutput o;
                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                    o.worldNormal = TransformObjectToWorldNormal(v.normal);
                    o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                    return o;
                }

                half4 Pixel(vertexOutput i):SV_TARGET{

                    /* 首先计算基础信息 */

                    Light light = GetMainLight();
                    half3 lightDir = normalize(TransformObjectToWorldDir(light.direction));
                    half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                    half3 reflectDir = normalize(reflect(lightDir,i.worldNormal));

                    /* 计算漫反射 */

                    half3 diffuse = _BaseColor.xyz * saturate(dot(lightDir,i.worldNormal));
                    
                    /* 计算高光 */

                    float spec = pow(saturate(dot(viewDir,-reflectDir)),_Gloss);
                    half3 specular = _BaseColor.xyz * spec;

                    /*叠加后输出*/ 

                    return half4(specular + diffuse,1);
                }

            ENDHLSL
        }
    }
}