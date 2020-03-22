Shader "UShaderMagicBook/Glass"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
        _BumpTex("Normal Map",2D) = "bump"{}
        _CubeMap("Cubemap",Cube) = "skybox"{}
        _Distortion("Distortion",Range(0,100)) = 10
        _RefractAmount("Refract Amount",Range(0,1)) = 1.0
        //其中_MainTex是玻璃的主纹理，_BumpTex是玻璃的法线纹理
        //Cubemap是玻璃的反射纹理，而_Distortion是变形系数
        //_RefractAmount是折射系数
    }

    SubShader{
        Tags{"Queue"="Transparent" "RenderType"="Opaque"}
        /*这里的Queue设置为Transparent和RenderType设置为Opaque*/
        GrabPass{"_RefractionTex"}
        //GrabPass会把模型后面的内容捕捉，塞进一张纹理中。我们只需要指定纹理的变量名即可
        pass{
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            sampler2D _MainTex;
            sampler2D _BumpTex;
            samplerCUBE _CubeMap;
            float _Distortion;
            fixed _RefractAmount;
            sampler2D _RefractionTex;
            //即使GrabPass，也要声明，不然没有地方填充变量
            float4 _RefractionTex_TexelSize;
            //Unity会把一个纹理的大小填充到一个叫
            //纹理名_TexelSize   变量中，使用之前要声明

            struct vertexInput{

                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct vertexOutput{

                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 scrPos : TEXCOORD1;
                float4 TW1 : TEXCOORD2;
                float4 TW2 : TEXCOORD3;
                float4 TW3 : TEXCOORD4;
            };

            vertexOutput Vertex(vertexInput v){
                
                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

                o.scrPos = ComputeGrabScreenPos(o.pos);
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

                o.TW1 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TW2 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TW3 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
                /* 计算切线空间转世界空间矩阵，记住是切线转世界*/

                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                float3 worldPos = float3(i.TW1.w,i.TW2.w,i.TW3.w);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                fixed3 bump = UnpackNormal(tex2D(_BumpTex,i.uv));
                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                i.scrPos.xy += offset;

                fixed3 refractColor = tex2D(_RefractionTex,i.scrPos.xy/i.scrPos.w).xyz;

                bump = normalize(half3(dot(i.TW1.xyz,bump),dot(i.TW2.xyz,bump),dot(i.TW3.xyz,bump)));
                fixed3 reflectDir = reflect(-worldViewDir,bump);
                fixed4 texColor = tex2D(_MainTex,i.uv);
                fixed3 relfectColor = texCUBE(_CubeMap,reflectDir).xyz * texColor.xyz;

                fixed3 finalColor = lerp(relfectColor,refractColor,_RefractAmount);
                return fixed4(finalColor,1);
            }
            ENDCG
        }
    }
}