using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class EdgeDetectNormalAndDepth : PostEffectsBase
{
    public Shader edgeDetectShader;
    private Material edgeDetectMaterial = null;

    public Slider backGroundSlider;
    public Slider SamlpeDistanceSlider;
    
    public Material material
    {
        get
        {
            edgeDetectMaterial = checkShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }
    }

    [Range(0.0f, 1.0f)] public float edgesOnly = 0.0f;

    public Color edgeColor = Color.black;
    
    public Color backgroundColor = Color.white;

    public float sampleDistance = 1.0f;//使用法线+纹理采样时使用的距离，值越大描边越宽

    //下面两个变量的差值用于记录深度值和法线值的差值，会被用于记录相差多少时会生成一条边，差值越大（灵敏度越大）
    public float sensitivityDepth;
    public float sensitivityNormals;

    //本例中需要法线+深度纹理，在脚本的OnEnable设置相应状态
    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
    }

    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_EdgeOnly",backGroundSlider.value);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor",backgroundColor);
            material.SetFloat("_SampleDistance",SamlpeDistanceSlider.value);
            material.SetVector("_Sensitity",new Vector4(sensitivityNormals,sensitivityDepth,0.0f,0.0f));
            
            Graphics.Blit(source,destination,material);
        }
        else
        {
            Graphics.Blit(source,destination);
        }
    }
}
