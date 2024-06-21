using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffectsBase
{
    public Shader motionBlurShader;
    private Material motionBlurMaterial = null;

    public Material material
    {
        get
        {
            motionBlurMaterial = checkShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    [Range(0.0f, 1.0f)] public float blurSize = 0.5f;
    
    //定义camera类型的变量，来获取脚本所在的的摄像机组件
    private Camera myCamera;

    public Camera camera
    {
        get
        {
            if (myCamera == null)
            {
                myCamera = GetComponent<Camera>();
            }

            return myCamera;
        }
    }
    
    //定义一个变量保存上一帧的摄像机的 视角*投影矩阵
    private Matrix4x4 previousViewProjectionMatrix;
    
    //由于需要摄像机的深度纹理，在脚本的OnEnable中设置摄像机的状态
    private void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }
    
    //最后再实现OnRenderImage函数
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("BlurSize",blurSize);
            
            material.SetMatrix("_PreviousViewProjectionMatrix",previousViewProjectionMatrix);//存储取逆前的结果
            Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix; //当前帧的视角矩阵*投影矩阵的逆矩阵
            Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse; //存储取逆后的结果
            material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);//存储取逆后的结果
            previousViewProjectionMatrix = currentViewProjectionMatrix; //存储取逆前的结果，以便在下一帧时传递给他们的材质_PreviousViewProjectionMatrix
            
            Graphics.Blit(source,destination,material);
        }
        else
        {
            Graphics.Blit(source,destination);
        }
    }
}
