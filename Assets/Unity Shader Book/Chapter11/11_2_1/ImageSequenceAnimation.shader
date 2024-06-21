// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/ImageSequenceAnimation"
{
    //声明多个属性，以设置该序列帧的相关参数
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Image Sequence",2D) = "white"{}//包含所有关键帧的位置
        _HorizontalAmount("Horizontal Amount",Float) = 4//水平方向关键帧图像个数
        _VerticalAmount("Vertical Amount",Float) = 4//竖直方向关键帧图像个数
        _Speed("Speed",Range(1,100)) = 30//播放速度
    }
    
    SubShader
    {
        Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                float time = floor(_Time.y * _Speed);//_Time.y自场景加载后所经历的时间；与*_Speed相乘得到模拟的时间
                float row = floor(time/_HorizontalAmount);//使用floor函数对结果值取整,time/_HorizontalAmount的商作为行索引，余数作为列索引
                float column = time - row * _HorizontalAmount;//得到余数作为列索引

                //half2 uv = float2(i.uv.x/_HorizontalAmount,i.uv.y/_VerticalAmount);
                //uv.x += column/_HorizontalAmount;
                //uv.y -=row/_VerticalAmount;

                half2 uv = i.uv + half2(column,-row);//half2(column,-row)得到偏移量，再将偏移量加到uv坐标上，得到图像滚动的效果
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;

                fixed4 c = tex2D(_MainTex,uv);
                c.rgb *= _Color;

                return c;
            }
            
            ENDCG
        }
    }
Fallback "Transparent/VertexLit"
}
