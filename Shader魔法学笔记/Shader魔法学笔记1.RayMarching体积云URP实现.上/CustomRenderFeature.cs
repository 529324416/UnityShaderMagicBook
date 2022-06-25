using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CustomRenderFeature: ScriptableRendererFeature{

    [SerializeField] private Shader shader;             // 手动指定该RenderFeature的所用到的Shader
    [SerializeField] private RenderPassEvent evt = RenderPassEvent.BeforeRenderingPostProcessing;
    private Material matInstance;                       // 创建一个该Shader的材质对象
    private CustomRenderPass pass;                      // RenderPass

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData){

        if(shader == null)return;
        if(matInstance == null){
            matInstance = CoreUtils.CreateEngineMaterial(shader);
        }
        RenderTargetIdentifier currentRT = renderer.cameraColorTarget;
        pass.Setup(currentRT, matInstance);
        renderer.EnqueuePass(pass);
    }
    public override void Create(){
        
        pass = new CustomRenderPass();
        pass.renderPassEvent = evt;
    }
}