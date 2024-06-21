using System;
using UnityEngine;

public class FogWithDepthTexture : PostEffectsBase
{
    public Shader fogShader;
    private Material fogMaterial = null;

    public Material material
    {
        get
        {
            fogMaterial = checkShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
        }
    }

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

    //需要获取摄像机的相关参数，例如近剪裁平面的距离，FOV；同时还需要世界空间下的方位，用两个变量存储摄像机的camera和transform组件
    private Transform myCameraTransform;
    public Transform CameraTransform
    {
        get
        {
            if (myCameraTransform == null)
            {
                myCameraTransform = camera.transform;
            }
            return myCameraTransform;
        }
    }

    [Range(0.0f, 3.0f)] public float fogDensity = 1.0f;//控制雾的浓度
    
    public Color fogColor = Color.white;//控制雾的颜色

    public float fogStart = 0.0f;//控制雾的起始高度
    public float fogEnd = 2.0f;//控制雾的终止高度

    private void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;//获取深度纹理
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            Matrix4x4 frustumCornera = Matrix4x4.identity;

            //获得摄像机的fov，近剪裁平面，远剪裁平面，和摄像机的横纵比
            float fov = camera.fieldOfView;
            float near = camera.nearClipPlane;
            float far = camera.farClipPlane;
            float aspect = camera.aspect;

            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
            Vector3 toRight = CameraTransform.right * halfHeight * aspect;
            Vector3 toTop = CameraTransform.up * halfHeight;

            Vector3 topLeft = CameraTransform.forward * near + toTop - toRight;
            float scale = topLeft.magnitude / near;
            
            topLeft.Normalize();
            topLeft *= scale;

            //计算四个角的顶点坐标
            Vector3 topRight = CameraTransform.forward * near + toTop + toRight;
            topRight.Normalize();
            toRight *= scale;

            Vector3 bottomLeft = CameraTransform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;

            Vector3 bottomRight = CameraTransform.forward * near + toRight - toTop;
            bottomRight.Normalize();
            bottomRight *= scale;
            
            //计算完成后将其存储在frustumCornera中
            frustumCornera.SetRow(0,bottomLeft);
            frustumCornera.SetRow(1,bottomRight);
            frustumCornera.SetRow(2,topRight);
            frustumCornera.SetRow(3,topLeft);
            
            material.SetMatrix("_FrustumCornersRay",frustumCornera);
            material.SetMatrix("_ViewProjectionInverseMatrix",(camera.projectionMatrix * camera.worldToCameraMatrix).inverse);
            
            material.SetFloat("_FogDensity",fogDensity);
            material.SetColor("_FogColor",fogColor);
            material.SetFloat("_FogStart",fogStart);
            material.SetFloat("_FogEnd",fogEnd);
            
            Graphics.Blit(source,destination,material);
        }
        else
        {
            Graphics.Blit(source,destination);
        }
    }
}
