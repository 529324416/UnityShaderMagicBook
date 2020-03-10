Shader "UShaderMagicBook/PerVertexLambertLight_0"{
    /*不带有颜色参数的兰伯特光照模型*/

    Properties{
        /* 暂时不需要任何输入 */
    }
    SubShader{
        /*如果是在SubShader中设定Tags，则在所有的Pass中通用
        但是并不是所有的标签都可以在SubShader中使用，就比如LightMode是针对pass的*/

        pass{
            Tags{"LightMode"="ForwardBase"}
            /* 在pass块中设定的的标签只能在Tags中有效，如果pass中出现了和SubShader
            中同样的标签，则会覆盖SubShader中的标签。
            此处我们使用了ForwardBase，也就是这个光照模型只对平行光有效*/

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            //设定顶点着色器的入口和片元着色器入口，类似于设定主函数一样
            
            #include "Lighting.cginc"
            /*引用Unity自己定义的着色器头文件（并非真实的头文件，只是方便理解这么说而已），
            你也可以编写自己的着色器头文件，而Unity内置的头文件可以在~/Unity3d/Editor/Data/CGIncludes中找到*/

            struct vertexInput{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                //通过NORMAL语义来获得模型表面发线
                //注意这个法线是模型空间的法线，要计算的话，需要先转到世界空间
            };

            struct vertexOutput{
                float4 pos : SV_POSITION;
                float4 color : COLOR;
                //由于在顶点着色器中计算光照，计算完后要传递给片元着色器
                //所以使用COLOR语义来存储颜色信息
            };

            vertexOutput Vertex(vertexInput v){
                //顶点着色器的的输入一定要用v作为变量名，用o作为输出名，
                //理由等到时候自然就明白了
                /*计算兰伯特光照模型*/

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);     //顶点着色器一定要做的事情
                
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldNormalStd = normalize(worldNormal);
                /*第一行主要是把模型空间的法线通过Unity的内置函数
                UnityObjectToWorldNormal函数转到世界空间中
                第二行主要是把法线给标准化*/

                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                /*由于平行光它没有位置概念，只有方向概念，（因为它不论在哪，强度都一样，所以只有方向）
                因而它的位置就可以代表它的方向，（在线性代数中，一个顶点减去原点坐标(0,0,0)，就是从原点
                指向它的一条方向），该部分如果理解不了，说明需要补一补线性代数或者立体几何了*/

                fixed3 diffuse = _LightColor0.xyz * max(0,dot(worldNormal,worldLightDir));

                o.color = fixed4(diffuse,1.0);
                //注意o.color是fixed4类型
                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{
                /*不需要计算任何东西*/

                return i.color;
            }

            ENDCG
        }
    }
}