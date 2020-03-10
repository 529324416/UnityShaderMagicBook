Shader "UShaderMagicBook/RampTextureLight.shader"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
        _RampTex("Ramp Texture",2D) = "ramp"{}
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _Gloss("Gloss",Range(8,100)) = 20.0
    }
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
                float4 texcoord : TEXCOORD0;
            };

            struct vertexOutput{

                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            sampler2D _RampTex;
            fixed4 _BaseColor;
            float _Gloss;

            vertexOutput Vertex(vertexInput v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); //计算光源方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));   //计算视角方向
                fixed3 worldNormal = normalize(i.worldNormal);

                
                fixed halfLambert = 0.5 * dot(worldNormal,lightDir) + 0.5;
                //fixed halfLambert = saturate(dot(worldNormal,lightDir));
                fixed3 albedo = tex2D(_RampTex,fixed2(halfLambert,halfLambert)).xyz * _BaseColor.xyz * tex2D(_MainTex,i.uv).xyz;
                //正片叠底

                //以下代码用于计算光照
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.xyz * saturate(dot(worldNormal,lightDir)) * albedo;

                fixed3 halfDir = normalize(viewDir + lightDir);
                fixed3 specular = _LightColor0.xyz * pow(saturate(dot(halfDir,worldNormal)),_Gloss);


                return fixed4(diffuse + ambient + specular,1.0);

            }
            
            ENDCG
        }
    }
}