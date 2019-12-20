// Original Gameboy RGB Colors :
			   // 15, 56, 15
			   // 48, 98, 48
			   // 139, 172, 15
			   // 155, 188, 15

Shader "Hidden/GameBoy"
{
    Properties
    {
		[PerRendererData]
        _MainTex("Texture", 2D) = "white" {}

		_PixelSize("Pixel Size", float) = 1
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
			fixed _PixelSize;
			fixed _RevPixelSize;
			fixed4 _LightestColor;
			fixed4 _LightColor;
			fixed4 _DarkColor;
			fixed4 _DarkestColor;

            fixed4 frag(v2f i) : SV_Target
            {
				fixed2 uv = i.uv;

				uv.x = ceil(uv.x * _RevPixelSize) * _PixelSize;
				
				uv.y = ceil(uv.y * _RevPixelSize) * _PixelSize;

                fixed4 col = tex2D(_MainTex, uv);

				//グレースケールにする
				col = dot(col.rgb, float3(0.3, 0.59, 0.11));

				if(col.r <= 0.25) {
					col = _DarkestColor;
				}
				else if(col.r > 0.75) {
					col = _LightestColor;
				}
				else if(col.r <= 0.5) {
					col = _DarkColor;
				}
				else {
					col = _LightColor;
				}

                return col;
            }
            ENDCG
        }
    }
}
