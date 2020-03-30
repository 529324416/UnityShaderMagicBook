Shader "UShaderMagicBook/ToonShading1"{
    Properties{
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _Ramp("Ramp Texture",2D) = "white"{}        //渐变纹理
        _OutLine("Outline",Range(0,1)) = 0.1        //控制轮廓线大小
        _OutLineColor("OutLine Color",Color) = (1.0,1.0,1.0,1.0)
        _SpecularColor("Specular Color",Color) = (1.0,1.0,1.0,1.0)  //高光颜色
        _SpecularScale("Specular Scale",Range(0,0.1)) = 0.01        //控制高光区域的阈值
    }

    SubShader{
        pass{
            NAME "OUTLINE"      //给这个pass起一个名字
            /*因为描边一直是一个比较常用的效果，所以命名之后，我们后续只需要引用这个名字即可 
            通过UsePass指令*/

            Cull Front //我们只需要渲染三角面的背面，不需要渲染正面，所以把正面剔除掉。

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #include "UnityCG.cginc"

            fixed _OutLine;
            fixed4 _OutLineColor;

            float4 Vertex(appdata_base v):SV_POSITION{

                float3 _pos = UnityObjectToViewPos(v.vertex.xyz);
                float4 pos = float4(_pos,1);
                //将顶点转换到视角空间

                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV,v.normal);
                //将法线转换到视角空间

                normal.z = -0.5;
                pos = pos + float4(normalize(normal) * _OutLine,0);
                return UnityViewToClipPos(pos);
            }

            fixed4 Pixel():SV_TARGET{

                return float4(_OutLineColor.xyz,1);
            }
            ENDCG
        }

        pass{
            Tags{"LightMode"="ForwardBase"}
            Cull Back

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #pragma multi_compile_fwdbase

            #include "AutoLight.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct vertexOutput{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            fixed4 _BaseColor;
            sampler2D _Ramp;
            fixed4 _SpecularScale;
            fixed4 _SpecularColor;


            vertexOutput Vertex(appdata_base v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldHalfDir = normalize(worldViewDir + worldLightDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _BaseColor.xyz;

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                //漫反射计算部分
                fixed diff = dot(worldNormal,worldLightDir);
                diff = (diff * 0.5 + 0.5) * atten;
                //这个就是广义兰伯特公式，只不过alpha算子和beta算子都设为了0.5
                fixed3 diffuse = _LightColor0.xyz * _BaseColor.xyz * tex2D(_Ramp,float2(diff,diff)).xyz;
                

                //高光计算部分
                fixed specular = dot(worldHalfDir,worldNormal);
                fixed w = fwidth(specular) * 2.0;
                specular = _SpecularColor.xyz * lerp(0,1,smoothstep(-w,w,specular + _SpecularScale - 1)) * step(0.0001,_SpecularScale);

                return fixed4(ambient + diffuse + specular,1.0);
            }

            ENDCG
        }
    }
}