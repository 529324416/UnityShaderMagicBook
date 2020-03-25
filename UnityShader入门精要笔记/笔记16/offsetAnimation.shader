Shader "UShaderMagicBook/offsetAnimation"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
        _XSpeed("X Axis Speed",Float) = 1.0
        _YSpeed("Y Axis Speed",Float) = 1.0
    }
    SubShader{
        pass{
            Tags{"LightMode"="Always"}
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #include "UnityCG.cginc"

            struct vertexOutput{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float _XSpeed;
            float _YSpeed;

            vertexOutput Vertex(appdata_base v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                float2 offset = float2(_Time.y * _XSpeed,_Time.y * _YSpeed);
                //根据水平和纵向的偏移速度计算出总得偏移

                i.uv += offset;
                //设置偏移

                return tex2D(_MainTex,i.uv);
                //采样并返回
            }
            ENDCG
        }
    }

}