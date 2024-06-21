using System;
using UnityEngine;
using System.Collections;

//确保在编辑器模式下也执行，并且需要绑定组件摄像机
[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]

public class PostEffectsBase : MonoBehaviour
{
    //需要在开始时调用CheckResourses函数检查各个资源条件是否满足
    protected void CheckRresources()
    {
        bool isSupported = CheckSupport();
        if (isSupported == false)
        {
            NotSupported();
        }
    }
    
    //检查资源是否支持当前平台
    protected bool CheckSupport()
    {
        if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
        {
            Debug.LogWarning("This platform does not support image effect or render texture.");

            return false;
        }

        return true;
    }
    
    //当平台不支持当前这个效果时
    protected void NotSupported()
    {
        enabled = false;
    }

    protected void Start()
    {
        CheckRresources();
    }
    
    //当需要被效果创建材质时调用
    //第一个参数代表着使用该特效时需要调用的shader，第二个参数是用于后期处理的材质
    protected Material checkShaderAndCreateMaterial(Shader shader, Material material)
    {
        //首先检查shader的可用性
        if (shader == null)
        {
            return null;
        }

        //检查通过返回一个使用了该shader的材质
        if (shader.isSupported && material && material.shader == shader)
        {
            return material;
        }

        //如果该shader不支持，则返回空，否则使用该shader
        if (!shader.isSupported)
        {
            return null;
        }
        else
        {
            material = new Material(shader);

            material.hideFlags = HideFlags.DontSave;//不保存材质的实例，代表着不把数据写入文件
            if (material)
            {
                return material;
            }
            else
            {
                return null;
            }
        }
    }
}