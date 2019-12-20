using System.Collections;
using UnityEngine;

public class SetInteractiveShaderEffects : MonoBehaviour {

    [SerializeField]
    private RenderTexture rt;

    [SerializeField]
    private Transform target;

    [SerializeField]
    private Material BlendGreenColor;

    [SerializeField, Range(0.1f, 30f)]
    private float ResetDuration = 10f;

    private RenderTexture temp_rt;

    private Material bGCMaterialIns;

    private int shaderPosID = Shader.PropertyToID("_Position");

    private void Awake() {
        temp_rt = new RenderTexture(rt);

        temp_rt.Create();

        bGCMaterialIns = Material.Instantiate(BlendGreenColor);

        bGCMaterialIns.SetTexture("_DestTex", temp_rt);

        //戻る秒数の逆数を計算
        bGCMaterialIns.SetFloat("_InvResetDuration", 1f / ResetDuration);

        Shader.SetGlobalTexture("_GlobalEffectRT", temp_rt);

        Shader.SetGlobalFloat("_OrthographicCamSize", GetComponent<Camera>().orthographicSize);
    }

    private IEnumerator OnPostRender() {
        yield return new WaitForEndOfFrame();

        var tempRenderTex = RenderTexture.GetTemporary(temp_rt.width, temp_rt.height, temp_rt.depth, temp_rt.format, RenderTextureReadWrite.Default);

        //なんという三回コピー。。。
        Graphics.Blit(temp_rt, tempRenderTex);

        Graphics.Blit(rt, tempRenderTex, bGCMaterialIns);

        Graphics.Blit(tempRenderTex, temp_rt);

        RenderTexture.ReleaseTemporary(tempRenderTex);
    }

    private void LateUpdate() {
        //フィールド（且移動しない）をターゲットとしているなら、ここの処理要らない
        var pos = target.transform.position;

        pos.y = transform.position.y;

        transform.position = pos;

        Shader.SetGlobalVector(shaderPosID, pos);
    }

    private void OnDestroy() {
        if(temp_rt.IsCreated())
            temp_rt.Release();

        Destroy(bGCMaterialIns);
    }
}
