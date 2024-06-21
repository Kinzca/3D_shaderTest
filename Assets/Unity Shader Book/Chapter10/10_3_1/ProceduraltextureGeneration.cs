using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Unity_Shader_Book.Chapter10._10_3_1
{
    [ExecuteInEditMode]
    public class ProceduralTextureGeneration : MonoBehaviour
    {
        //声明一个材质，这个材质将使用该脚本中生成的纹理程序
        public Material material = null;
        
        //然后声明使用该纹理的各种参数

        #region Material properties

        //纹理大小，通常是2的整数次幂
        [SerializeField, SetProperty("textureWidth")]
        private int m_textureWidth = 512;
        public int textureWidth
        {
            get
            {
                return m_textureWidth;
            }
            set
            {
                m_textureWidth = value;
                _UpdateMaterial();
            }
        }
        
        //纹理背景颜色
        [SerializeField,SetProperty("backgroundColor")]
        private Color m_backgroundColor = Color.white;
        public Color backgroundColor
        {
            get
            {
                return m_backgroundColor;
            }
            set
            {
                m_backgroundColor = value;
                _UpdateMaterial();
            }
        }

        //原点颜色
        [SerializeField, SetProperty("circleColor")]
        private Color m_circleColor = Color.yellow;
        public Color circleColor
        {
            get
            {
                return m_circleColor;
            }
            set
            {
                m_circleColor = value;
                _UpdateMaterial();
            }
        }

        //模糊影子
        [SerializeField, SetProperty("blurFactor")]
        private float m_blurFactor = 2.0f;
        public float blurFactor
        {
            get
            {
                return m_blurFactor;
            }
            set
            {
                m_blurFactor = value;
                _UpdateMaterial();
            }
        }

        #endregion
        
        //声明一个Texture2D类型的变量,用于存储程序纹理
        private Texture2D m_generateTexture = null;

        private void Start()
        {
            //在Start函数中进行检查，得到所需要的函数
            if (material == null)
            {
                Renderer renderer = gameObject.GetComponent<Renderer>();
                if (renderer == null)
                {
                    Debug.LogWarning("Connot find a renderer.");
                }

                material = renderer.sharedMaterial;
            }

            _UpdateMaterial();
        }

        private void _UpdateMaterial()
        {
            if (material != null)
            {
                //确保material不为空后，调用_GeneraProceduralTexture生成一张程序纹理，并赋给m_generaTexture
                //然后利用Material.SetTexture将生成的纹理赋给材质
                //material中需要有一个名为_MainTex的纹理属性
                m_generateTexture = _GenerateProceduralTexture();
                material.SetTexture("_MainTex",m_generateTexture);
            }
        }

        private Texture2D _GenerateProceduralTexture()
        {
            //初始化一张二维纹理
            Texture2D proceduralTexture = new Texture2D(textureWidth, textureWidth);
            
            //定义圆与圆之间的间距
            float circleTnterval = textureWidth / 4.0f;
            //定义圆的半径
            float radius = textureWidth / 10.0f;
            //定义模糊系数
            float edgeBlur = 1.0f / blurFactor;

            for (int w = 0; w < textureWidth; w++) 
            {
                for (int h = 0; h < textureWidth; h++)
                {
                    //使用背景颜色初始化
                    Color pixel = backgroundColor;
                    
                    //以此画9个圆
                    for (int i = 0; i < 3; i++)
                    {
                        for (int j = 0; j < 3; j++)
                        {
                            //计算当前圆心的位置
                            Vector2 circleCenter = new Vector2(circleTnterval * (i + 1), circleTnterval * (j + 1));
                            
                            //计算当前像素和圆心的位置
                            float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;
                            
                            //模糊圆的边界
                            Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f), Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));
                            
                            //与之前得到的颜色混合
                            pixel = _MixColor(pixel, color, color.a);
                        }
                    }
                    proceduralTexture.SetPixel(w,h,pixel);
                }
            }
            //将像素值写入纹理中
            proceduralTexture.Apply();
            return proceduralTexture;
        }

        private Color _MixColor(Color color0, Color color1, float mixFactor)
        {
            Color mixColor = Color.white;
            mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
            mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
            mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
            mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);

            return mixColor;
        }
    }
}