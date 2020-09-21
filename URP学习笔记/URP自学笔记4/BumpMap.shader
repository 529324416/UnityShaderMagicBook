Shader "URPNotes/BumpMap"{
    Properties{
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
        _MainTex("Main Texture",2D) = "white"{}
        _BumpTex("Bump Texture",2D) = "white"{}
        _BumpScale("Bump Scale",Float) = 1.0
        _Gloss("Gloss",Float) = 1.0
    }
    SubShader{
        Tags{
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalRenderPipeline"
        }
        pass{
            HLSLPROGRAM
                #pragma vertex Vertex
                #pragma fragment Pixel
                
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);

                TEXTURE2D(_BumpTex);
                SAMPLER(sampler_BumpTex);

                CBUFFER_START(UnityPerMaterial)
                    float _BumpScale;
                    float4 _MainTex_ST;
                    float4 _BumpTex_ST;
                    half4 _BaseColor;
                    float _Gloss;
                CBUFFER_END

                struct vertexInput{

                    float4 vertex:POSITION;
                    float3 normal:NORMAL;
                    float2 uv_MainTex:TEXCOORD0;
                    float2 uv_BumpTex:TEXCOORD1;
                    float4 tangent:TANGENT;
                    //注意tangent是float4类型，因为其w分量是用于控制切线方向的。
                };

                struct vertexOutput{

                    float4 pos:SV_POSITION;
                    float2 uv_MainTex:TEXCOORD0;
                    float2 uv_BumpTex:TEXCOORD1;
                    float4 TW1:TEXCOORD2;
                    float4 TW2:TEXCOORD3;
                    float4 TW3:TEXCOORD4;
                };

                vertexOutput Vertex(vertexInput v){

                    vertexOutput o;
                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                    float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                    float3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
                    float3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

                    float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                    //计算世界法线，世界切线和世界副切线

                    o.uv_MainTex = TRANSFORM_TEX(v.uv_MainTex,_MainTex);
                    o.uv_BumpTex = TRANSFORM_TEX(v.uv_BumpTex,_BumpTex);
                    //计算采样坐标

                    o.TW1 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                    o.TW2 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                    o.TW3 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
                    return o;
                }

                half4 Pixel(vertexOutput i):SV_TARGET{

                    /* 提取在顶点着色器中的数据 */
                    float3x3 TW = float3x3(i.TW1.xyz,i.TW2.xyz,i.TW3.xyz);
                    float3 worldPos = half3(i.TW1.w,i.TW2.w,i.TW3.w);
                    
                    /* 先计算最终的世界法线 */
                    float4 normalTex = SAMPLE_TEXTURE2D(_BumpTex,sampler_BumpTex,i.uv_BumpTex);        //对法线纹理采样
                    float3 bump = UnpackNormal(normalTex);                              //解包，也就是将法线从-1,1重新映射回0,1
                    bump.xy *= _BumpScale;
                    bump.z = sqrt(1.0 - saturate(dot(bump.xy,bump.xy)));
                    //这个z的计算是因为法线仅存储x和y信息，而z可以由x^2 + y^2 + z^2 = 1反推出来。（法线是单位矢量）
                    bump = mul(TW,bump);             //将切线空间中的法线转换到世界空间中

                    /*计算纹理颜色*/
                    Light light = GetMainLight();
                    half3 albedo = _BaseColor.xyz * SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv_MainTex).xyz * light.color.xyz;

                    /*计算漫反射光照*/
                    half3 lightDir = TransformObjectToWorldDir(light.direction);
                    half3 diffuse = albedo * saturate(dot(lightDir,bump));

                    /*计算Blinn-Phong高光*/
                    half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
                    half3 halfDir = normalize(viewDir + lightDir);
                    half3 specular = pow(saturate(dot(halfDir,bump)),_Gloss) * albedo;
                    

                    return half4(diffuse + UNITY_LIGHTMODEL_AMBIENT.xyz * albedo + specular,1);
                }
            ENDHLSL
        }
    }
}