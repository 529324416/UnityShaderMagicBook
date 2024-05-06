using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Serialization;

[System.Serializable]
[VolumeComponentMenuForRenderPipeline("Custom/VolumetricCloud", typeof(UniversalRenderPipeline))]
public class VolumetricCloud: VolumeComponent, IPostProcessComponent{
    
    [Header("Shape Controller")]
    [Tooltip("Density Noise")]
    public Texture3DParameter densityNoise = new Texture3DParameter(null);
    
    [Tooltip("Density Noise Scale")]
    public Vector3Parameter densityNoiseScale = new Vector3Parameter(Vector3.one);
    
    [Tooltip("Density Noise Offset")]
    public Vector3Parameter densityNoiseOffset = new Vector3Parameter(Vector3.zero);
    
    [Tooltip("Density Scale")]
    public ClampedFloatParameter densityScale = new ClampedFloatParameter(1f, 0, 20, true);

    public Texture3DParameter densityErodeTex = new Texture3DParameter(null);
    public Vector3Parameter densityErodeScale = new Vector3Parameter(Vector3.one);
    public Vector3Parameter densityErodeOffset = new Vector3Parameter(Vector3.zero);
    public ClampedFloatParameter densityErode = new ClampedFloatParameter(1f, 0, 10, true);
    
    
    [Tooltip("Bounds Box Max Point")]
    public Vector3Parameter boundsMax = new Vector3Parameter(Vector3.zero);
    
    [Tooltip("Bounds Box Min Point")]
    public Vector3Parameter boundsMin = new Vector3Parameter(Vector3.zero);
    
    [Tooltip("Edge Softness Distance XZ")]
    public ClampedFloatParameter edgeSoftness = new ClampedFloatParameter(20f, 1f, 100f, true);
    
    [Tooltip("Edge Softness Distance Y")]
    public ClampedFloatParameter edgeSoftnessY = new ClampedFloatParameter(5f, 1f, 100f, true);
    
    
    [Header("Lighting Controller")]
    [Tooltip("Base Color")]
    public ColorParameter baseColor = new ColorParameter(new Color(1, 1, 1, 1));
    
    [Tooltip("Molar Extinction Coefficient")]
    public MinFloatParameter absorption = new MinFloatParameter(1, 0);
    
    [Tooltip("Light Molar Extinction Coefficient")]
    public MinFloatParameter lightAbsorption = new MinFloatParameter(1, 0);
    
    [Tooltip("Cloud Coverage")]
    public Vector3Parameter sigma = new Vector3Parameter(new Vector3(1f, 1f, 1f));
    
    [Tooltip("Phase Function Param")]
    public ClampedFloatParameter phaseFunctionParam0 = new ClampedFloatParameter(0f, -0.99f, 0.99f, true);
    
    [Tooltip("Phase Function Param")]
    public ClampedFloatParameter phaseFunctionParam1 = new ClampedFloatParameter(0f, -0.99f, 0.99f, true);
    
    [Tooltip("Light Absorption In Cloud")]
    public MinFloatParameter lightPower = new MinFloatParameter(1, 0);
    
    

    public bool IsActive() => true;
    public bool IsTileCompatible() => false;
    public void load(Material material, ref RenderingData data){
        /* 将所有的参数载入目标材质 */
        
        material.SetColor("_BaseColor", baseColor.value);
        if(densityNoise.value != null){
            material.SetTexture("_DensityNoiseTex", densityNoise.value);
        }
        if(densityErodeTex.value != null){
            material.SetTexture("_DensityErodeTex", densityErodeTex.value);
        }
        material.SetVector("_DensityErode_Scale", densityErodeScale.value);
        material.SetVector("_DensityErode_Offset", densityErodeOffset.value);
        material.SetFloat("_DensityErode", densityErode.value);
        material.SetVector("_DensityNoise_Scale", densityNoiseScale.value);
        material.SetVector("_DensityNoise_Offset", densityNoiseOffset.value);
        material.SetFloat("_Absorption", absorption.value);
        material.SetFloat("_LightAbsorption", lightAbsorption.value);
        material.SetFloat("_LightPower", lightPower.value);
        material.SetVector("_Sigma", sigma.value);
        material.SetFloat("_HgPhaseG0", phaseFunctionParam0.value);
        material.SetFloat("_HgPhaseG1", phaseFunctionParam1.value);
        material.SetFloat("_DensityScale", densityScale.value);

        material.SetVector("_BoundsMax", boundsMax.value);
        material.SetVector("_BoundsMin", boundsMin.value);
        
        material.SetVector("_EdgeSoftnessThreshold", new Vector4(edgeSoftness.value, edgeSoftnessY.value, 0, 0));

        // Bounds box = boundsBox.value.GetComponent<BoxCollider>().bounds;
        // material.SetVector("_BoundsMin", boundsMin.value);
        // material.SetVector("_BoundsMax", boundsMax.value);

    }
}