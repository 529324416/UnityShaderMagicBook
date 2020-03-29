Shader "UShaderMagicBook/Billboard1"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
    }
    SubShader{
        Tags{"Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" "DisableBatching"="True"}
        /*
        这里我们使用了DisableBatching标签，一些SubShader在使用Unity的批处理功能的时候会产生问题，
        这个时候可以通过该标签来直接指明是否对SubShader使用批处理功能。而这些需要特殊处理的Shader通常
        就是指包含了模型空间的顶点动画的Shader。批处理会导致模型空间的丢失，而这正好是顶点动画所需要的
        所以我们在这里关闭Shader的批处理操作。
        */
        pass{
            Tags{"LightMode"="Always"}
            Cull Off    //关闭剔除，让模型的两面都可以显示


            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            sampler2D _MainTex;

            struct vertexOutput{

                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            vertexOutput Vertex(appdata_base v){

                vertexOutput o;
                float3 center = float3(0,0,0);
                /*设（0，0，0）为模型的中心点，用于代替模型的位置，这个一定要有，
                本质上中心点的位置不变其他顶点围绕中心点发生变化
                问1：为什么不使用worldPos=mul(unity_ObjectToWorld,v.vertex).xyz？
                答1：使用worldPos代表了每个顶点的位置，每个顶点都有自己的方向，如果使用
                worldPos，那么每个顶点便会自顾自的旋转，而非整体旋转。（ps：我们是在模型
                空间计算）
                */

                float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;
                /*把摄像机的位置转换到模型空间*/

                float3 viewDir = viewer - center;
                viewDir = normalize(viewDir);       //始终保持center不是(0,0,0)的假设

                float3 upDir = float3(0,1,0);                           //up方向
                float3 rightDir = normalize(cross(upDir,viewDir));      //右方向
                viewDir = normalize(cross(upDir,rightDir));             //新的模型视角方向

                float3 centerOffset = v.vertex.xyz - center;
                float3x3 _RotateMatrix = transpose(float3x3(rightDir,upDir,viewDir));
                float3 pos = mul(_RotateMatrix,centerOffset) + center;

                o.pos = UnityObjectToClipPos(float4(pos,1));
                o.uv = v.texcoord;

                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                return tex2D(_MainTex,i.uv);
            }
            
            ENDCG

        }
    }
}