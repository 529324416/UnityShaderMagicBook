Shader "UShaderMagicBook/bumpMapWorldSpace_diffuse"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _BumpTex("Bump Texture",2D) = "bump"{}
        _BumpScale("Bump Scale",Float) = 1.0
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
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct vertexOutput{

                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 TtoW1 : TEXCOORD1;
                float4 TtoW2 : TEXCOORD2;
                float4 TtoW3 : TEXCOORD3;
            };

            sampler2D _MainTex;
            sampler2D _BumpTex;
            float _BumpScale;
            fixed4 _BaseColor;

            vertexOutput Vertex(vertexInput v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

                //得到切线空间的逆矩阵，由于该矩阵只有线性变换，所以矩阵的逆矩阵就是它的转置矩阵
                o.TtoW1 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW2 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW3 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                float3 worldPos = float3(i.TtoW1.w,i.TtoW2.w,i.TtoW3.w);        //先取出模型的世界坐标
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos)); //计算光源方向

                fixed3 bump = UnpackNormal(tex2D(_BumpTex,i.uv));
                bump.xy *= _BumpScale;
                //这个Bump目前是切线空间的哦(/ ~ \)

                bump = normalize(
                    float3(dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump),dot(i.TtoW3.xyz,bump))
                );
                //和一个矩阵相乘就相当于和一个列向量组的每个向量相乘后组合在一起。

                //以下代码用于计算光照

                fixed3 albedo = _BaseColor.xyz * tex2D(_MainTex,i.uv).xyz;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                fixed3 diffuse = _LightColor0.xyz * albedo * saturate(dot(bump,lightDir));

                return fixed4(diffuse + ambient,1.0);

            }
            
            ENDCG
        }
    }
}