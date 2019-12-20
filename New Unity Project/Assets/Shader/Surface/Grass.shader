//�Q�l�y�[�W�Fhttps://roystan.net/articles/grass-shader.html
Shader "Custom/Grass"
{
    Properties
    {
		[Header(Shading)]
        _TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)
		_TranslucentGain("Translucent Gain", Range(0,1)) = 0.5
		//�|���
		_BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2
		
		[Header(BladeSize)]
		_BladeWidth("Blade Width", float) = 0.05
		_BladeWidthRandom("Blade Width Random", float) = 0.02
		_BladeHeight("Blade Height", float) = 0.5
		_BladeHeightRandom("Blade Height Random", float) = 0.3
		//�X�΂̖ʂő���|�������ꍇ�l��傫������
		_BladeForward("Blade Forward Amount", float) = 0.38
		//���̐ݒ�l�̊g��{��
		_BladeCurve("Blade Curvature Amount", Range(1, 4)) = 2

		[Header(Tessllation)]
		_TessellationUniform("TessllationUniform", Range(1, 100)) = 1 
		
		[Header(Wind)]
		//���ɂ��Ȃт����߂̃e�N�X�`���A�ԂƃO���[���̂Q�`�����l���Ǝg���e�N�X�`��
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

	//���_�V�F�[�_�[�͉������Ȃ��A���̂܂܎��̃X�e�[�W�ɏ���n��
	vertexInput vert(vertexInput IN)
	{
		return IN;
	}

	geometryOutput VertexOutput(float3 pos, float2 uv, float3 normal) 
	{
		geometryOutput o;

		o.pos = UnityObjectToClipPos(pos);

#if UNITY_PASS_SHADOWCASTER
		//�V���h�E�\�������j�A�ɂ���
		//�M�U�M�U������
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

	//�W�I���g���V�F�[�_�[�ł̓o�[�e�b�N�X����̏o�͂��󂯎��ׂ�
	//���ԁF�o�[�e�b�N�X���n�����e�b�Z���[�V�������h���C�����W�I���g�����s�N�Z��
	//�umaxvertexcount�v�ŕK�v�Ȓ��_�����w��AGPU������͂���Əo�͂���
	[maxvertexcount(BLADE_SEGMENTS * 2 + 2)]
	void geo(point vertexOutput IN[1] : SV_POSITION, inout TriangleStream<geometryOutput> triStream)
	{
		//�v���~�e�B�u�̔C�ӂ̒��_������
		float3 pos = IN[0].vertex;

		float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;

		//�p�X���
		float2 w_pos = mul(unity_ObjectToWorld, pos).xz;

		float2 pathUV = w_pos - _Position.xz;

		pathUV = pathUV / (_OrthographicCamSize * 2.0) + 0.5;

		fixed4 pathCol = tex2Dlod(_GlobalEffectRT, float4(pathUV, 0, 0));

		//tex2Dlod(_WindDistortionMap, float4(uv, 0, 0))�́u0.5~1�v�ɂȂ�̂ŁA������u0~1�v�ɂ���
		float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;

		float3 wind = normalize(float3(windSample.xy, 0));

		//z
		float3 vNormal = IN[0].normal;
		
		//x
		float4 vTangent = IN[0].tangent;
		
		//�Ō�vTangent.w��������̂́Adx����opengl���̍����z�����邽�߂���
		//�uvTangent.w�v�ɂ̓��f�����O���C���|�[�g���ꂽ�����f���ɂ������ubinormal�v�͂��łɊi�[�ς�
		float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;

		//�ڋ�Ԃ��烂�f����Ԃɕϊ����邽�߂̃}�g���b�N�X
		float3x3 tangentToLocal = float3x3(
			vTangent.x, vBinormal.x, vNormal.x,
			vTangent.y, vBinormal.y, vNormal.y,
			vTangent.z, vBinormal.z, vNormal.z
			);

		//Up���ɉ�������]�̂��߂̃}�g���b�N�X
		//�ڋ�Ԃł́uUp�v�����uZ���v
		//�����̂��߂̉�]
		float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));

		//NOTE:�������[�g�ɍ��Ղ��c�������ꍇ�A�����̃}�g���b�N�X��M��΍ςނ̂ŁA�󋵂��m�F����
		//x���ɉ����������_����]�̂��߂̃}�g���b�N�X
		//�K��(180*0.5)�x�ȉ��ɂȂ�
		//�|�����߂̉�]
		//float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * /*lerp(_BendRotationRandom, 1, pathCol.g) **/ UNITY_PI * 0.5, float3(-1, 0, 0));

		//���Ȃт����߂̃}�g���b�N�X
		float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample, wind);

		//�l�̃}�g���b�N�X����������
		float3x3 transformationMatrix = mul(mul(tangentToLocal, windRotation), facingRotationMatrix);//mul(mul(mul(tangentToLocal, windRotation), facingRotationMatrix), bendRotationMatrix);

		//�|�����߂̃}�g���b�N�X�����f����ԓ��Ɉڂ�
		float3x3 transformationMatrixFacing = mul(tangentToLocal, facingRotationMatrix);

		//Z
		float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
		
		//x
		float width = (rand(pos.xyz) * 2 - 1) * _BladeWidthRandom + _BladeWidth;

		//y
		float forward = rand(pos.yyz) * _BladeForward;

		//�������̒��_�̂��߂̃}�g���b�N�X
		float3x3 loopTransformMatrix = transformationMatrixFacing;

		//�P���ɍœK��
		float inv_BLADE_SEGMENTS = 1 / (float)BLADE_SEGMENTS;

		//���_�������₷
		//�K�w�I�ɒ��_��U�蓖�Ă�A�Ō�ɂȂ�Ɓuwidth�v���u0�v�ɂȂ�
		for(int i = 0; i < BLADE_SEGMENTS + 1; i++) 
		{
			float t = i * inv_BLADE_SEGMENTS;
			
			//���[�v����΂���قǕ����������Ȃ�
			float segmentsWidth = width * (1 - t * 0.25);

			//���[�v����΂���قǍ�����������
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
				
				//Cull���Ȃ����߁A���ʂƔw�ʂ𕪂���K�v������܂�
				float3 normal = i.normal * clamp(step(facing, 0), 1, -1);

				//�g�U���˂̋���
				float NDotL = saturate(saturate(dot(normal, _WorldSpaceLightPos0)) + _TranslucentGain) * shadow;

				//�����̏��
				float3 ambient = ShadeSH9(float4(normal, 1));

				//���C�g�̐F��S�����Z
				float4 lightIntensity = NDotL * _LightColor0 + float4(ambient, 1);

				//�������͑S�����̉e���󂯂Ȃ�
				float4 col = lerp(_BottomColor, _TopColor * lightIntensity, i.uv.y);
				
				return col;
			}
			ENDCG
		}

		//�V���h�[���e
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
				//return 0�����ł��e�𗎂Ƃ���
				//�A�e�`��
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
}