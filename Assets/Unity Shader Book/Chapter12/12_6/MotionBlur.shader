// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/MotionBlur"
{
    Properties
    {
        _MainTex("Base (GRB)",2D) = "white"{} //输入的渲染图像
        _BlurAmount("Blur Amount",Float) = 1.0 //混合图像时使用的渲染系数
    }
    
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"
        
        sampler2D _MainTex;
        fixed _BlurAmount;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
        };

        //定义的顶点着色器
        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            o.uv = v.texcoord;

            return o;
        }

        //第一个片元着色器，更新渲染纹理的RGB通道部分
        fixed4 fragRGB(v2f i) : SV_Target{
            return fixed4(tex2D(_MainTex,i.uv).rgb,_BlurAmount);//将A通道的部分设为_BlurAmount，以便以后可以使用透明通道进行混合
        }
        //更新A部分，直接返回采样结果
        half4 fragA(v2f i) : SV_Target{
            return tex2D(_MainTex,i.uv);
        }
        ENDCG
        
        //定义运动模糊所需的两个pass
        ZTest Always Cull Off
        
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha//设置混合模式，使用SrcAlpha作为混合因子，并将1-目标颜色的alpha的值作为混合因子
            
            ColorMask RGB//设置了颜色写入掩码，只允许 RGB 通道的颜色写入目标帧缓冲区，A 通道的颜色将被忽略
            
            CGPROGRAM

            #pragma vertex vert //指示编译名为vert的编译器，定义的顶点着色器处理纹理并将结果传递给片元着色器
            #pragma fragment fragRGB//指示编译名为frag的编译器，定义的片元着色器处理纹理并将结果显示在屏幕上
            
            ENDCG
        }

        Pass
        {
            Blend One Zero//设置了混合模式，其中 One 表示源颜色使用 1 作为混合因子，Zero 表示目标颜色使用 0 作为混合因子。
            ColorMask A//这行代码设置了颜色写入掩码，只允许 A 通道的颜色写入目标帧缓冲区，RGB 通道的颜色将被忽略。这意味着，只有 A 通道的颜色将被渲染到目标屏幕上，RGB 通道的颜色将保持不变
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment fragA
            
            ENDCG
        }
    }
Fallback Off
}
