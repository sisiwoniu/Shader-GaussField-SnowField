Shader "Custom/LoadingEffect"
{
    Properties
    {
		[PerRendererData]
        _MainTex ("Texture", 2D) = "white" {}
		
		[MaterialToggle]
		_InverseAlpha("Inverse Alpha", Float) = 1

		_Value("Value", Range(-0.1, 1)) = 1

		_Scale("Scale", Range(1, 1000)) = 1

		_Width("Width", Range(0, 1)) = 0.1

		_Dir("Dir x y", Vector) = (1, 1, 0, 0)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" }
        LOD 100

		Blend SrcAlpha OneMinusSrcAlpha

		ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

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

            sampler2D _MainTex;

			fixed _Scale, _Value, _Width, _InverseAlpha;

			float2 _Dir;

			float circle(fixed2 Pos) 
			{
				return dot(Pos, Pos);
			}

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
				fixed2 uv = i.uv * fixed2(_Scale, _Scale * (_ScreenParams.y / _ScreenParams.x));
				
                fixed4 col = tex2D(_MainTex, i.uv);

				fixed2 i_uv = floor(uv);

				fixed2 f_uv = frac(uv) * 2 - 1;

				//円の拡大方向
				float2 dir = normalize(_Dir);

				//符号を取得
				float2 sg = sign(dir);

				fixed val = (_Value + 0.1) * (dot(uv - 1, abs(dir)) * _Width + 2);

				float a = 1;

				for(int i = -1; i <= 1; i++) {
					for(int j = -1; j <= 1; j++) {
						float2 f = (uv - 1) * (0.5 - sg * 0.5) + (i_uv + fixed2(i, j)) * sg;
						
						fixed c = circle(f_uv - fixed2(2 * i, 2 * j));

						fixed v = val - dot(f, abs(dir)) * _Width;

						a = min(a, step(v, c));
					}
				}

				col.a = _InverseAlpha - a * (_InverseAlpha * 2 - 1);

                return col;
            }
            ENDCG
        }
    }
}
