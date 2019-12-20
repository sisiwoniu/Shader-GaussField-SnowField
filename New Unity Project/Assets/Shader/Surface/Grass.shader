//参考ページ：https://roystan.net/articles/grass-shader.html
Shader "Custom/Grass"
{
    Properties
    {
		[Header(Shading)]
        _TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)
		_TranslucentGain("Translucent Gain", Range(0,1)) = 0.5
		//倒れる具合
		_BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2
		
		[Header(BladeSize)]
		_BladeWidth("Blade Width", float) = 0.05
		_BladeWidthRandom("Blade Width Random", float) = 0.02
		_BladeHeight("Blade Height", float) = 0.5
		_BladeHeightRandom("Blade Height Random", float) = 0.3
		//傾斜の面で草を倒したい場合値を大きくする
		_BladeForward("Blade Forward Amount", float) = 0.38
		//↑の設定値の拡大倍数
		_BladeCurve("Blade Curvature Amount", Range(1, 4)) = 2

		[Header(Tessllation)]
		_TessellationUniform("TessllationUniform", Range(1, 100)) = 1 
		
		[Header(Wind)]
		//風によりなびくためのテクスチャ、赤とグリーンの２チャンネルと使うテクスチャ
		_WindDistortionMap("Wind Distortion Map", 2D) = "white"{}
		_WindFrequency("Wind Frequency", vector) = (0.05, 0.05, 0, 0)
		_WindStrength("Wind Strength", float) = 1
	}

	CGINCLUDE
	#include "Autolight.cginc"
	#include "Assets/Shader/Cgincs/ShapeAndMathG.cginc"
	#define BLADE_SEGMENTS 3

	// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
	// Extended discussion on this function can be found at the following link:
	// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
	// Returns a number in the 0...1 range.
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	// Construct a rotation matrix that rotates around the provided axis, sourced from:
	// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
	float3x3 AngleAxis3x3(float angle, float3 axis)
	{
		float c, s;
		sincos(angle, s, c);

		float t = 1 - c;
		float x = axis.x;
		float y = axis.y;
		float z = axis.z;

		return float3x3(
			t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			t * x * z - s * y, t * y * z + s * x, t * z * z + c
			);
	}

	struct geometryOutput
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		unityShadowCoord4 _ShadowCoord : TEXCOORD1;
		float3 normal : TEXCOORD2;
	};

	//頂点シェーダーは何もしない、そのまま次のステージに情報を渡す
	vertexInput vert(vertexInput IN)
	{
		return IN;
	}

	geometryOutput VertexOutput(float3 pos, float2 uv, float3 normal) 
	{
		geometryOutput o;

		o.pos = UnityObjectToClipPos(pos);

#if UNITY_PASS_SHADOWCASTER
		//シャドウ表示をリニアにする
		//ギザギザを解消
		o.pos = UnityApplyLinearShadowBias(o.pos);
#endif

		o.uv = uv;

		o._ShadowCoord = ComputeGrabScreenPos(o.pos);

		o.normal = UnityObjectToWorldNormal(normal);

		return o;
	}

	geometryOutput GenerateGrassVertex(float3 vertexPos, float width, float forward, float height, float2 uv, float3x3 transformMatrix) 
	{
		float3 localNormal = mul(transformMatrix, normalize(float3(0, -1, forward)));

		float3 tangentPos = float3(width, forward, height);

		return VertexOutput(vertexPos + mul(transformMatrix, tangentPos), uv, localNormal);
	}

	float _BendRotationRandom;
	float _BladeWidth;
	float _BladeWidthRandom;
	float _BladeHeight;
	float _BladeHeightRandom;
	float _BladeForward;
	float _BladeCurve;

	sampler2D _WindDistortionMap;
	float4 _WindDistortionMap_ST;
	float2 _WindFrequency;
	float _WindStrength;

	sampler2D _GlobalEffectRT;
	float _OrthographicCamSize;
	float4 _Position;

	//ジオメトリシェーダーではバーテックスからの出力を受け取るべき
	//順番：バーテックス→ハル→テッセレーション→ドメイン→ジオメトリ→ピクセル
	//「maxvertexcount」で必要な頂点数を指定、GPUから入力すると出力する
	[maxvertexcount(BLADE_SEGMENTS * 2 + 2)]
	void geo(point vertexOutput IN[1] : SV_POSITION, inout TriangleStream<geometryOutput> triStream)
	{
		//プリミティブの任意の頂点を一個取る
		float3 pos = IN[0].vertex;

		float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;

		//パス情報
		float2 w_pos = mul(unity_ObjectToWorld, pos).xz;

		float2 pathUV = w_pos - _Position.xz;

		pathUV = pathUV / (_OrthographicCamSize * 2.0) + 0.5;

		fixed4 pathCol = tex2Dlod(_GlobalEffectRT, float4(pathUV, 0, 0));

		//tex2Dlod(_WindDistortionMap, float4(uv, 0, 0))は「0.5~1」になるので、これを「0~1」にする
		float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;

		float3 wind = normalize(float3(windSample.xy, 0));

		//z
		float3 vNormal = IN[0].normal;
		
		//x
		float4 vTangent = IN[0].tangent;
		
		//最後vTangent.wをかけるのは、dx環境とopengl環境の差を吸収するためかな
		//「vTangent.w」にはモデリングがインポートされた時モデルにあった「binormal」はすでに格納済み
		float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;

		//接空間からモデル空間に変換するためのマトリックス
		float3x3 tangentToLocal = float3x3(
			vTangent.x, vBinormal.x, vNormal.x,
			vTangent.y, vBinormal.y, vNormal.y,
			vTangent.z, vBinormal.z, vNormal.z
			);

		//Up軸に沿った回転のためのマトリックス
		//接空間では「Up」＝＝「Z軸」
		//向きのための回転
		float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));

		//NOTE:もしルートに痕跡を残したい場合、ここのマトリックスを弄れば済むので、状況を確認する
		//x軸に沿ったランダム回転のためのマトリックス
		//必ず(180*0.5)度以下になる
		//倒すための回転
		//float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * /*lerp(_BendRotationRandom, 1, pathCol.g) **/ UNITY_PI * 0.5, float3(-1, 0, 0));

		//風なびくためのマトリックス
		float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample, wind);

		//四つのマトリックスを合成する
		float3x3 transformationMatrix = mul(mul(tangentToLocal, windRotation), facingRotationMatrix);//mul(mul(mul(tangentToLocal, windRotation), facingRotationMatrix), bendRotationMatrix);

		//倒すためのマトリックスをモデル空間内に移す
		float3x3 transformationMatrixFacing = mul(tangentToLocal, facingRotationMatrix);

		//Z
		float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
		
		//x
		float width = (rand(pos.xyz) * 2 - 1) * _BladeWidthRandom + _BladeWidth;

		//y
		float forward = rand(pos.yyz) * _BladeForward;

		//根っこの頂点のためのマトリックス
		float3x3 loopTransformMatrix = transformationMatrixFacing;

		//単純に最適化
		float inv_BLADE_SEGMENTS = 1 / (float)BLADE_SEGMENTS;

		//頂点を二つずつ増やす
		//階層的に頂点を振り当てる、最後になると「width」が「0」になる
		for(int i = 0; i < BLADE_SEGMENTS + 1; i++) 
		{
			float t = i * inv_BLADE_SEGMENTS;
			
			//ループすればするほど幅が小さくなる
			float segmentsWidth = width * (1 - t * 0.25);

			//ループすればするほど高さが増える
			float segmentsHeight = height * t * max((1 - pathCol.g) * 2, 0.2);

			float segmentsForward = pow(t, _BladeCurve) * forward;

			triStream.Append(GenerateGrassVertex(pos, segmentsWidth, segmentsForward, segmentsHeight, float2(0, t), loopTransformMatrix));

			triStream.Append(GenerateGrassVertex(pos, -segmentsWidth, segmentsForward, segmentsHeight, float2(t, 0), loopTransformMatrix));
			
			loopTransformMatrix = transformationMatrix;
		}
	}

	ENDCG

    SubShader
	{
		Cull Off

		Pass
		{
			Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6
			#pragma geometry geo
			#pragma multi_compile_fwdbase

			#include "Lighting.cginc"

			float4 _TopColor;
			float4 _BottomColor;
			float _TranslucentGain;

			float4 frag(geometryOutput i, fixed facing : VFACE) : SV_Target
			{
				float shadow = SHADOW_ATTENUATION(i);
				
				//Cullしないため、正面と背面を分ける必要があります
				float3 normal = i.normal * clamp(step(facing, 0), 1, -1);

				//拡散反射の強さ
				float NDotL = saturate(saturate(dot(normal, _WorldSpaceLightPos0)) + _TranslucentGain) * shadow;

				//環境光の情報
				float3 ambient = ShadeSH9(float4(normal, 1));

				//ライトの色を全員加算
				float4 lightIntensity = NDotL * _LightColor0 + float4(ambient, 1);

				//根っこは全く光の影響受けない
				float4 col = lerp(_BottomColor, _TopColor * lightIntensity, i.uv.y);
				
				return col;
			}
			ENDCG
		}

		//シャドー投影
		Pass
		{
			Tags { "LightMode" = "ShadowCaster" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6
			#pragma geometry geo
			#pragma multi_compile_shadowcaster

			float4 frag(geometryOutput i) : SV_Target
			{
				//return 0だけでも影を落とせる
				//陰影描画
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
}