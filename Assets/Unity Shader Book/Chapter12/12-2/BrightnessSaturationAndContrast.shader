// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/BrightnessSaturationAndContrast"
{
    //声明特效使用的各个属性
    Properties
    {
        _MainTex("Base (RGB)",2D) = "white"{}
        _Brightness("Brightness",Float) = 1
        _Saturation("Saturation",Float) = 1
        _Contrast("Contrast",Float) = 1
    }
    
    SubShader
    {
        Pass
        {
            //设置关闭深度写入
            ZTest Always Cull Off 
            ZWrite Off
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            half _Brightness;
            half _Saturation;
            half _Contrast;

            //定义顶点着色器
            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
            };

            //使用appdata_img作为顶点着色器输入
            //其中包含着顶点坐标和第一纹理坐标
            v2f vert(appdata_img v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord;

                return o;
            }

            //用于调整亮度，饱和度，和对比度的片元着色器
            fixed4 frag(v2f i) : SV_Target{
                fixed4 renderTex = tex2D(_MainTex,i.uv);//首先对原纹理进行采样

                //应用亮度
                fixed3 finalColor = renderTex.rgb * _Brightness;

                //应用饱和度
                fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                fixed3 luminanceColor = fixed3(luminance,luminance,luminance);
                finalColor = lerp(luminanceColor,finalColor,_Saturation);

                //应用对比度
                fixed3 avgColor = fixed3(0.5,0.5,0.5);
                finalColor = lerp(avgColor,finalColor,_Contrast);

                return fixed4(finalColor,renderTex.a);
            }
            
            ENDCG
        }
    }

Fallback Off
}
