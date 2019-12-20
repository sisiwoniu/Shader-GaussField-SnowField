#ifndef SHAPE_AND_MATH_G_INCLUDED
#define SHAPE_AND_MATH_G_INCLUDED

#define PI 3.141592653589793

#define PI2 PI * 2

//ラジアンから度数に変換する際にこれを掛ける
#define PI2THETA 1 / PI2

#include "UnityCG.cginc"

half circle(fixed2 Pos) {
	return dot(Pos, Pos);
}

half circle(fixed2 Pos, fixed Radius) {
	return length(Pos) - Radius;
}

//楕円
half ellipse(fixed2 Pos, fixed2 R, fixed Size) {
	return length(Pos / R) - Size;
}

//四角
half rectangle(fixed2 Pos, fixed2 Size) {
	return max(abs(Pos.x) - Size.x, abs(Pos.y) - Size.y);
}

//菱形
half rhombus(fixed2 Pos, fixed Size) {
	return abs(Pos.x) + abs(Pos.y) - Size;
}

half heart(fixed2 Pos, fixed Size) {
	Pos.x = 1.2 * Pos.x - sign(Pos.x) * Pos.y * 0.55;

	return length(Pos) - Size;
}

//Nは角の数
half polygon(fixed2 Pos, int N, fixed Size) {
	half a = atan2(Pos.y, Pos.x) + PI;

	half r = 2 * PI / N;

	return cos(floor(0.5 + a / r) * r - a) * length(Pos) - Size;
}

//Size == 大きさ、Width = ringの太さ
half ring(fixed2 Pos, fixed Size, fixed Width) {
	return abs(length(Pos) - Size) + Width;
}

//N = 5 T = 0.5はスター
half star(fixed2 Pos, fixed N, fixed T, fixed Size) {
	fixed a = 2 * PI / N * 0.5;

	fixed c = cos(a);

	fixed s = sin(a);

	fixed2 r = mul(Pos, fixed2x2(c, -s, s, c));

	return (polygon(Pos, N, Size) - polygon(r, N, Size) * T) / (1 - T);
}

//直接回転する
fixed2 rotation2D(fixed2 Pos, fixed Angle) {
	return fixed2(Pos.x * cos(Angle) - Pos.y * sin(Angle), Pos.x * sin(Angle) + Pos.y * cos(Angle));
}

//拡大マトリックス
fixed4x4 scaleMatrix(fixed3 scaleValue) {
	return fixed4x4(
		scaleValue.x, 0, 0, 0,
		0, scaleValue.y, 0, 0,
		0, 0, scaleValue.z, 0,
		0, 0, 0, 1
	);
}

//移動マトリックス
fixed4x4 moveMatrix(fixed3 moveValue) {
	return fixed4x4(
		1, 0, 0, moveValue.x,
		0, 1, 0, moveValue.y,
		0, 0, 1, moveValue.z,
		0, 0, 0, 1
	);
}

//X軸回転マトリックス
fixed4x4 x_rotationMatrix(fixed angle) {
	return fixed4x4(
		1, 0, 0, 0,
		0, cos(angle), -sin(angle), 0,
		0, sin(angle), cos(angle), 0,
		0, 0, 0, 1
	);
}

//Y軸回転マトリックス
fixed4x4 y_rotationMatrix(fixed angle) {
	return fixed4x4(
		cos(angle), 0, sin(angle), 0,
		0, 1, 0, 0,
		-sin(angle), 0, cos(angle), 0,
		0, 0, 0, 1
	);
}

//Z軸回転マトリックス
fixed4x4 z_rotationMatrix(fixed angle) {
	return fixed4x4(
		cos(angle), -sin(angle), 0, 0,
		sin(angle), cos(angle), 0, 0,
		0, 0, 0, 1,
		0, 0, 0, 1
	);
}

