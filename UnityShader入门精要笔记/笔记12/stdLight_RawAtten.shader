Shader "UShaderMagicBook/StdLight_RawAtten"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _Gloss("Gloss",Range(8.0,200.0)) = 20.0
    }
    SubShader{
        Tags{"Queue"="Geometry"}
        Pass{
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #pragma vertex Vertex
            #pragma fragment Pixel
            #pragma multi_compile_fwdbase       //一定要有这个编译指令

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
            float _Gloss;

            vertexOutput Vertex(vertexInput v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.texcoord;

                return o;
            }
            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                //BasePass和之前计算光照没有差别

                fixed3 albedo = tex2D(_MainTex,i.uv).xyz * _BaseColor.xyz;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                //环境光只需要计算一次就行了

                fixed3 diffuse = _LightColor0.xyz * albedo * saturate(dot(lightDir,worldNormal));

                fixed3 halfDir = normalize(viewDir + lightDir);
                fixed3 specular = _LightColor0.xyz * pow(saturate(dot(halfDir,worldNormal)),_Gloss);

                fixed atten = 1.0;
                //由于平行光没有光照衰减，所以光照衰减为1

                return fixed4(ambient + (specular + diffuse) * atten,1.0);
                //计算光照衰减
            }
            ENDCG
        }
        
        Pass{
            Tags{"LightMode"="ForwardAdd"}

            Blend One One
            //一定要开启混合，设置线性混合，不然其他光源的光不能附加
            CGPROGRAM
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #pragma vertex Vertex
            #pragma fragment Pixel
            #pragma multi_compile_fwdadd       //一定要有这个编译指令

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
            float _Gloss;

            vertexOutput Vertex(vertexInput v){
                //顶点着色器依旧不变，因为这里和模型的外形没有啥关系

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.texcoord;

                return o;
            }
            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 worldNormal = normalize(i.worldNormal);
                //第一个不同的可能就是光照的方向，因为平行光的光照方向可以直接用位置代替，然而
                //其他光源不行。

                #ifdef USING_DIRECTIONAL_LIGHT
                    //这个宏指令的意思是如果照射该物体的光源是一个平行光

                    fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    //如果不是平行光，那么光照方向为光源位置减模型位置

                    fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
                #endif
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                //视角方向是不变的

                //BasePass和之前计算光照没有差别

                fixed3 albedo = tex2D(_MainTex,i.uv).xyz * _BaseColor.xyz;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                //环境光只需要计算一次就行了

                fixed3 diffuse = _LightColor0.xyz * albedo * saturate(dot(lightDir,worldNormal));

                fixed3 halfDir = normalize(viewDir + lightDir);
                fixed3 specular = _LightColor0.xyz * pow(saturate(dot(halfDir,worldNormal)),_Gloss);


                #ifdef USING_DIRECTIONAL_LIGHT
                    //这个宏指令的意思是如果照射该物体的光源是一个平行光

                    fixed atten = 1.0;   // 平行光没有光照衰减
                #else
                    //如果不是平行光，光照衰减可以用下面这种方式计算出来。

                    // #if defined(POINT)
                    //     //如果是点光源
                    //     float3 lightCoord = mul(unity_WorldToLight,float4(i.worldPos,1)).xyz;
                    //     fixed atten = tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    // #elif defined(SPOT)
                    //     //如果是聚光灯
                    //     float4 lightCoord = mul(unity_WorldToLight,float4(i.worldPos,1));
                    //     fixed atten=(lightCoord.z>0)*tex2D(_LightTexture0,lightCoord.xy/lightCoord.w+0.5).w*tex2D(_LightTextureB0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    // #endif
                    float _distance = distance(_WorldSpaceLightPos0.xyz,i.worldPos);    //先计算距离
                    fixed atten = 1.0/_distance;
                #endif

                return fixed4(ambient + (specular + diffuse) * atten,1.0);
                //计算光照衰减
            }

            ENDCG
        }
    }
}