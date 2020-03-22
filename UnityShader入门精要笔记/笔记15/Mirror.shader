Shader "UShaderMagicBook/Mirror"{
    Properties{
        _MainTex("Main Texture",2D) = "white"{}
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

            vertexOutput Vertex(appdata_base v){
                
                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.uv.x = 1 - o.uv.x;
                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                return tex2D(_MainTex,i.uv);
            }
            ENDCG
        }
    }
}