//接空間に変換するための逆行列
fixed4x4 invTangentMatrix(fixed3 t, fixed3 b, fixed3 n) {
	return transpose(fixed4x4(
		t.x, t.y, t.z, 0,
		b.x, b.y, b.z, 0,
		n.x, n.y, n.z, 0,
		0, 0, 0, 1
	));
}

fixed random2D(fixed2 Pos) {
	return frac(sin(dot(Pos, fixed2(12.9898, 78.233))) * 43758.5453);
}

fixed random2D(fixed2 Pos, fixed Seed) {
	return frac(sin(dot(Pos, fixed2(12.9898, 78.233)) + Seed) * 43758.5453);
}

fixed2 random2DR2(fixed2 Pos) {
	Pos = fixed2(dot(Pos, fixed2(127.1, 311.7)), dot(Pos, fixed2(269.5, 183.3)));

	return -1 + 2 * frac(sin(Pos) * 43758.5453123);
}

fixed blocknoise(fixed2 Pos) {
	return random2D(floor(Pos));
}

fixed valuenoise(fixed2 Pos) {
	fixed2 i_uv = floor(Pos);

	fixed2 f_uv = frac(Pos);

	fixed v00 = random2D(i_uv);

	fixed v01 = random2D(i_uv + fixed2(0, 1));

	fixed v10 = random2D(i_uv + fixed2(1, 0));

	fixed v11 = random2D(i_uv + fixed2(1, 1));

	fixed2 uv = f_uv * f_uv * (3 - 2 * f_uv);

	fixed v0010 = lerp(v00, v10, uv.x);

	fixed v0111 = lerp(v01, v11, uv.x);

	return lerp(v0010, v0111, uv.y);
}

fixed perlinnoise(fixed2 Pos) {
	fixed2 i_uv = floor(Pos);

	fixed2 f_uv = frac(Pos);

	fixed2 uv = f_uv * f_uv * (3 - 2 * f_uv);

	fixed v00 = random2DR2(i_uv);

	fixed v01 = random2DR2(i_uv + fixed2(0, 1));

	fixed v10 = random2DR2(i_uv + fixed2(1, 0));

	fixed v11 = random2DR2(i_uv + fixed2(1, 1));

	fixed v0010 = lerp(dot(v00, f_uv), dot(v10, f_uv - fixed2(1, 0)), uv.x);

	fixed v0111 = lerp(dot(v01, f_uv - fixed2(0, 1)), dot(v11, f_uv - fixed2(1, 1)), uv.x);

	return lerp(v0010, v0111, uv.y) + 0.5;
}

//X軸方向の歪み
fixed distortionXType1(fixed2 uv, fixed speed) {
	fixed x = 2 * uv.y + sin(_Time.y * speed);

	fixed distort = sin(_Time.y * 1.5) * 0.1 * sin(5 * x);

	return distort;
}

//XY軸方向の歪み
fixed2 distortionXYType1(fixed2 uv, fixed speed) {
	fixed2 s_uv = uv;

	s_uv = 0.1 * sin(s_uv.x * 5.0 + _Time.z * speed) + 0.1 * sin(s_uv.y * 3.0 + _Time.z * speed);

	return s_uv;
}

//XY軸方向の歪み
fixed2 distortionXYType2(fixed2 uv, fixed speed) {
	fixed2 s_uv = uv;

	s_uv -= 0.5;

	s_uv *= 15 * pow(length(uv - 0.5), 2);

	s_uv += 0.5;
	
	return s_uv;
}

//stride == 拡散率　c == 調整値
//波動方程式
fixed prevwave(sampler2D prevTex, sampler2D prev2Tex, fixed2 uv, fixed4 prevTexelSize, fixed stride, fixed v) {
	fixed2 _stride = fixed2(stride, stride) * prevTexelSize.xy;

	fixed prevR = (tex2D(prevTex, uv) * 2 - 1).r;

	fixed value = (prevR * 2 - 
					(tex2D(prev2Tex, uv).r * 2 - 1) + (
						(tex2D(prevTex, fixed2(uv.x + _stride.x, uv.y)).r * 2 - 1) +
						(tex2D(prevTex, fixed2(uv.x - _stride.x, uv.y)).r * 2 - 1) +
						(tex2D(prevTex, fixed2(uv.x, uv.y + _stride.y)).r * 2 - 1) +
						(tex2D(prevTex, fixed2(uv.x, uv.y - _stride.y)).r * 2 - 1) -
						prevR * 4
					) * v
				);

	return value;
}

