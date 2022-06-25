using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[System.Serializable]
[VolumeComponentMenuForRenderPipeline("Custom/VolumetricCloud", typeof(UniversalRenderPipeline))]
public class VolumetricCloud: VolumeComponent, IPostProcessComponent{

    [Tooltip("Base Color")]
    public ColorParameter baseColor = new ColorParameter(new Color(1, 1, 1, 1));
    [Tooltip("Density Noise")]
    public Texture3DParameter densityNoise = new Texture3DParameter(null);
    [Tooltip("Density Noise Scale")]
    public Vector3Parameter densityNoiseScale = new Vector3Parameter(Vector3.one);
    [Tooltip("Density Noise Offset")]
    public Vector3Parameter densityNoiseOffset = new Vector3Parameter(Vector3.zero);
    [Tooltip("Molar Extinction Coefficient")]
    public MinFloatParameter absorption = new MinFloatParameter(1, 0);
    [Tooltip("Light Molar Extinction Coefficient")]
    public MinFloatParameter lightAbsorption = new MinFloatParameter(1, 0);
    [Tooltip("Light Absorption In Cloud")]
    public MinFloatParameter lightPower = new MinFloatParameter(1, 0);

    public bool IsActive() => true;
    public bool IsTileCompatible() => false;
    public void load(Material material, ref RenderingData data){
        /* 将所有的参数载入目标材质 */

        material.SetColor("_BaseColor", baseColor.value);
        if(densityNoise != null){
            material.SetTexture("_DensityNoiseTex", densityNoise.value);
        }
        material.SetVector("_DensityNoise_Scale", densityNoiseScale.value);
        material.SetVector("_DensityNoise_Offset", densityNoiseOffset.value);
        material.SetFloat("_Absorption", absorption.value);
        material.SetFloat("_LightAbsorption", lightAbsorption.value);
        material.SetFloat("_LightPower", lightPower.value);
    }
}