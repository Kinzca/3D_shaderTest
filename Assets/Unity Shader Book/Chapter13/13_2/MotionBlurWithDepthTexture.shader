// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/MotionBlurWithDepthTexture"
{
    Properties
    {
        _MainTex("Base (RGB)",2D) = "white"{} //对应输入的渲染纹理
        _BlurSize("Blur Size",Float) = 1.0 //模糊参数
    }
    
    SubShader
    {
        Pass
        {
            CGINCLUDE

            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            half4 _MainTex_TexelSize;
            sampler2D _CameraDepthTexture; //unity传递的深度纹理
            float4x4 _CurrentViewProjectionInverseMatrix;//脚本传递的矩阵
            float4x4 _PreviousViewProjectionMatrix;
            half _BlurSize;

            //顶点着色器
            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                half2 uv_depth : TEXCOORD1;
            };
            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord;
                o.uv_depth = v.texcoord;

                #if UNITY_UV_STARTS_AT_TOP
                if(_MainTex_TexelSize.y < 0)
                    o.uv_depth.y = 1 - o.uv_depth.y;
                #endif

                return o;
            }

            //片元着色器
            fixed4 frag(v2f i) : SV_Target{
                //得到当前像素的深度值
                float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth);
                //H是转换为NDC坐标的值
                float4 H = float4(i.uv.x * 2 - 1,i.uv.y * 2 - 1,d * 2 - 1,1);
                //用当前帧的视角*投影矩阵的逆矩阵对其进行变换
                float4 D = mul(_CurrentViewProjectionInverseMatrix,H);
                //将结果值/w分量得到世界表示的worldPos;
                float4 worldPos = D / D.w;

                //当前的视角坐标
                float4 currentPos = H;
                //当前坐标*前一帧的视角*投影矩阵
                float4 previousPos = mul(_PreviousViewProjectionMatrix,worldPos);
                //前一帧的坐标 * 前一帧的w分量 得到前一帧的坐标在当前世界系的表示
                previousPos /= previousPos.w;

                //使用当前帧的坐标 - 前一帧的坐标 得到像素的位移差即速度
                float2 velocity = (currentPos.xy - previousPos.xy)/2.0f;

                float2 uv = i.uv;
                float4 c = tex2D(_MainTex,uv);
                uv += velocity * _BlurSize;//使用该速度对相邻速度进行采样并进行模糊

                for(int it = 1;it < 3;it++,uv += velocity * _BlurSize)
                {
                    float4 currentColor = tex2D(_MainTex,uv);
                    c += currentColor;
                }
                c /= 3; //相加后取平均值进行一个模糊的效果

                return fixed4(c.rgb,1.0);
            }
            ENDCG
        }

//定义运动模糊所需的pass
        Pass
        {
            ZTest Always
            Cull Off
            ZWrite Off
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            ENDCG
        }
    }
Fallback Off
}