//拡大パターンされたUVのXをずらす
fixed2 shiftUVX(fixed2 uv) {
	uv.x += step(1, fmod(uv.y, 2.0)) * 0.5;
	
	return uv;
}

//拡大パターンされたUVのXをずらす
fixed2 shiftUVY(fixed2 uv) {
	uv.y += step(1, fmod(uv.x, 2.0)) * 0.5;
	
	return uv;
}

//直角座標系を極座標系に変換
//戻り値「x = ベクトル長さ」「y = 度数」
fixed2 convertPolarCordinate(fixed2 uv) {

	fixed2 r_uv;

	//座標範囲を「0~1」から「-1~1」に変換
	uv = uv * 2 - 1;

	//ベクトル長さ
	r_uv.x = sqrt(pow(uv.x, 2) + pow(uv.y, 2));

	//ラジアンから度数に変換
	r_uv.y = atan2(uv.y, uv.x) * PI2THETA;

	return r_uv;
}

//スクリーンアスペクト比でUVを適応させる
//横タイプに適用する場合、これを使う
fixed2 screenAspect(fixed2 uv) {
	
	fixed a = _ScreenParams.x / _ScreenParams.y;

	uv.x -= 0.5;

	uv.x *= a;

	uv.x += 0.5;

	return uv;
}

//ビルボードの頂点座標値
float4 BillboardVertex(float4 vertex) {
    float3 pos = mul((float3x3)unity_ObjectToWorld, vertex.xyz);
    
    float4 worldCoord = float4(unity_ObjectToWorld._m03, unity_ObjectToWorld._m13, unity_ObjectToWorld._m23, 1);
    
    float4 viewPos = mul(UNITY_MATRIX_V, worldCoord) + float4(pos, 0);

    float4 outPos = mul(UNITY_MATRIX_P, viewPos);

    return outPos; 
}

//Tessllationエリア
struct vertexInput
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
};

struct vertexOutput 
{
	float4 vertex : SV_POSITION;
	float3 normal :NORMAL;
	float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
};

struct TessellationFactors
{
	//パッチのエッジに対する分割、1の場合分割しない
	float edge[3] : SV_TessFactor;
	//パッチの内部に対する分割
	float inside : SV_InsideTessFactor;
};

//分割数
float _TessellationUniform;

//テッセレーションステージ
TessellationFactors patchConstantFunction(InputPatch<vertexInput, 3> patch)
{
    TessellationFactors o;

    o.edge[0] = _TessellationUniform;
    o.edge[1] = _TessellationUniform;
    o.edge[2] = _TessellationUniform;
    o.inside = _TessellationUniform;    

    return o;
}

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("integer")]
[UNITY_patchconstantfunc("patchConstantFunction")]
vertexInput hull(InputPatch<vertexInput, 3> patch, uint id : SV_OutputControlPointID)
{
    return patch[id];
}

[UNITY_domain("tri")]
vertexOutput domain(TessellationFactors factors, OutputPatch<vertexOutput, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
    vertexOutput o;

    #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) o.fieldName = \
    patch[0].fieldName * barycentricCoordinates.x + \
    patch[1].fieldName * barycentricCoordinates.y + \
    patch[2].fieldName * barycentricCoordinates.z;

    MY_DOMAIN_PROGRAM_INTERPOLATE(vertex);
    MY_DOMAIN_PROGRAM_INTERPOLATE(normal);
    MY_DOMAIN_PROGRAM_INTERPOLATE(tangent);
    MY_DOMAIN_PROGRAM_INTERPOLATE(uv);

    return o;
}
#endif