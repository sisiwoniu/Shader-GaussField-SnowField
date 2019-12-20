Shader "Custom/DOFEffect"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}

		[HDR]
		_BaseColor("Base Color", Color) = (1, 1, 1, 1)
		
		_Offset("Offset", Range(0, 100)) = 1
		
		[Toggle]
		_Soft("Use Soft Particle", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" "IgnoreProjector" = "True" }
        
		LOD 200

		Cull Back

		Blend SrcAlpha OneMinusSrcAlpha

		ZWrite Off

		ZTest Always

        Pass
        {
            CGPROGRAM
			#pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
			#pragma shader_feature _SOFT_ON

            #include "UnityCG.cginc"

            struct appdata
            {
                half4 vertex : POSITION;
                half2 uv : TEXCOORD0;
				fixed4 color : COLOR;
            };

            struct v2f
            {
                half2 uv : TEXCOORD0;
				half4 vertex : SV_POSITION;
				half4 projpos : TEXCOORD1;
				fixed4 color : COLOR;
				fixed mipmaplv : TEXCOORD2;
            };

            sampler2D _MainTex;
            
			float4 _MainTex_ST;
			
			half _Offset;

			fixed4 _BaseColor;

#if _SOFT_ON
			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
#endif

            v2f vert(appdata v)
            {
                v2f o;

				half3 viewPos = UnityObjectToViewPos(v.vertex);
                
				o.vertex = UnityObjectToClipPos(v.vertex);

				o.projpos = ComputeGrabScreenPos(o.vertex);

				COMPUTE_EYEDEPTH(o.projpos.z);
                
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				o.color = v.color;

				o.mipmaplv = ceil(lerp(2, 0, saturate(abs(viewPos.z) - _Offset)));

				return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
				fixed4 col = tex2Dlod(_MainTex, half4(i.uv, 0, i.mipmaplv));

				col.a *= col.r;

				col.rgb = 1;

#if _SOFT_ON

				half sceneDepth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, i.projpos));

				col.a *= saturate(sceneDepth - i.projpos.z);

#endif		

				return col * i.color * _BaseColor;
            }
            ENDCG
        }
    }
}
