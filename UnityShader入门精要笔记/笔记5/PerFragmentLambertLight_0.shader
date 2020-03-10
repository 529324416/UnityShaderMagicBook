Shader "UShaderMagicBook/PerFragmentLambertLight_0"{
    Properties{}
    SubShader{
        pass{
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel

            #include "Lighting.cginc"

            struct vertexInput{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct vertexOutput{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                //这里的texcoord仅仅是用作储存世界法线信息而已
            };

            vertexOutput Vertex(vertexInput v){
                /*在顶点着色器中进行坐标的转换*/

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 worldNormal = normalize(i.worldNormal);                //将法线信息标准化
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);


                fixed3 diffuse = _LightColor0.xyz * max(0,dot(worldNormal,worldLightDir));



                //_LightColor0中同时储存了平行光（在ForwardBase模式下）的光源颜色和强度

                return fixed4(diffuse,1.0);
            }

            ENDCG
        }
    }
}