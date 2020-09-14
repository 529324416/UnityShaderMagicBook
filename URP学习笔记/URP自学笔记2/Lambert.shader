Shader "URPNotes/Lambert"
{
    Properties
    {
        //着色器的输入，注意Unity所规定的类型不变
        _BaseColor ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags {"RenderType"="Opaque" "RenderPipeline" = "UniversalRenderPipeline"}
        //设定为URP
        pass{

            HLSLPROGRAM
                /* 主要的着色器内容 */

                #pragma vertex Vertex
                #pragma fragment Pixel

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
                //引用


                CBUFFER_START(UnityPerMaterial)
                    /*输入变量的声明要包在CBUFFER_START(UnityPerMaterial)和CBUFFER_END中*/

                    half4 _BaseColor;
                CBUFFER_END

                struct VertexInput{
                    //顶点着色器的输入，我们需要顶点位置和法线，语义和CG中一样

                    float4 vertex:POSITION;
                    half3 normal:NORMAL;
                };

                struct VertexOutput{
                    //顶点着色器的输出

                    float4 pos:SV_POSITION;
                    half3 worldNormal:TEXCOORD0;
                };

                VertexOutput Vertex(VertexInput v){
                    /* 顶点着色器 */

                    VertexOutput o;
                    o.pos = TransformObjectToHClip(v.vertex.xyz);           //将顶点转换到裁剪空间，这步是顶点着色器必做的事情，否则
                                                                            //渲染后模型会错位。
                    o.worldNormal = TransformObjectToWorldDir(v.normal); //将法线切换到世界空间下，注意normal是方向
                    return o;
                }

                half4 Pixel(VertexOutput i):SV_TARGET{
                    /* 片元着色器 */

                    Light mlight = GetMainLight();                                  //获取主光源的数据      
                    float power = saturate(dot(mlight.direction,i.worldNormal));    //计算漫反射强度
                    return _BaseColor * power * half4(mlight.color,1);              //将表面颜色，漫反射强度和光源强度混合。
                }
            ENDHLSL
        }
    }
}
