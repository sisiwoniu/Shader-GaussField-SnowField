using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public sealed class GameboyEffect : MonoBehaviour {

    [SerializeField]
    private Shader GameBoyShader;

    [SerializeField, Range(0.001f, 0.01f)]
    private float PixelSize = 0.001f;

    private Material material;

    private Camera c;

    private int pixelSizeID = Shader.PropertyToID("_PixelSize");

    private int revPixelSizeID = Shader.PropertyToID("_RevPixelSize");

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if(c == null)
            c = GetComponent<Camera>();

        if(material == null) {
            material = new Material(GameBoyShader);

            SetupGameBoyColor();
        }

        material.SetFloat(pixelSizeID, PixelSize);

        material.SetFloat(revPixelSizeID, 1f / PixelSize);

        c.targetTexture = null;

        Graphics.Blit(source, null, material);
    }

    private void Awake() {
        material = new Material(GameBoyShader);

        c = GetComponent<Camera>();

        SetupGameBoyColor();
    }

    private void SetupGameBoyColor() {
        var lightestColor = new Color(155f / 255f, 188f / 255f, 15f / 255f, 1f);

        var lightColor = new Color(139f / 255f, 172f / 255f, 15f / 255f, 1f);

        var darkColor = new Color(48f / 255f, 98f / 255f, 45f / 255f, 1f);

        var darkestColor = new Color(15f / 255f, 56f / 255f, 15f / 255f, 1f);

        material.SetColor("_DarkestColor", darkestColor);

        material.SetColor("_DarkColor", darkColor);

        material.SetColor("_LightestColor", lightestColor);

        material.SetColor("_LightColor", lightColor);
    }
}