Shader "URPNotes/SimpleTest"{
    /* 着色器的名称以及它在下拉菜单中的位置 ，这部分是不变的 */

    Properties{
        /* 着色器的输入 这部分是不变的，部分参数的类型会发生变化，在后面会说到。*/

        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
    }
    SubShader{
        /* 子着色器1，针对显卡A的着色器，这里是ShaderLab着色器的主要内容 */

        Tags{
            "RenderPipeline" = "UniversalRenderPipeline"            //一定要加这个，用于指明使用URP来渲染
            "RenderType"="Opaque"
        }
        pass{
            
            HLSLPROGRAM
            //函数块变成了HLSLPROGRAM

            #pragma vertex Vertex
            #pragma fragment Pixel
            //保持你喜欢的命名方式

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //在CG中使用的cginc文件变成了HLSL文件，并且由于它们是Unity的一个扩展组件，所以需要在Packages中找到相对应的
            //库文件，里面定义了我们在URP中使用的主要的API，
            //Core.HLSL中包含了一些常用的函数，另外还有一些其他的HLSL文件，后面会逐一介绍。

            half4 _BaseColor;
            //不要忘记在这里声明变量，否则着色器无法访问属性。

            struct vertexInput{
                //顶点着色器的输入,这个是不变的,

                float4 vertex:POSITION;

            };//不要忘了分号哦

            struct vertexOutput{
                //顶点着色器的输出,同时也是片元着色器的输入

                float4 pos:SV_POSITION;
            };

            vertexOutput Vertex(vertexInput v){

                vertexOutput o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                // TransformObjectToHClip 是
                
                return o;
            }

            half4 Pixel(vertexOutput i):SV_TARGET{
                /* 片元着色器，注意，在HLSL中，fixed4类型变成了half4类型*/

                return _BaseColor;
            }

            ENDHLSL
        }
    }
}