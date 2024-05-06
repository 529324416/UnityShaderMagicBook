using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class CustomRenderPass: ScriptableRenderPass{

    const string customPassTag = "Custom Render Pass";
    private VolumetricCloud parameters;
    private Material mat;
    private RenderTargetIdentifier sourceRT;
    private RenderTargetHandle tempRT;

    public void Setup(RenderTargetIdentifier identifier, Material material){
        
        this.sourceRT = identifier;
        this.mat = material;
    }
    public override void Execute(ScriptableRenderContext ctx, ref RenderingData data){

        VolumeStack stack = VolumeManager.instance.stack;
        parameters = stack.GetComponent<VolumetricCloud>();
        CommandBuffer command = CommandBufferPool.Get(customPassTag);
        Render(command, ref data);
        ctx.ExecuteCommandBuffer(command);
        CommandBufferPool.Release(command);
        command.ReleaseTemporaryRT(tempRT.id);
    }
    public void Render(CommandBuffer command, ref RenderingData data){

        if(parameters.IsActive()){
            parameters.load(mat, ref data);
            RenderTextureDescriptor opaqueDesc = data.cameraData.cameraTargetDescriptor;
            opaqueDesc.depthBufferBits = 0;
            command.GetTemporaryRT(tempRT.id, opaqueDesc);
            command.Blit(sourceRT, tempRT.Identifier(), mat);
            command.Blit(tempRT.Identifier(), sourceRT);
        }
    }
}