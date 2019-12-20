Shader "Custom/UIReflection"
{
    Properties
    {
		[PerRendererData]
        _MainTex("Texture", 2D) = "white" {}
		_Offset("Vertex Offset", vector) = (0, 0, 0, 0)
		_TransShadowValue("TransShadow Value", range(0, 1)) = 0.1
		_YOffset("YOffset", range(0, 0.05)) = 0.0005
		[KeywordEnum(Text, Sprite)]
		_Type("UI Type", float) = 0
	}

    SubShader
    {
        Tags 
		{ 
			"RenderType"="Opaque" 
			"Queue"="Transparent" 
			"CanUseSpriteAltas"="True"
			"IgnoreProjector"="True"
		}
        
		Blend SrcAlpha OneMinusSrcAlpha

		ZWrite Off

		ZTest Always

		ZClip Off

		Cull Off

		Lighting Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "UnityUI.cginc"	

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float4 v_color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				float4 color : COLOR;
                float4 vertex : SV_POSITION;
				float4 worldPosition : TEXCOORD1;
            };

            sampler2D _MainTex;
			fixed4 _ClipRect;

            v2f vert(appdata v)
            {
                v2f o;
				
				o.worldPosition = v.vertex;
                
				o.vertex = UnityObjectToClipPos(v.vertex);
                
				o.uv = v.uv;
				
				o.color = v.v_color;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

				col.rgb += i.color.rgb;
				
				col.a *= UnityGet2DClipping(i.worldPosition.xy, _ClipRect) * i.color.a;

                return col;
            }
            ENDCG
        }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _TYPE_TEXT _TYPE_SPRITE

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"	

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 v_color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
				float4 vertex : SV_POSITION;
				float4 worldPosition : TEXCOORD1;
			};

			sampler2D _MainTex, _RevFontTex;
			
			fixed4 _ClipRect;
			
			fixed4 _Offset;

			fixed _TransShadowValue;

			fixed _YOffset;

			v2f vert(appdata v)
			{
				v2f o;
				
				o.worldPosition = v.vertex;

				v.vertex += _Offset;

				o.vertex = UnityObjectToClipPos(v.vertex);

				o.uv = v.uv;

#if _TYPE_SPRITE
				o.uv.y = abs(o.uv.y - 1);

#else
				o.vertex.y *= -1;
#endif

				o.color = v.v_color;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{

				fixed4 col = tex2D(_MainTex, i.uv);

				col.rgb += i.color.rgb;
				
				col.a *= UnityGet2DClipping(i.worldPosition.xy, _ClipRect) * i.color.a;

				col.a *= lerp(0, 1, _TransShadowValue - i.worldPosition.y * _YOffset);

				return col;
			}
			ENDCG
		}
    }
}
