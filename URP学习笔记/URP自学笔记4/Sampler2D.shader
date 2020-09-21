Shader "URPNotes/Sampler2D"{
    /* 关于HLSL的2D采样器 */

    Properties{
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _MainTex("Main Texture",2D) = "white"{}
    }
    SubShader{
        Tags{
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalRenderPipeline"
        }
        pass{
            
            HLSLPROGRAM
                #pragma vertex Vertex
                #pragma fragment Pixel

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
                /* 声明主纹理并且为主纹理设置一个采样器，没有什么说法，这是一种固定的格式。
                主纹理的声明同属性的声明，注意类型为TEXTURE2D，采样通过SAMPLER来定义，括号中的
                名字为采样器的变量名，变量名随意，但同样遵循一般命名原则。*/

                CBUFFER_START(UnityPerMaterial)
                    half4 _BaseColor;
                    float4 _MainTex_ST;
                    //_MainTex_ST，当定义一张纹理的时候，该纹理的uv坐标的缩放与偏移会
                    //整合成一个float4类型数据填充到_MainTex_ST当中，所以你需要手动声明一下
                CBUFFER_END

                struct vertexInput{

                    float4 vertex:POSITION;
                    float2 uv:TEXCOORD0;        //第一张纹理的uv坐标，TEXCOORD0在输入结构体当中的含义是明确的
                };

                struct vertexOutput{

                    float4 pos:SV_POSITION;
                    float2 uv:TEXCOORD0;
                };

                vertexOutput Vertex(vertexInput v){
                    
                    vertexOutput o;
                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                    o.uv = TRANSFORM_TEX(v.uv,_MainTex);            
                    /*注意这里写的是_MainTex，因为在TransformTex函数中，它会自动在纹理名后面增加一个_ST*/

                    return o;
                }

                half4 Pixel(vertexOutput i):SV_TARGET{

                    half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                    //使用uv坐标和采样器在主纹理上进行采样，说实话，有点繁琐

                    return albedo * _BaseColor;
                }

            ENDHLSL
        }
    }
}