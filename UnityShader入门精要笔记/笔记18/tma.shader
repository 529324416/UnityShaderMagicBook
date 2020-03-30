Shader "UShaderMagicBook/TMA"{
    Properties{
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _TileFactor("Tile Factor",Float) = 1
        _OutLine("OutLine",Range(0,1)) = 0.1
        _H1("Hatch 0",2D) = "white"{}
        _H2("Hatch 1",2D) = "white"{}
        _H3("Hatch 2",2D) = "white"{}
        _H4("Hatch 3",2D) = "white"{}
        _H5("Hatch 5",2D) = "white"{}
        _H6("Hatch 6",2D) = "white"{}

    }
    SubShader{
        pass{
            Tags{
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #pragma multi_compile_fwdbase
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct vertexOutput{

                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed3 hatchWeights0 : TEXCOORD1;
                fixed3 hatchWeights1 : TEXCOORD2;
                //注意，我们用两个fixed3变量来储存6个值
                float3 worldPos : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            fixed4 _BaseColor;
            float _TileFactor;
            fixed _OutLine;
            sampler2D _H1;
            sampler2D _H2;
            sampler2D _H3;
            sampler2D _H4;
            sampler2D _H5;
            sampler2D _H6;

            vertexOutput Vertex(appdata_base v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord.xy * _TileFactor;
                fixed3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed diff = saturate(dot(worldLightDir,worldNormal));

                o.hatchWeights0 = fixed3(0,0,0);
                o.hatchWeights1 = fixed3(0,0,0);

                float hatchFactor = diff * 7.0;         
                //将diff由[0,1]映射到[0,7],为了它可以方便的选择目标图片

                if(hatchFactor > 6.0){
                    //纯白色 do nothing;
                    //不需要一张图，所以这个权重可以直接用1 - 所有的权重获得。
                }else if(hatchFactor > 5.0){
                    o.hatchWeights0.x = hatchFactor - 5.0;
                    //如果diff的值是5.x，那么我们就用第一张图片与权重0.x来表达出5.x的亮度
                }else if(hatchFactor > 4.0){

                    o.hatchWeights0.x = hatchFactor - 4.0;
                    o.hatchWeights0.y = 1 - o.hatchWeights0.x;
                    //同上，只不过这里我们需要和一张相邻的图混合在一起。
                }else if (hatchFactor > 3.0){
                    o.hatchWeights0.y = hatchFactor - 3.0;
                    o.hatchWeights0.z = 1 - o.hatchWeights0.y;
                }else if(hatchFactor > 2.0){

                    o.hatchWeights0.z = hatchFactor - 2.0;
                    o.hatchWeights1.x = 1 - o.hatchWeights0.z;
                }else if(hatchFactor > 1.0){

                    o.hatchWeights1.x = hatchFactor - 1.0;
                    o.hatchWeights1.y = 1 - o.hatchWeights1.x;
                }else{

                    o.hatchWeights1.y = hatchFactor;
                    o.hatchWeights1.z = 1 - hatchFactor;
                }

                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                TRANSFER_SHADOW(o)

                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed4 hatchTex0 = tex2D(_H1,i.uv) * i.hatchWeights0.x;
                fixed4 hatchTex1 = tex2D(_H2,i.uv) * i.hatchWeights0.y;
                fixed4 hatchTex2 = tex2D(_H3,i.uv) * i.hatchWeights0.z;
                fixed4 hatchTex3 = tex2D(_H4,i.uv) * i.hatchWeights1.x;
                fixed4 hatchTex4 = tex2D(_H5,i.uv) * i.hatchWeights1.y;
                fixed4 hatchTex5 = tex2D(_H6,i.uv) * i.hatchWeights1.z;

                fixed4 whiteColor = fixed4(1,1,1,1) * (1 - i.hatchWeights0.x - i.hatchWeights0.y - i.hatchWeights0.z - i.hatchWeights1.x - i.hatchWeights1.y - i.hatchWeights1.z);
                fixed4 hatchColor = hatchTex0 + hatchTex1 + hatchTex2 + hatchTex3 + hatchTex4 + hatchTex5 + whiteColor;
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                return fixed4(hatchColor.xyz * _BaseColor.xyz * atten,1.0);
            }

                      
            ENDCG
        }
    }
}