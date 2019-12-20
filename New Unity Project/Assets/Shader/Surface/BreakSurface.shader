Shader "Unlit/BreakSurface"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
		//破壊
		_Destruction("Destruction", Range(0, 1)) = 0
		//スケール
		_InvScale("Inv Scale", Range(0, 1)) = 1
		_Rotate("Rotate", Range(0, 1)) = 0
		_Pos("Pos", Range(0, 1)) = 0
		_TessellationUniform("TessellationFactors", Range(1, 100)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" }
        
		LOD 100

		Blend SrcAlpha OneMinusSrcAlpha

		Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma geometry geo
			#pragma target 4.6

		    #include "Assets/Shader/Cgincs/ShapeAndMathG.cginc"

			//テッセレーション要らないバージョン
          /*  struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };*/

			//テッセレーション要らないバージョン
           /* struct v2g
            {
                float2 uv : TEXCOORD0;
                float4 vertex : POSITION;
            };*/

			struct g2f 
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

            sampler2D _MainTex;
            float4 _MainTex_ST;
			half _InvScale, _Destruction, _Pos, _Rotate;

			float rand(float3 co)
			{
				return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
			}

			//テッセレーション要らないバージョン
           /* v2g vert(appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }*/
			//テッセレーションバージョン
			vertexInput vert(vertexInput IN)
			{
				return IN;
			}

			[maxvertexcount(3)]
			void geo(triangle /*v2g*/vertexOutput IN[3] : SV_POSITION, inout TriangleStream<g2f> triStream)
			{
				float3 c_point = (IN[2].vertex.xyz + IN[1].vertex.xyz + IN[0].vertex.xyz) / 3;

				float3 v_1 = IN[1].vertex.xyz - IN[0].vertex.xyz;

				float3 v_2 = IN[2].vertex.xyz - IN[0].vertex.xyz;

				float3 normal = normalize(cross(v_1, v_2));

				float r = rand(c_point);

				for(int i = 0; i < 3; i++) 
				{
					g2f o;
					
					o.uv = IN[i].uv;

					//破壊とスケール変更
					float3 pos = (IN[i].vertex.xyz - c_point) * (1 - _Destruction * _InvScale) + c_point;

					//回転
					pos.xy = rotation2D(pos.xy, r * _Rotate * _Destruction);

					//移動
					pos = normal * _Destruction * _Pos * r + pos;

					o.pos = UnityObjectToClipPos(pos);

					triStream.Append(o);
				}
			}

            fixed4 frag(g2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
