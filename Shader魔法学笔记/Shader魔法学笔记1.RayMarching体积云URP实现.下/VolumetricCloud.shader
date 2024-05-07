Shader "RedSaw/VolumetricCloud"{
    
    Properties{
        // 着色器输入
        _MainTex("Main Texture", 2D) = "white"{}
    }
    SubShader{
        Tags{
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        pass{

            Cull Off
            ZTest Always
            ZWrite Off
            
            HLSLPROGRAM

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
                
                #pragma vertex Vertex
                #pragma fragment Pixel

                Texture2D _MainTex;
                SamplerState sampler_MainTex;

                float3 _BoundsMax;
                float3 _BoundsMin;
                
                sampler3D _DensityNoiseTex;
                float3 _DensityNoise_Scale;
                float3 _DensityNoise_Offset;
                float _DensityScale;

                sampler3D _DensityErodeTex;
                float3 _DensityErode_Scale;
                float3 _DensityErode_Offset;
                float _DensityErode;

                float2 _EdgeSoftnessThreshold;
                
                
                half4 _BaseColor;
                float _Absorption;
                float _LightAbsorption;
                float _LightPower;
                float3 _Sigma;
                float _HgPhaseG0;
                float _HgPhaseG1;

                struct vertexInput{
                    float4 vertex: POSITION;
                    float2 uv: TEXCOORD0;
                };
                struct vertexOutput{
                    float4 pos: SV_POSITION;
                    float2 uv: TEXCOORD0;
                };



                float2 rayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 rayDir){
                    /*  通过boundsMin和boundsMax锚定一个长方体包围盒
                        从rayOrigin朝rayDir发射一条射线，计算出射线到包围盒的距离
                        about ray box algorithm 
                        https://jcgt.org/published/0007/03/04/ */

                    float3 t0 = (boundsMin - rayOrigin) / rayDir;
                    float3 t1 = (boundsMax - rayOrigin) / rayDir;
                    float3 tmin = min(t0, t1);
                    float3 tmax = max(t0, t1);

                    float dstA = max(max(tmin.x, tmin.y), tmin.z);
                    float dstB = min(tmax.x, min(tmax.y, tmax.z));

                    float dstToBox = max(0, dstA);
                    float dstInsideBox = max(0, dstB - dstToBox);
                    return float2(dstToBox, dstInsideBox);
                }
                float HgPhaseFunction(float a, float g){
                    /* 亨利·格林斯坦相位函数，也就是HG相位函数 
                       r(a, g) = (1 - g^2)/(4pi * ( 1 + g^2 - 2ga )^1.5 )
                       其中a是入射光和视角方向的夹角，g是描述体积云（雾）的性质的常量参数, g为0时。
                       云向四面八方进行散射，所有方向散射结果一致，呈现各向同性。*/

                    float g2 = g * g;
                    return (1 - g2)/(12.56637 * pow(1 + g2 - 2 * g * a, 1.5));
                }
                float3 BeerPowder(float3 d, float a)
                {
                    return exp(-d * a) * (1 - exp(-d * 2 * a));
                }

                float sampleDensity(float3 position){

                    float3 uvw = position * _DensityNoise_Scale + _DensityNoise_Offset;
                    float density = tex3D(_DensityNoiseTex, uvw).r;

                    /* 对云团进行侵蚀 */
                    float3 erodeUVW = position * _DensityErode_Scale + _DensityErode_Offset;
                    float erode = tex3D(_DensityErodeTex, erodeUVW).r * _DensityErode;

                    /* 范围盒边缘衰减 */
                    float edgeToX = min(_EdgeSoftnessThreshold.x, min(position.x - _BoundsMin.x, _BoundsMax.x - position.x));
                    float edgeToZ = min(_EdgeSoftnessThreshold.x, min(position.z - _BoundsMin.z, _BoundsMax.z - position.z));
                    float edgeToY = min(_EdgeSoftnessThreshold.y, min(position.y - _BoundsMin.y, _BoundsMax.y - position.y));
                    float softness = edgeToX/ _EdgeSoftnessThreshold.x * edgeToZ / _EdgeSoftnessThreshold.x * edgeToY / _EdgeSoftnessThreshold.y;

                    /* 平方后可以使得衰减更为平滑，但是也造成了边缘显得比较模糊，
                     * 所以这里看情况可以进行注释 */
                    softness *= softness;

                    density = max(0, density - erode) * _DensityScale * softness * softness;
                    return density;
                }
                float LightPathDensity(float3 position, int stepCount){
                    /* sample density from given point to light 
                       within target step count */

                    // URP的主光源位置的定义名字换了一下
                    float3 dirToLight = _MainLightPosition.xyz;
                    
                    /* 这里的给传入的方向反向了一下是因为，rayBoxDst的计算是要从
                       目标点到体积，而采样时，则是反过来，从position出发到主光源 */
                    float dstInsideBox = rayBoxDst(_BoundsMin, _BoundsMax, position, 1/dirToLight).y;
                    
                    // 采样
                    float stepSize = dstInsideBox / stepCount;
                    float totalDensity = 0;
                    float3 stepVec = dirToLight * stepSize;
                    for(int i = 0; i < stepCount; i ++)
                    {
                        position += stepVec;
                        totalDensity += max(0, sampleDensity(position) * stepSize);
                    }
                    return totalDensity;
                }

                float3 GetWorldPosition(float3 positionHCS){
                    /* get world space position */

                    float2 UV = positionHCS.xy / _ScaledScreenParams.xy;
                    #if UNITY_REVERSED_Z
                        real depth = SampleSceneDepth(UV);
                    #else
                        real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                    #endif
                    return ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);
                }



                vertexOutput Vertex(vertexInput v){

                    vertexOutput o;
                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                    o.uv = v.uv;
                    return o;
                }
                half4 Pixel(vertexOutput IN): SV_TARGET{
                    
                    // 采样主纹理
                    half4 albedo = _MainTex.Sample(sampler_MainTex, IN.uv);

                    // 重建世界坐标
                    float3 worldPosition = GetWorldPosition(IN.pos);
                    float3 rayPosition = _WorldSpaceCameraPos.xyz;
                    float3 worldViewVector = worldPosition - rayPosition;
                    float3 rayDir = normalize(worldViewVector);

                    // 碰撞体积计算
                    float2 rayBoxInfo = rayBoxDst(_BoundsMin, _BoundsMax, rayPosition, rayDir);
                    float dstToBox = rayBoxInfo.x;
                    float dstInsideBox = rayBoxInfo.y;
                    float dstToOpaque = length(worldViewVector);
                    float dstLimit = min(dstToOpaque - dstToBox, dstInsideBox);

                    // 浓度和光照强度采样
                    int stepCount = 64;                                         // 采样的次数
                    float stepSize = dstInsideBox / stepCount;                  // 步进的长度
                    float3 stepVec = rayDir * stepSize;                         // 步进向量
                    float3 currentPoint = rayPosition + dstToBox * rayDir;      // 采样起点
                    float dstTravelled = 0.0;

                    
                    float3 lightIntensity = float3(0.0, 0.0, 0.0);
                    float transmittance = 1.0;

                    /* 基于双瓣亨利·格林斯坦相位函数模拟米氏散射 */
                    const float _costheta = dot(rayDir, _MainLightPosition.xyz);
                    const float phaseVal = lerp(
                        HgPhaseFunction(_costheta, _HgPhaseG0), 
                        HgPhaseFunction(_costheta, _HgPhaseG1), 
                        0.5
                    );
            
                    for(int i = 0; i < stepCount; i ++){
                        if(dstTravelled < dstLimit){

                            // 采样该点的云浓度记为Dx
                            float Dx = sampleDensity(currentPoint) * stepSize;
                            
                            /* 从主光源接受到的能量首先会被云层的吸收，于是乘以exp(-Dx * _LightAbsorption * _Sigma)
                             * 以及该点的云的浓度越高，越能接受足够的能量，于是乘以Dx
                             * 再乘以相位函数结果phaseVal赋予其针对观察视角的亮度差异 */
                            const float density_to_light = LightPathDensity(currentPoint, 8);
                            float3 energy = BeerPowder(density_to_light * _LightAbsorption * _Sigma, 6) * Dx * _Sigma * phaseVal;

                            /* 进行多次散射模拟，具体看下面的链接
                             * https://www.ea.com/frostbite/news/physically-based-sky-atmosphere-and-cloud-rendering */
                            const float sigma = _LightAbsorption * _Sigma;
                            energy = (energy - energy * BeerPowder(density_to_light * sigma, 6)) / sigma;
                            
                            /* 叠加散射能量和主世界的透射率 */
                            lightIntensity += energy * transmittance;
                            transmittance *= exp(-Dx * _Absorption);
                            
                            currentPoint += stepVec;
                            dstTravelled += stepSize;
                            continue;
                        }
                        break;
                    }
                    float3 cloudColor = _MainLightColor.xyz * lightIntensity * _BaseColor.xyz * _LightPower;
                    return half4(albedo * transmittance + cloudColor, 1);
                }
            ENDHLSL
        }
    }
}