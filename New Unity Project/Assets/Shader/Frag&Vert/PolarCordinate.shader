Shader "Unlit/PolarCordinateRotate"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}

		[HDR]
		_Color("Color", Color) = (1, 1, 1, 1)

		_SSpeed("Change Scale Speed", Range(0, 30)) = 1

		_RSpeed("Rotate Speed", Range(0, 30)) = 1

		_WaveSpeed("Wave Speed", Range(0.1, 10)) = 1

		_Scale("Scale", Range(1, 10)) = 1

		[Toggle]
		_Reversal("ReverSal", float) = 1

		[Toggle]
		_ChangeCAlpha("Change Center Alpha", float) = 1

		[Toggle]
		_UseWaveNoise("Use Wave Noise", float) = 1

		[Toggle(LAND_SCAPE_ON)]
		_LandScape("LandScape", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" }

		Cull Off

		Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#pragma shader_feature LAND_SCAPE_ON

			#include "Assets/Shader/Cgincs/ShapeAndMathG.cginc"

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
            float4 _MainTex_ST;
			fixed4 _Color;
			fixed _SSpeed, _RSpeed, _Reversal, _ChangeCAlpha, _Scale;
			fixed _UseWaveNoise, _WaveSpeed;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
				#ifdef LAND_SCAPE_ON
				
				i.uv = screenAspect(i.uv);
				
				#endif

				//歪み
				fixed distort = distortionXType1(i.uv, _WaveSpeed) * _UseWaveNoise;

				//座標系を極座標系に変更、x = ベクトル長さ y = 角度
				fixed2 uv = convertPolarCordinate(i.uv);

				fixed _r = _Reversal * 2 - 1;

				uv.x += _SSpeed * _Time.x * _r;

				uv.y += _RSpeed * _Time.x * _r + distort;

                fixed4 col = tex2D(_MainTex, uv) * _Color;

				col.a *= lerp(lerp(1, 0.25, _ChangeCAlpha), 1, distance(i.uv * _Scale, 0.5 * _Scale));

                return col;
            }
            ENDCG
        }
    }
}
