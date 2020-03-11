Shader "UShaderMagicBook/AlphaBlend_Cull"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _AlphaScale("Alpha Threshold",Range(0,1)) = 1
    }

    SubShader{
        Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        //记住Transparent就完事了

        pass{
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            //关闭深度写入，同时开启混合。这里我们的混合因子选择了SrcAlpha 和OneMinueSrcAlpha
            //这两个计算因子最终可以得到半透明混合的效果。

            Tags{"LightMode"="ForwardBase"}
            Cull Front
            //不变

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #include "Lighting.cginc"

            struct vertexInput{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct vertexOutput{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            sampler2D _MainTex;
            fixed4 _BaseColor;
            fixed _AlphaScale;

            vertexOutput Vertex(vertexInput v){
                
                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv = v.texcoord;

                return o;
            }
            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 albedo = tex2D(_MainTex,i.uv).xyz * _BaseColor.xyz;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.xyz * albedo * saturate(dot(worldNormal,lightDir));

                return fixed4(diffuse + ambient,_AlphaScale);
            }

            ENDCG
        }
        pass{
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            //关闭深度写入，同时开启混合。这里我们的混合因子选择了SrcAlpha 和OneMinueSrcAlpha
            //这两个计算因子最终可以得到半透明混合的效果。

            Tags{"LightMode"="ForwardBase"}
            Cull Back
            //不变

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #include "Lighting.cginc"

            struct vertexInput{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct vertexOutput{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            sampler2D _MainTex;
            fixed4 _BaseColor;
            fixed _AlphaScale;

            vertexOutput Vertex(vertexInput v){
                
                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv = v.texcoord;

                return o;
            }
            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 albedo = tex2D(_MainTex,i.uv).xyz * _BaseColor.xyz;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.xyz * albedo * saturate(dot(worldNormal,lightDir));

                return fixed4(diffuse + ambient,_AlphaScale);
            }

            ENDCG
        }
    }
}