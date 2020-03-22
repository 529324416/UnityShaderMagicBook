Shader "UShaderMagicBook/FresnelReflection_schlick"{
    Properties{
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _FresnelScale("Fresnel Scale",Range(0,1)) = 0.5
        _Cubemap("Cubemap",Cube) = "skybox"{}
    }
    SubShader{
        pass{
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct vertexInput{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct vertexOutput{

                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldReflectDir : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            fixed4 _BaseColor;
            fixed _FresnelScale;
            samplerCUBE _Cubemap;

            vertexOutput Vertex(vertexInput v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldReflectDir = reflect(-o.worldViewDir,o.worldNormal);

                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _BaseColor.xyz;
                fixed3 diffuse = _LightColor0.xyz * _BaseColor.xyz * saturate(dot(worldNormal,lightDir));

                float fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldNormal,worldViewDir),5);
                //schlick菲涅尔反射计算公式
                fixed3 reflection = texCUBE(_Cubemap,i.worldReflectDir).xyz;
                
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                fixed3 color = ambient + lerp(diffuse,reflection,saturate(fresnel)) * atten;
                //注意我们这里是把菲涅尔反射系数作为线性插值的权重在物体原本的漫反射颜色和反射颜色之间进行过度
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}