Shader "UShaderMagicBook/texSimple"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
        //增加一个2d纹理类型的输入

        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
    }
    SubShader{
        pass{
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            struct vertexInput{
                /*顶点着色器的输入*/

                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                //输入第一组纹理坐标,其实就是一个0-1的值
            };

            struct vertexOutput{
                /* 顶点着色器输出 */

                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float2 uv : TEXCOORD1;
                //uv坐标，在顶点着色器中计算，后使用该坐标去片元着色器中对纹理进行采样
            };

            sampler2D _MainTex;        //别忘记重新声明一下,注意在Properties中的2D类型对应的是sampler2D类型
            float4 _MainTex_ST;         
            float4 _BaseColor;

            vertexOutput Vertex(vertexInput v){
                /* 顶点着色器，除了做基本的转换之外，还需要增加一个uv坐标的计算 */

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                //o.uv = TRANSFORM_TEX(v.texcoord,_MainTex)
                //此处的texcoord的范围其实就是0-1的一个值，
                //在该着色器中暂时不做计算，直接赋值给uv后传入片元着色器

                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{
                /* 片元着色器，为了简单起见，我们只计算漫反射和环境光 */

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                float3 albedo = tex2D(_MainTex,i.uv).xyz * _BaseColor.xyz;
                //使用前面计算得到的uv坐标对主纹理进行采样
                //然后和基础颜色进行混合
                
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.xyz * albedo * saturate(dot(worldNormal,worldLightDir));
                //计算环境光和漫反射的时候，使用albedo来作为颜色输入

                return fixed4(ambient + diffuse,1.0);
            }

            ENDCG
        }
    }
}