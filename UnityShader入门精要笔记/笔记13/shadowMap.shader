Shader "UShaderMagicBook/ShadowMap"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _Gloss("Gloss",Range(8.0,200)) = 20.0
    }
    SubShader{
        pass{
            // this pass is a shadow map pass
            Tags{"LightMode"="ShadowCaster"}
            CGPROGRAM
            #pragma vertex VertexShadow
            #pragma fragment PixelShadow
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct vertexOutput_shadow{

                V2F_SHADOW_CASTER;
            };

            vertexOutput_shadow VertexShadow(appdata_base v){
                
                vertexOutput_shadow o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 PixelShadow(vertexOutput_shadow i):SV_TARGET{

                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
        pass{
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #pragma multi_compile_fwdbase
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

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
                SHADOW_COORDS(3)
                //Shadow_Coords声明一个uv坐标，只不过是对ShadowMap采样。
            };

            sampler2D _MainTex;
            fixed4 _BaseColor;
            float _Gloss;

            vertexOutput Vertex(vertexInput v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = v.texcoord;
                TRANSFER_SHADOW(o)    //转换阴影的uv坐标
                return o;
            }
            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed shadow = SHADOW_ATTENUATION(i);
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 albedo = tex2D(_MainTex,i.uv).xyz * _BaseColor.xyz;
                fixed3 diffuse = _LightColor0.xyz * albedo * saturate(dot(lightDir,worldNormal));
                fixed3 halfDir = normalize(viewDir + lightDir);
                fixed3 specular = _LightColor0.xyz * pow(saturate(dot(halfDir,worldNormal)),_Gloss);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 atten = 1.0;

                return fixed4(ambient + (specular + diffuse) * atten * shadow,1.0);
            }
    
            ENDCG
        }
        pass{
            Blend One One
            Tags{"LightMode"="ForwardAdd"}
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #pragma multi_compile_fwdadd_fullshadows
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

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
                SHADOW_COORDS(3)
                //Shadow_Coords声明一个uv坐标，只不过是对ShadowMap采样。
            };

            sampler2D _MainTex;
            fixed4 _BaseColor;
            float _Gloss;

            vertexOutput Vertex(vertexInput v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = v.texcoord;
                TRANSFER_SHADOW(o)    //转换阴影的uv坐标
                return o;
            }
            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed shadow = SHADOW_ATTENUATION(i);
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 albedo = tex2D(_MainTex,i.uv).xyz * _BaseColor.xyz;
                fixed3 diffuse = _LightColor0.xyz * albedo * saturate(dot(lightDir,worldNormal));
                fixed3 halfDir = normalize(viewDir + lightDir);
                fixed3 specular = _LightColor0.xyz * pow(saturate(dot(halfDir,worldNormal)),_Gloss);

                #ifdef USING_DIRECTIONAL_LIGHT

                    fixed atten = shadow;
                #else
                    #if defined(POINT)
                        //如果是点光源
                        float3 lightCoord = mul(unity_WorldToLight,float4(i.worldPos,1)).xyz;
                        fixed atten = tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL * shadow;
                    #elif defined(SPOT)
                        //如果是聚光灯
                        float4 lightCoord = mul(unity_WorldToLight,fixed4(i.worldPos,1));
                        fixed atten = shadow * (lightCoord.z > 0.05) * tex2D(_LightTexture0, lightCoord.xy/(lightCoord.w) + 0.5).w * tex2D(_LightTextureB0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #endif
                #endif
                //UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos)


                return fixed4((specular + diffuse) * atten,1.0);
            }
            ENDCG
        }

    }
}