// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Water"
{
    Properties
    {
        _MainTex("Main Tex",2D) = "white"{} //河流纹理
        _Color("Color Tint",Color) = (1,1,1,1) //控制整体颜色
        _Magnitude("Distortion Magnitude",Float) = 1 //控制水流波动幅度
        _Frequency("Distortion Frequency",Float) = 1 //控制波动频率
        InvWaveLength("Distortion Inverse Wave Length",Float) = 10 //控制波长的倒数，越大波长越小
        _Speed("Speed",Float) = 0.5 //河流移动速度
    }
    
    SubShader
    {
        //添加一个取消批处理的新标签
        //因为批处理会合并所有的模型，而我们需要在模型的各个模型空间进行顶点变换
        Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
    
        pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off //关闭提出模式
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
            float _Speed;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                float4 offest;

                //首先计算顶点坐标，需要对x 进行偏移，因此yzw分量被设为0
                offest.yzw = float3(0.0,0.0,0.0);

                //计算x轴上的分量 （频率*时间 + x点位置*波长 + y点位置*波长 + z点位置*波长）*波长幅度
                offest.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
                o.pos = UnityObjectToClipPos(v.vertex + offest);//将偏移量+顶点位置 再将其转换到剪裁空间

                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);//获取主纹理属性
                o.uv += float2(0.0,_Time.y * _Speed);//对纹理坐标进行偏移

                return o;
            }

            //片元着色器只需要对纹理采样并添加颜色
            fixed4 frag(v2f i) : SV_Target{
                fixed4 c = tex2D(_MainTex,i.uv);//获取主纹理属性
                c.rgb *= _Color.rgb;//对颜色进行叠加

                return c;
            }
            
            ENDCG
        }
    }
    Fallback "Transparent/VertexLit"
}
