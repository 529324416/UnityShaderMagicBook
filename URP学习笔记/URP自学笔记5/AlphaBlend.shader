Shader "URPNotes/AlphaBlend"{
    Properties{
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _MainTex("Main Texture",2D) = "white"{}
        _Alpha("Alpha",Range(0,1)) = 1.0
    }
    SubShader{
        Tags{
            /* 设置渲染类型为透明，忽略其他物体的投影，渲染队列为透明度渲染队列，这个
            队列会在不透明物体队列之后渲染 */

            "RenderType"="Transparent"
            "RenderPipeline"="UniversalRenderPipeline"
            "IgnoreProjector"="True"
            "Queue"="Transparent"
        }
        pass{
            /* 设置混合模式，我们选择的模式是透明度混合，所以使用透明度混合，并关闭ZWrite
            之后正常的计算该有的东西就可以了，所有的工作都将由Unity来完成 */
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off
            HLSLPROGRAM
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

                #pragma vertex Vertex
                #pragma fragment Pixel

                CBUFFER_START(UnityPerMaterial)
                    half4 _BaseColor;
                    half _Alpha;
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

                half4 Pixel(vertexOutput i):SV_TARGET{

                    half3 albeo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv).xyz * _BaseColor.xyz;
                    return half4(albeo,_Alpha);
                }
            
            ENDHLSL
        }
    }
}