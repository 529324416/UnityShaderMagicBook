Shader "UShaderMagicBook/GrabPassTest"{
    Properties{
        //none of any input
    }
    SubShader{
        Tags{"Queue"="Transparent" "RenderType"="Opaque"}
        GrabPass{"_GrabPassTexture"}

        pass{
            Tags{"LightMode"="Always"}
            //不论什么情况下，这个pass总会被绘制

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            #include "UnityCG.cginc"

            sampler2D _GrabPassTexture;
            float4 _GrabPassTexture_TexelSize;

            struct vertexOutput{
                
                float4 pos : SV_POSITION;
                float2 uv :TEXCOORD0;
            };

            vertexOutput Vertex(appdata_base v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                return tex2D(_GrabPassTexture,i.uv);
            }
            ENDCG
        }
    }
}