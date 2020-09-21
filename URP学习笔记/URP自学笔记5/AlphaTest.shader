Shader "URPNotes/AlphaTest"{
    Properties{
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _MainTex("Main Texture",2D) = "white"{}
        _AlphaTest("Alpha Threshold",Range(0,1)) = 0
    }
    SubShader{
        Tags{
            /*想不到把，透明度测试还是不透明物体*/

            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }
        pass{
            HLSLPROGRAM
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

                #pragma vertex Vertex
                #pragma fragment Pixel

                CBUFFER_START(UnityPerMaterial)
                    half4 _BaseColor;
                    half _AlphaTest;
                    float4 _MainTex_ST;
                CBUFFER_END

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);

                struct vertexInput{
                    float4 vertex:POSITION;
                    float2 uv:TEXCOORD0;
                };

                struct vertexOutput{

                    float4 pos:SV_POSITION;
                    float2 uv:TEXCOORD0;
                };

                vertexOutput Vertex(vertexInput v){

                    vertexOutput o;
                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                    o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                    return o;
                }

                half4 Pixel(vertexInput i):SV_TARGET{

                    half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                    clip(albedo.a - _AlphaTest);        //剔除掉透明度值低于_AlphaTest的像素。

                    return albedo * _BaseColor;
                }

            ENDHLSL
        }
    }
}