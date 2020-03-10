Shader "UShaderMagicBook/PhongLight_0"{
    Properties{
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
            };

            struct vertexOutput{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;   //需要模型的世界坐标位置，才可以计算视角方向
            };

            fixed4 _BaseColor;
            float _Gloss;

            vertexOutput Vertex(vertexInput v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;     //由于vertex是一个4x4类型变量，所以我们取xyz

                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{
                
                fixed3 worldNormal = normalize(i.worldNormal);      //别忘记标准化
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 reflectDir = reflect(-worldLightDir,worldNormal);
                //注意reflect函数的第一个参数才是光源，第二个是法线

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                //视角方向可以通过内置的函数UnityWorldSpaceViewDir来计算，无需自己计算
                //不要忘记标准化！！！

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _BaseColor.xyz;      //先获取环境光
                fixed3 diffuse = _LightColor0.xyz * _BaseColor.xyz * saturate(dot(worldNormal,worldLightDir));
                //这里我们用了一个新的函数saturate，它的作用和max类似，也是把目标参数约束到0-1的范围内

                fixed3 specular = _LightColor0.xyz * pow(saturate(dot(viewDir,reflectDir)),_Gloss);
                //利用Phong模型中的高光公式来计算高光

                return fixed4(specular + ambient + diffuse,1.0);

            }

            ENDCG
        }
    }
}