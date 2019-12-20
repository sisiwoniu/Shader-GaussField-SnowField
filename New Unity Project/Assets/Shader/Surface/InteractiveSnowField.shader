Shader "Custom/InteractiveSnowField"
{
    Properties
    {
		[Header(Main)]
		_Noise("Snow Noise", 2D) = "gray" {}
		_NoiseScale("Noise Scale", Range(0, 2)) = 0.1
		_NoiseWeight("Noise Weight", Range(0, 2)) = 0.1
		_ToonRamp("Main Color", Color) = (0.5, 0.5, 0.5, 1)
		_Mask("Mask", 2D) = "white" {}
		
		[Space]
        [Header(Tesselation)]
        _MaxTessDistance("Max Tessellation Distance", Range(10,100)) = 50
        _Tess("Tessellation", Range(1,32)) = 20

		[Space]
		[Header(Snow)]
		_Color("Snow Color", Color) = (1, 1, 1, 1)
		_PathColor("Snow Path Color", Color) = (1, 1, 1, 1)
		_MainTex("Snow Texture", 2D) = "white" {}
		_SnowHeight("Snow Height", Range(0, 2)) = 0.3
		_SnowDepth("Snow Path Depth", Range(-2, 2)) = 0.3
		//頂点色に対する情報操作なので、頂点が無色の場合色設定が効かない
		_EdgeColor("Snow Edge Color", Color) = (1, 1, 1, 1)
		_EdgeWidth("Snow Edge Width", Range(0, 0.2)) = 0.1
		_SnowTextureOpacity("Snow Texture Opacity", Range(0, 2)) = 0.3
		_SnowTextureScale("Snow Texture Scale", Range(0, 2)) = 0.3

		//光るparameter　
		[Space]
		[Header(Sparkles)]
		_SparkleScale("Sparkle Scale", Range(0, 10)) = 10
		_SparkleCutOff("Sparkle Cutoff", Range(0, 10)) = 0.1
		_SparkleNoise("Sparkle Noise", 2D) = "gray"{}

		[Space]
		[Header(Extra Textures)]
		_MainTexBase("Base Texture", 2D) = "white"{}
		_Scale("Base Scale", Range(0, 2)) = 2

		[Space]
		[Header(Rim)]
		_BaseColor("Base Color", Color) = (1, 1, 1, 1)
		_RimPower("Rim Power", Range(0, 20)) = 20
		_RimColor("Rim Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

		Cull Back

        LOD 200

        CGPROGRAM
		#pragma surface surf ToomRamp vertex:vert addshadow nolightmap tessellate:tessDistance

        #pragma target 5.0

		#pragma require tessellation tessHW

		#include "Tessellation.cginc"

		fixed4 _ToonRamp;
		
		inline half4 LightingToomRamp(SurfaceOutput s, fixed3 lightDir, fixed atten) 
		{
		#ifndef USING_DIRECTIONAL_LIGHT
			lightDir = normalize(lightDir);
		#endif
			
			float d = dot(s.Normal, lightDir);

			float3 ramp = smoothstep(0.0, d + 0.06, d) + _ToonRamp;

			half4 c;

			c.rgb = s.Albedo * _LightColor0.rgb * ramp * (atten * 2.0);

			c.a = 0.0;

			return c;
		}

		//外部に代入される情報
        float3 _Position;
		sampler2D _GlobalEffectRT;
		float _OrthographicCamSize;

		float _Tess;
		float _MaxTessDistance;

		//定義済みの[UnityCalcDistanceTessFactor]とほぼ同じ
		float ColorCalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess, float4 color) 
		{
			float3 w_pos = mul(unity_ObjectToWorld, vertex).xyz;
			
			float dist = distance(w_pos, _WorldSpaceCameraPos);
			
			//頂点色の「R」情報が0.4以下になると、テッセレーションされる度合いが弱くなる（ほぼしない）
			//雪を積もらせない場合利用する
			//ここの頂点色を利用するため、書き換えている
			float f = color.r < 0.4 ? 0.001 : clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0);
			
			return f * tess;
		}

		fixed4 ColorDistanceBasedTess(fixed4 v0, fixed4 v1, fixed4 v2, fixed minDist, fixed maxDist,
		fixed tess, fixed4 v0c, fixed4 v1c, fixed4 v2c) 
		{
			float3 f;

			f.x = ColorCalcDistanceTessFactor(v0, minDist, maxDist, tess, v0c);

			f.y = ColorCalcDistanceTessFactor(v1, minDist, maxDist, tess, v1c);

			f.z = ColorCalcDistanceTessFactor(v2, minDist, maxDist, tess, v2c);

			//Tessellation.cginc内部で定義済み
			return UnityCalcTriEdgeTessFactors(f);
		}

		//テッセレーションシェーダーから呼ばれる関数
		fixed4 tessDistance(appdata_full v0, appdata_full v1, appdata_full v2)
        {
            fixed minDist = 10.0;
            
			fixed maxDist = _MaxTessDistance;
 
            return ColorDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess, v0.color, v1.color, v2.color);
        }

		sampler2D _MainTex, _MainTexBase, _Noise, _SparkleNoise;
		fixed4 _Color, _RimColor;
		fixed _RimPower;
		fixed _Scale, _SnowTextureScale, _NoiseScale;
		fixed4 _EdgeColor;
		fixed _EdgeWidth;
		fixed _SnowHeight, _SnowDepth;
		fixed4 _PathColor, _BaseColor;
		sampler2D _Mask;
		fixed _NoiseWeight;
		fixed _SparkleScale, _SparkleCutOff;
		fixed _SnowTextureOpacity;

        struct Input
        {
            float2 uv_MainTex : TEXCOORD0;
			float3 worldPos;
			float3 viewDir; //リムライトで使う
			float4 vertexColor : COLOR;
			float4 screenPos;
        };

		void vert(inout appdata_full v) 
		{
			fixed3 w_pos = mul(unity_ObjectToWorld, v.vertex).xyz;

			//レンダラーテクスチャをロード
			//カメラが対象の真上にあるので、座標のx,zが平面から見るとxyになる
			fixed2 uv = w_pos.xz - _Position.xz;

			//通常カメラの「OrthographicCamSize」が画面の半分になる
			//「uv / (_OrthographicCamSize * 2.0)」の結果が「-0.5~0.5」になるので、これを「0~1」に変換
			uv = uv / (_OrthographicCamSize * 2.0) + 0.5;

			//「tex2Dlod」の第2要素値「xy = uv, w = mip level」
			//「tex2Dlod」はバーテックスシェーダでサンプリング用
			//Mask to prevent bleeding
			fixed mask = tex2Dlod(_Mask, fixed4(uv, 0, 0)).a;

			fixed4 RTEffect = tex2Dlod(_GlobalEffectRT, float4(uv, 0, 0));

			RTEffect *= mask;

			//ワールド空間でノイズの影響を入れる
			fixed snowNoise = tex2Dlod(_Noise, fixed4(w_pos.xz * _NoiseScale * 5.0, 0, 0));

			//頂点を膨らます
			//頂点座標 + 法線方向 * (「頂点色 * 雪の高さ] + 「ノイズ情報 * ノイズ強さ * 頂点色」)
			v.vertex.xyz += normalize(v.normal) * (
				saturate((v.color.r * _SnowHeight) + (snowNoise * _NoiseWeight * v.color.r))
			);

			//particleの色が緑色なので、RTEffect.gを使っている、particleの色が変わるならこっちも変更しないといけない
			//頂点を凹ませる、パーティクルの軌跡に合わせる
			v.vertex.xyz -= normalize(v.normal) * (RTEffect.g * saturate(v.color.r)) * _SnowDepth;
		}

		void surf(Input IN, inout SurfaceOutput o)
		{
			fixed2 uv = IN.worldPos.xz - _Position.xz;

			uv = uv / (_OrthographicCamSize * 2.0) + 0.5;

			fixed mask = tex2D(_Mask, uv).a;

			fixed4 effect = tex2D(_GlobalEffectRT, fixed2(uv.x, uv.y));
			
			effect *= mask;

			//[WorldNormalVector]はピクセル法線マップから値取る場合利用
			fixed3 blendNormal = saturate(pow(WorldNormalVector(IN, o.Normal), 4.0));
			
			//各軸ベースのノーマルノイズ
			fixed3 xn = tex2D(_Noise, IN.worldPos.zy * _NoiseScale);

			fixed3 yn = tex2D(_Noise, IN.worldPos.zx * _NoiseScale);

			fixed3 zn = tex2D(_Noise, IN.worldPos.xy * _NoiseScale);

			//ノイズテクスチャブレンド
			fixed3 noisetexture = zn;

			noisetexture = lerp(noisetexture, xn, blendNormal.x);

			noisetexture = lerp(noisetexture, yn, blendNormal.y);

			//各軸から見たメインテクスチャ
			fixed3 xm = tex2D(_MainTex, IN.worldPos.zy * _SnowTextureScale);

			fixed3 ym = tex2D(_MainTex, IN.worldPos.zx * _SnowTextureScale);

			fixed3 zm = tex2D(_MainTex, IN.worldPos.xy * _SnowTextureScale);

			//メインテクスチャブレンド
			fixed3 snowTexture = zm;

			snowTexture = lerp(snowTexture, xm, blendNormal.x);

			snowTexture = lerp(snowTexture, ym, blendNormal.y);

			//各軸から見たベーステクスチャ要素
			fixed3 x = tex2D(_MainTexBase, IN.worldPos.zy * _Scale);

			fixed3 y = tex2D(_MainTexBase, IN.worldPos.zx * _Scale);

			fixed3 z = tex2D(_MainTexBase, IN.worldPos.xy * _Scale);
			
			//ベーステクスチャブレンド
			fixed3 baseTexture = z;

			baseTexture = lerp(baseTexture, x, blendNormal.x);

			baseTexture = lerp(baseTexture, y, blendNormal.y);

			//リムライト、ノイズとブレンド
			//BlendNormalsは複数のノーマル情報をブレンド
			fixed rim = 1.0 - dot(IN.viewDir, BlendNormals(o.Normal, noisetexture));

			//雪を表示するかどうかの最終計算するためのパラメーター
			fixed vertexColoredPrimary = step(0.6 * noisetexture, IN.vertexColor.r);

			//雪テクスチャ最終的に決める
			fixed3 snowTextureResult = vertexColoredPrimary * snowTexture;

			//頂点エッジ色、雪表示する場合エッジなし
			fixed vertexColorEdge = step((0.6 - _EdgeWidth) * noisetexture, IN.vertexColor.r) * (1.0 - vertexColoredPrimary);
			
			//雪の下の画像
			fixed3 baseTextureResult = baseTexture * (1.0 - (vertexColoredPrimary + vertexColorEdge));
			
			//合成
			fixed3 mainColors = (baseTextureResult * _BaseColor) + 
			((snowTextureResult * _SnowTextureOpacity) + (vertexColoredPrimary * _Color)) +
			(vertexColorEdge * _EdgeColor);
			
			//凹んだ深さの具合により色調整をしなくなる
			o.Albedo = lerp(mainColors, _PathColor * effect.g,
				saturate(effect.g));

			//凹んだ深さの具合により色調整する
			/*o.Albedo = lerp(mainColors, _PathColor * effect.g, 
			saturate(effect.g * 2.0 * vertexColoredPrimary));*/

			fixed sparklesStatic = tex2D(_SparkleNoise, IN.uv_MainTex * _SparkleScale * 5.0);

			fixed sparklesResult = tex2D(_SparkleNoise, (IN.uv_MainTex * IN.screenPos) * _SparkleScale) * sparklesStatic;

			float t = step(_SparkleCutOff, sparklesResult);

			o.Albedo += vertexColoredPrimary * t;
			
			//雪のところにRimライトを照らす
			o.Emission = vertexColoredPrimary * _RimColor * pow(rim, _RimPower);
		}

        ENDCG
    }

    FallBack "Diffuse"
}