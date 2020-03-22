Shader "UShaderMagicBook/GrabPassTest2"{
    Properties{
        
        _BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
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
            fixed4 _BaseColor;

            struct vertexOutput{
                
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD0;
            };

            vertexOutput Vertex(appdata_base v){

                vertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);

                #ifdef UNITY_UV_STARTS_AT_TOP
                    float scale = -1.0;
                #else
                    float scale = 1.0;
                #endif

                float4 _currentPos = o.pos * 0.5;
                _currentPos.xy = float2(_currentPos.x,_currentPos.y * scale) + _currentPos.w;
                _currentPos.zw = o.pos.zw;
                o.screenPos = _currentPos;

                return o;
            }

            fixed4 Pixel(vertexOutput i):SV_TARGET{

                fixed3 color = tex2D(_GrabPassTexture,i.screenPos.xy/i.screenPos.w).xyz * _BaseColor.xyz;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}