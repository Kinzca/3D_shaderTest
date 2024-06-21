using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GaussianBlur : PostEffectsBase
{
    public Shader gaussianBlurShader;
    private Material gaussianBlurMaterial = null;

    public Slider IterationSlider;
    public Material material
    {
        get
        {
            //gaussianBlurShader是我们指定的shader
            gaussianBlurMaterial = checkShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
            return gaussianBlurMaterial;
        }
    }
    
    //模糊迭代次数，次数越大越模糊
    [Range(0, 4)] public int iterations = 3;
    //每次模糊的散布，数值越大越模糊
    [Range(0.2f, 3.0f)] public float blurSpread = 0.6f;
    //图像降采样,downSample数值越大，需要处理的像素数越少，越模糊，但过大的downSample会使图像像素化
    [Range(1,8)] public int downSample = 2;
    
    
    // private void OnRenderImage(RenderTexture source, RenderTexture destination)
    // {
    //     if (material != null)
    //     {
    //         int rtW = source.width;
    //         int rtH = source.height;
    //         
    //         RenderTexture buffer = RenderTexture.GetTemporary(rtW,rtH,0);
    //         
    //         //执行第一个pass对竖直方向上进行滤波
    //         Graphics.Blit(source,material,0);
    //         //执行第二个pass对水平方向进行滤波
    //         Graphics.Blit(source,material,1);
    //         
    //         RenderTexture.ReleaseTemporary(buffer);//释放之前的缓存
    //     }
    //     else
    //     {
    //         Graphics.Blit(source,destination);
    //     }
    // }
    
    //第二种实现方法利用缩放图像对图像进行降采样，减少需要处理的图像个数
    // private void OnRenderImage(RenderTexture source, RenderTexture destination)
    // {
    //     if (material != null)
    //     {
    //         int rtW = source.width / downSample;
    //         int rtH = source.height / downSample;
    //
    //         RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
    //         buffer.filterMode = FilterMode.Bilinear;//将滤波模式改为双线性
    //         
    //         Graphics.Blit(source,buffer,material,0);
    //         Graphics.Blit(buffer,destination,material,1);
    //         
    //         RenderTexture.ReleaseTemporary(buffer);
    //     }
    //     else
    //     {
    //         Graphics.Blit(source,destination);
    //     }
    // }
    
    //考虑了高斯模糊迭代次数的最终版本
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            int rtW = source.width / downSample;
            int rtH = source.height / downSample;

            //第一个缓存buffer0，将原纹理（_MainTex）缩放后存储到buffer0
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;
            
            //将缩放后的原纹理存储到buffer0
            Graphics.Blit(source,buffer0);

            for (int i = 0; i < IterationSlider.value; i++)
            {
                material.SetFloat("_BlurSize",1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                
                //进行竖直滤波,将结果存储到buffer1,buffer0是中间缓存
                Graphics.Blit(buffer0,buffer1,material,0);
                RenderTexture.ReleaseTemporary(buffer0);//释放buffer0
                
                buffer0 = buffer1;//将上一步的结果存储到buffer0中
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                
                Graphics.Blit(buffer0,buffer1,material,1);//对buffer0使用material进行处理将结果存储到buffer1中
                RenderTexture.ReleaseTemporary(buffer0);//释放buffer0
                buffer0 = buffer1;//将buffer0指向buffer1的内存地址，以便下一次循环使用
            }
            
            //将最终的结果存储到destination
            Graphics.Blit(buffer0,destination);
            RenderTexture.ReleaseTemporary(buffer0);//最终循环结束后再释放buffer0
        }
        else
        {
            Graphics.Blit(source,destination);
        }
    }
}
