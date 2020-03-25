Shader "UShaderMagicBook/frameAnimation"{
    Properties{
        _MainTex("Animation Texture",2D) = "white"{}
        _BaseColor("BaseColor",Color) = (1.0,1.0,1.0,1.0)
        _XCount("XCount",Int) = 1
        _YCount("YCount",Int) = 1
        _Speed("Speed",Range(1,100)) = 30
    }
    SubShader{
        Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        pass{
            Tags{"LightMode"="Always"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            #pragma vertex Vertex
            #pragma fragment Pixel

            struct vertexOutput{

                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            fixed4 _BaseColor;
            int _XCount;
            int _YCount;
            float _Speed;

            vertexOutput Vertex(appdata_base v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }
            fixed4 Pixel(vertexOutput i):SV_TARGET{

                float time = floor(_Time.y * _Speed);
                //将时间乘上我们指定的缩放，这样就可以控制播放速度了

                float ypos = floor(time / _XCount);         
                float xpos = time - ypos * _XCount;
                //计算行索引与列索引

                i.uv.x = (i.uv.x + xpos) / _XCount;
                i.uv.y = 1 - (ypos + 1 - i.uv.y)/_YCount;
                //根据我们刚才计算出来的公式进行uv坐标的偏移和缩放

                fixed4 c = tex2D(_MainTex,i.uv);
                return c * _BaseColor;

            }
            ENDCG
        }
    }
}