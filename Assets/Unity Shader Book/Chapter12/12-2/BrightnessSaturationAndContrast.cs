using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class BrightnessSaturationAndContrast : PostEffectsBase //继承材质检测的基类
{
    //声明该效果所需要的Shader，并创建相应的材质
    public Shader briSatConShader;
    private Material _briSatConMaterial;

    public Slider BrightnessSlider;
    public Slider SaturationSlider;
    public Slider ContrastSlider;

    
    public Material material
    {
        //调用基类中的函数检测材质
        get
        {
            _briSatConMaterial = checkShaderAndCreateMaterial(briSatConShader, _briSatConMaterial);
            return _briSatConMaterial;
        }
    }

    [Range(0.0f, 3.0f)] public float brightness = 1.0f;
    [Range(0.0f, 3.0f)] public float saturation = 1.0f;
    [Range(0.0f, 3.0f)] public float contrast = 1.0f;
    
    //定义OnRenderImage函数进行特效处理
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_Brightness",BrightnessSlider.value);
            material.SetFloat("_Saturation",SaturationSlider.value);
            material.SetFloat("_Contrast",ContrastSlider.value);
            
            Graphics.Blit(source,destination,material);
        }
        else
        {
            Graphics.Blit(source,destination);
        }
    }
}
