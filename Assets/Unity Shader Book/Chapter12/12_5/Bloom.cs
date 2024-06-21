using UnityEngine;

public class Bloom : PostEffectsBase
{
    public Shader bloomShader;
    private Material bloomMaterial = null;

    public Material material
    {
        get
        {
            bloomMaterial = checkShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }
    
    
    //模糊迭代次数，次数越大越模糊
    [Range(0, 4)] public int iterations = 3;
    //每次模糊的散布，数值越大越模糊
    [Range(0.2f, 3.0f)] public float blurSpread = 0.6f;
    //图像降采样,downSample数值越大，需要处理的像素数越少，越模糊，但过大的downSample会使图像像素化
    [Range(1,8)] public int downSample = 2;
    //控制较亮区域时使用的阈值大小
    [Range(0.0f, 4.0f)] public float luminanceThreshold = 0.6f;
    
    //考虑了高斯模糊迭代次数的最终版本
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_LuminanceThreshold",luminanceThreshold);
            
            int rtW = source.width / downSample;
            int rtH = source.height / downSample;

            //第一个缓存buffer0，将原纹理（_MainTex）缩放后存储到buffer0
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;//双管线
            
            //将缩放后的原纹理存储到buffer0
            Graphics.Blit(source,buffer0,material,0);

            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize",1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                
                //进行竖直滤波,将结果存储到buffer1,buffer0是中间缓存
                Graphics.Blit(buffer0,buffer1,material,1);
                RenderTexture.ReleaseTemporary(buffer0);//释放buffer0
                
                buffer0 = buffer1;//将上一步的结果存储到buffer0中
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                
                Graphics.Blit(buffer0,buffer1,material,2);//对buffer0使用material进行处理将结果存储到buffer1中
                RenderTexture.ReleaseTemporary(buffer0);//释放buffer0
                buffer0 = buffer1;//将buffer0指向buffer1的内存地址，以便下一次循环使用
            }
            
            material.SetTexture("_Bloom",buffer0);
            
            //将最终的结果存储到destination
            Graphics.Blit(buffer0,destination,material,3);
            RenderTexture.ReleaseTemporary(buffer0);//最终循环结束后再释放buffer0
        }
        else
        {
            Graphics.Blit(source,destination);
        }
    }
}
