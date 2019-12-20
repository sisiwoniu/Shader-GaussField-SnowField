Shader "Custom/Dissolve"
{
    Properties
    {
		[PerRendererData]
        _MainTex("Texture", 2D) = "white" {}

		[KeywordEnum(BlockNoise, ValueNoise, PerlinNoise)]
		_NoiseType("Noise Type", float) = 0

		[Toggle]
		_ShowAnim("Show Anim", float) = 0

		_NoiseColor("Noise Color", COLOR) = (0, 0, 0, 1)

		_Threshold("Threshold", Range(0, 1)) = 0

		_AlphaThreshold("Alpha Threshold", Range(0, 1)) = 0.2

		_AnimSpeed("Fade Speed", Range(0, 5)) = 1

		_Emission("Emission", Range(1, 10)) = 1

		_Seed("Seed", int) = 0

		_Size("Size", int) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

		Cull Back

		LOD 200

		Blend SrcAlpha OneMinusSrcAlpha
		
        Pass
        {
			Name "DISSOLVE"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#pragma multi_compile _NOISETYPE_BLOCKNOISE _NOISETYPE_VALUENOISE _NOISETYPE_PERLINNOISE

			#pragma shader_feature _SHOWANIM_ON

			#include "Assets/Shader/Cgincs/ShapeAndMathG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
            };

            sampler2D _MainTex;

			fixed4 _NoiseColor;

			fixed _Threshold;

			fixed _AlphaThreshold;

			fixed _AnimSpeed;

			fixed _Emission;

			int _Seed;

			int _Size;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.color = v.color;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
				fixed2 uv = i.uv;

				fixed4 col = tex2D(_MainTex, uv);

				fixed noiseRate;

				#ifdef _NOISETYPE_BLOCKNOISE

				noiseRate = abs(1 - random2D(floor(uv * max(_Size, 1)), _Seed));

				#elif _NOISETYPE_VALUENOISE

				noiseRate = abs(1 - valuenoise(uv * _Size));

				#elif _NOISETYPE_PERLINNOISE 

				noiseRate = perlinnoise(uv * _Size);

				#endif

				#ifdef _SHOWANIM_ON
				_Threshold = sin(_Time.y * _AnimSpeed);
				#endif

				//消える演出
				fixed rate = smoothstep(noiseRate, 0, _Threshold);

				_NoiseColor.a *= col.a;

				col = lerp(col, _NoiseColor * _Emission, 1 - (step(rate, _AlphaThreshold) - step(0.001, rate)));

				col.a *= step(rate, _AlphaThreshold);

                return col;
            }
            ENDCG
        }
    }
}
