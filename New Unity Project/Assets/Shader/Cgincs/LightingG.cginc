#ifndef LIGHTING_G_INCLUDED
#define LIGHTING_G_INCLUDED

#include "Lighting.cginc"
#include "ShapeAndMathG.cginc"

//�g�U����
fixed3 diffuse(fixed3 w_nomral) {
	fixed3 v = max(0, dot(w_nomral, _WorldSpaceLightPos0.xyz));

	return v;
}

//���ʔ���(�u�����t�H�����f���A���ꂪ�y�ʉ���������)
fixed3 specularLightVer(fixed3 vertexWPos, fixed3 w_normal, fixed shininess) {
	fixed3 eyeVec = normalize(_WorldSpaceCameraPos.xyz - vertexWPos);

	fixed3 halfV = normalize(_WorldSpaceLightPos0.xyz + eyeVec.xyz);

	return pow(max(0, dot(halfV, w_normal)), shininess);
}

//���ʔ���(�t�H�����f���A�v�Z�ʂ�����Ƒ���)
fixed3 specular(fixed3 w_ndotl, fixed3 w_lightdir, fixed3 w_normal, fixed3 v_pos, fixed3 shininess) {
	//���˃x�N�g��
	fixed3 r = w_ndotl * w_normal * 2 - w_lightdir;

	fixed3 spec = pow(max(0, dot(r, v_pos)), shininess);

	return spec;
}

/*fixed3 halfVec(fixed3 vertexWPos) {
	fixed3 eyeVec = normalize(_WorldSpaceCameraPos.xyz - vertexWPos);
	
	return normalize(_WorldSpaceLightPos0.xyz + eyeVec);
}*/

//�o���v�}�b�s���O
fixed bumpMapping(fixed3 t, fixed3 b, fixed3 n, sampler2D bumpTex, fixed2 uv) {
	
	fixed3 localLightPos = mul(unity_WorldToObject, _WorldSpaceLightPos0.xyz);

	fixed3 lightDir = normalize(mul(localLightPos, invTangentMatrix(t, b, n)));

	fixed3 normal = UnpackNormal(tex2D(bumpTex, uv));

	return max(0, dot(lightDir, normal));
}

//�y���o�[�W�����̃o���v�}�b�s���O
//t_lightDir == �ڋ�Ԃ̃��C�g����
fixed bumpMappingLite(fixed3 t_lightDir, sampler2D bumpTex, fixed2 uv) {
	fixed3 normal = UnpackNormal(tex2D(bumpTex, uv));

	return max(0, dot(normalize(t_lightDir), normal));
}

#endif