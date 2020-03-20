Shader "UShaderMagicBook/EnvironmentMap"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _ReflectColor("Reflection Color",Color) = (1.0,1.0,1.0,1.0)
        _ReflectAmount("Reflection Amount",Range(0,1)) = 1
        _Cubemap("Reflection Cubemap",Cube) = "skybox"{}
    }
    SubShader{
        pass{
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma vertex Vertex
            #pragma fragment Pixel

            struct vertexInput{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct vertexOutput{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldReflectDir : TEXCOORD3;
                float2 uv : TEXCOORD4;
                SHADOW_COORDS(5)
            };

            fixed4 _BaseColor;
            fixed _ReflectAmount;
            fixed4 _ReflectColor;
            samplerCUBE _Cubemap;
            sampler2D _MainTex;

            vertexOutput Vertex(vertexInput v){
                
                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldReflectDir = reflect(-o.worldViewDir,o.worldNormal);
                o.uv = v.texcoord;
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                fixed3 albedo = tex2D(_MainTex,i.uv).xyz * _BaseColor.xyz;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.xyz * albedo * saturate(dot(worldNormal,worldLightDir));

                fixed3 reflection = texCUBE(_Cubemap,i.worldReflectDir).xyz * _ReflectColor.xyz;
                //利用视角的反射方向，在立方体纹理中进行采样。然后和反射颜色进行混合

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                fixed3 color = ambient + lerp(diffuse,reflection,_ReflectAmount) * atten;
                //在漫反射颜色和反射颜色之间做一个线性插值，根据_ReflectAmount来过渡。
                return fixed4(color,1.0);

            }

            ENDCG
        }
    }
}