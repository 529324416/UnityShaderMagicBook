Shader "UShaderMagicBook/Refract"{
    Properties{
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _RefractColor("Refract Color",Color) = (1.0,1.0,1.0,1.0)
        _RefractAmount("Refract Amount",Range(0,1)) = 1.0
        _RefractRatio("Refract Ratio",Range(0.1,1)) = 0.5
        //透射比不能为0
        _RefractTex("Refract Texture",Cube) = "skybox"{}
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
                float4 texcoord : TEXCOORD0;
            };

            struct vertexOutput{

                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float2 uv : TEXCOORD3;
                float3 worldRefractDir : TEXCOORD4;
                SHADOW_COORDS(5)
            };

            fixed4 _BaseColor;
            fixed4 _RefractColor;
            float _RefractAmount;
            float _RefractRatio;
            samplerCUBE _RefractTex;

            vertexOutput Vertex(vertexInput v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.texcoord;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldRefractDir = refract(normalize(o.worldViewDir),normalize(o.worldNormal),_RefractRatio);
                //通过refract函数来计算折射，由于斯尼尔定律中需要计算正弦函数，又我们的方向都是向量
                //所以这里需要进行正则化。
                TRANSFER_SHADOW(o)

                return o;
            }
            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 worldNormal = normalize(i.worldNormal);
                //fixed3 worldViewDir = normalize(i.worldViewDir);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _BaseColor.xyz;
                fixed3 diffuse = _LightColor0.xyz * _BaseColor.xyz * saturate(dot(worldNormal,lightDir));
                
                fixed3 refraction = texCUBE(_RefractTex,i.worldRefractDir) * _RefractColor.xyz;

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos)
                return fixed4(ambient + lerp(diffuse,refraction,_RefractAmount) * atten,1.0);
            }
            ENDCG
        }
    }
}