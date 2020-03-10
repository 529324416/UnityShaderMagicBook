Shader "UShaderMagicBook/BumpMapTangentSpace_diffuse"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        //由于我们本次只计算漫反射，所以只需要_MainTex和_BaseColor
        
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
                float4 texcoord : TEXCOORD0;

                float4 tangent : TANGENT;
                //特别注意tangent虽然是法线，但是它是一个float4类型
                //xyz表示切线方向，而第四个分量w表示副切线的方向。如果副切线方向不对，那么
                //最终法线会反向
            };


            struct vertexOutput{

                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                //这里默认凹凸纹理和主纹理使用同一个uv坐标
                //并且我们不对它进行任何的缩放和偏移

                float3 lightDir : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _BumpTex;
            fixed4 _BaseColor;
            float _BumpScale;

            vertexOutput Vertex(vertexInput v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

                float3 binormal = cross(normalize(v.normal),normalize(v.tangent.xyz)) * v.tangent.w;
                //先计算副切线，就是把法线和切线进行叉积计算，然后乘以副切线的方向参数

                float3x3 _2tangentSpace = float3x3(v.tangent.xyz,binormal,v.normal);
                //按照切线，副切线，法线的顺序拼在一起就是切线空间的变换矩阵

                o.lightDir = mul(_2tangentSpace,ObjSpaceLightDir(v.vertex).xyz);
                //把光源方向转换到切线空间
                
                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 tangentLightDir = normalize(i.lightDir);

                fixed4 packedNormal = tex2D(_BumpTex,i.uv);
                //先对法线纹理进行采样，注意这个采样值暂时还不能用，需要映射

                fixed3 tangentNormal;
                //使用法线纹理中的法线值来代替模型原来的法线参与光照计算

                tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
                //作法线值的映射

                tangentNormal.z = packedNormal.z;
                //计算法线的z分量

                fixed3 albedo = tex2D(_MainTex,i.uv).xyz * _BaseColor.xyz;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.xyz * albedo * saturate(dot(tangentLightDir,tangentNormal));
                //计算漫反射

                return fixed4(diffuse + ambient,1.0);

            }



            ENDCG
        }
    }
}