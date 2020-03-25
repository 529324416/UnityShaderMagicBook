Shader "UShaderMagicBook/vertexAnimation"{
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
                v.vertex.y += sin(_Time.y + v.vertex.x * _XSpeed + v.vertex.z * _YSpeed);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                return tex2D(_MainTex,i.uv);
            }
            ENDCG
        }
    }

}