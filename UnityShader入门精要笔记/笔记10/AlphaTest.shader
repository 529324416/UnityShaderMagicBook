Shader "UShaderMagicBook/AlphaTest"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _Alpha("Alpha Threshold",Range(0,1)) = 0
    }

    SubShader{
        Tags{"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        //AlphaTest规定了使用了该着色器的物体的渲染顺序，并且它现在忽略投影器的影响（IgnoreProjector）
        //最后它会被归纳到Unity提前定义好的组当中，TransparentCutout指的就是使用了透明度测试的着色器
        pass{
            Tags{"LightMode"="ForwardBase"}
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
            fixed _Alpha;

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
                
                fixed4 texColor = tex2D(_MainTex,i.uv);
                clip(texColor.a - _Alpha);
                //把透明度低于_Alpha的像素全部都剔除掉;

                fixed3 albedo = texColor.xyz * _BaseColor.xyz;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.xyz * albedo * saturate(dot(worldNormal,lightDir));

                return fixed4(diffuse + ambient,1.0);
            }

            ENDCG
        }
    }
}