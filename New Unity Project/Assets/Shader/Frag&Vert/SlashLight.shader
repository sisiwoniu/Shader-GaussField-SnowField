Shader "Custom/SlashLight"
{
	Properties
	{
		[PerRendererData]
		_MainTex("Texture", 2D) = "white" {}

		_SlashWidth("Slash Width", Range(0, 1)) = 0.1

		_SlashColor("Slash Color", Color) = (1, 1, 1, 1)

		[HideInInspector]
		_t("T", float) = -2
	}
	SubShader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }

		Cull Back

		Blend SrcAlpha OneMinusSrcAlpha

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
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
			};

			sampler2D _MainTex;
			fixed4 _SlashColor;
			fixed _SlashWidth;
			fixed _t;

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
				fixed4 col = tex2D(_MainTex, i.uv) * i.color;

				fixed b_x = 1 - i.uv.y;

				fixed now_x = i.uv.x + _t;

				fixed dist = distance(b_x, now_x);

				col.rgb = _SlashColor.rgb * smoothstep(0, dist, _SlashWidth) * _SlashColor.a * col.a + col.rgb;

				return col;
			}
			ENDCG
		}
	}
}