Shader "Custom/BlendTexGreenColor"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}

		_DestTex("Dest Tex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

		ZWrite Off

		ZTest Always

		Blend One Zero

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

            sampler2D _MainTex;
			sampler2D _DestTex;
            float4 _MainTex_ST;
			fixed _InvResetDuration;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
				fixed4 col = tex2D(_MainTex, i.uv);
				
				fixed4 dst_col = tex2D(_DestTex, i.uv);

				dst_col.g = max(dst_col.g, col.g);

				dst_col.g = max(0, dst_col.g - (unity_DeltaTime.x * _InvResetDuration));

				return fixed4(col.r, dst_col.g, col.b, col.a);
            }
            ENDCG
        }
    }
}
