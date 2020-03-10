Shader "UShaderMagicBook/BlinnPhongLight_0"{
    Properties{
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _Gloss("Gloss",Range(8.0,100.0)) = 20.0
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
            };

            struct vertexOutput{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            fixed4 _BaseColor;
            float _Gloss;

            vertexOutput Vertex(vertexInput v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                return o;
            }
            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 worldNormal = normalize(i.worldNormal);
                float3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                fixed3 halfDir = normalize(viewDir + worldLightDir);
                //半角向量的计算

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _BaseColor.xyz;
                fixed3 diffuse = _LightColor0.xyz * _BaseColor.xyz * saturate(dot(worldLightDir,worldNormal));
                fixed3 specular = _LightColor0.xyz * pow(saturate(dot(halfDir,worldNormal)),_Gloss);

                return fixed4(ambient + diffuse + specular,1.0);
            }


            ENDCG
        }
    }
}