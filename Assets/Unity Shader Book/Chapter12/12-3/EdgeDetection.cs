using System;
using UnityEngine;
using UnityEngine.UI;

public class EdgeDetection : PostEffectsBase
{
    //声明该效果所需的shader，并创建相应的材质
    public Shader edgeDetectShader;
    private Material edgeDetectMaterial = null;

    public Slider EdgesOnlySlider;
    
    public Material material
    {
        get
        {
            //edgeDetectShader对应着我们指定的shader
            edgeDetectMaterial = checkShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }
    }

    [Range(0.0f, 1.0f)] public float edgesOnly = 0.0f;
    //edgesOnly为0,边缘将叠加到原渲染图像上；为1时只显示边缘不显示原图像
    //其中背景颜色由backgroundColor指定，边缘颜色由edgeColor指定
    public Color edgeColor = Color.black;
    public Color backgroundColor = Color.white;
    
    //定义OnRenderImage进行特效处理
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_EdgeOnly",EdgesOnlySlider.value);
            material.SetColor("_EdgeColor",edgeColor);
            material.SetColor("_BackgroundColor",backgroundColor);
            
            Graphics.Blit(source,destination,material);
        }
        else
        {
            Graphics.Blit(source,destination);
        }
    }
}

