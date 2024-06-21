using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : PostEffectsBase
{
    public Shader motionShader;
    private Material motionBlurMaterial = null;

    public Material material
    {
        get
        {
            motionBlurMaterial = checkShaderAndCreateMaterial(motionShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    //运动模糊所需要地参数，blurAmount的值越大，运动拖尾的效果越明显，为了防止拖尾效果完全替代当前帧的渲染结果，值取0.0-0.9间
    [Range(0.0f, 0.9f)] public float blurAmount = 0.5f;
 
    //定义RenderTexture，保存之前叠加的结果
    private RenderTexture accumulationTexture;

    private void OnDisable()
    {
        //该脚本不运行时，调用OnDisable销毁accumulationTexture 
        DestroyImmediate(accumulationTexture);
    }
    
    //定义运动模糊使用的OnRenderImage
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            //创建用于累加的图像
            if (accumulationTexture == null || accumulationTexture.width !=
                source.width || accumulationTexture.height != source.height)
            {
                DestroyImmediate(accumulationTexture);
                accumulationTexture = new RenderTexture(source.width, source.height, 0);
                accumulationTexture.hideFlags = HideFlags.HideAndDontSave;//不会显示在Hierarchy，也不会保存
                Graphics.Blit(source,accumulationTexture);//使用当前帧图像初始化
            }
            
            accumulationTexture.MarkRestoreExpected();//渲染纹理的恢复操作（渲染到纹理而该纹理没有被提前销毁或清空的情况下） 
            
            material.SetFloat("_BlurAmount",1.0f - blurAmount);
            
            Graphics.Blit(source,accumulationTexture,material);//将当前屏幕的图像叠加到accumulateTexture中
            Graphics.Blit(accumulationTexture,destination);//最后将结果显示到屏幕上
        }
        else
        {
            Graphics.Blit(source,destination);
        }
    }
}
