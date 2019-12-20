Shader "Unlit/SpriteWave"
{
    Properties
    {
		[PerRendererData]
        _MainTex("Texture", 2D) = "white" {}
		_Dist("Dist", Range(0, 1)) = 0
		[HDR]
		_LineCol("LineCol", Color) = (1, 1, 1, 1)
		_LineColDist("LineColDist", Range(0, 0.2)) = 0
		_WaveSpeed("WaveSpeed", Range(0, 10)) = 1
		_Height("WaveHeight", Range(0.01, 1)) = 0.1
		_WavePower("WavePower", Range(1, 20)) = 4
		[KeywordEnum(Up, Bottom, Right, Left)]
		_Dir("Dir", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" "IgnoreProjector"="True" "CanUseSpriteAtlas"="True" }
        
		ZWrite Off

		ZTest Always

		Lighting Off

		Cull Back

		Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma shader_feature _DIR_UP _DIR_RIGHT _DIR_BOTTOM _DIR_LEFT

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				fixed4 col : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				fixed4 col : COLOR;
            };

            sampler2D _MainTex;
			fixed _Dist;
			fixed4 _LineCol;
			fixed _LineColDist;
			fixed _WaveSpeed;
			fixed _Height;
			fixed _WavePower;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.col = v.col;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * i.col;

				fixed2 uv = i.uv;

				//波計算するための係数、方向により変わる
				fixed waveNum = uv.x;

				//方向によりUVを調整
#if _DIR_UP
				uv.x = 0;
#elif _DIR_BOTTOM
				uv.x = 0;

				uv.y = 1 - uv.y;
#elif _DIR_RIGHT
				waveNum = uv.y;

				uv.y = 0;
#elif _DIR_LEFT
				waveNum = uv.y;

				uv.y = 0;

				uv.x = 1 - uv.x;
#endif
				//もともとの画像の表示長さ
				fixed dist = distance(fixed2(0, 0), uv);

				fixed wave = sin(waveNum * _WavePower + _Time.y * _WaveSpeed) * _Height;

				//波を作るための距離
				fixed _dist = _Dist * wave + _Dist;

				fixed v = step(dist, _dist);

				fixed2 gradStartPoint = fixed2(0, 0);

				//グラデーションの開始点も方向により変わる
#if _DIR_UP || _DIR_BOTTOM
				gradStartPoint.y = _dist;
#else
				gradStartPoint.x = _dist;
#endif

				//グラデーションの長さ
				fixed dist2 = distance(gradStartPoint, uv);

				fixed v2 = step(dist2, _LineColDist);

				//グラデーションをかける
				fixed3 lineCol = lerp(_LineCol.rgb, fixed3(0, 0, 0), dist2);

				col.rgb += lineCol * _LineCol.a * v2 * abs(_LineColDist - dist2);

				col.a *= v;

                return col;
            }
            ENDCG
        }
    }
}
