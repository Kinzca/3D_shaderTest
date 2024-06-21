// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/FogWithDepthTexture"
{
    Properties
    {
        _MainTex("Base (RGB)",2D) = "white"{}
        _FogDensity("Fog Density",Float) = 1.0
        _FogColor("Fog Color",Color) = (1,1,1,1)
        _FogStart("Fog Start",Float) = 0.0
        _FogEnd("Fog End",Float) = 1.0
    }
    
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"
        
        float4x4 _FrustumCornersRay;//由脚本传入

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _CameraDepthTexture;//摄像机深度纹理
        half _FogDensity;
        fixed4 _FogColor;
        float _FogStart;
        float _FogEnd;

        //顶点着色器
        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
            half2 uv_depth : TEXCOORD1;
            float4 interpolatedRay : TEXCOORD2;//存储插值后的像素像素向量
        };

        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP//如果不符合unity的坐标系进行翻转
            if (_MainTex_TexelSize.y < 0)
            {
                o.uv_depth.y = 1 - o.uv_depth.y;
            }
            #endif

            //unity中右上（1，1），左下（0，0）；通过这点判断该顶点坐标在屏幕的位置
            //将近剪裁平面对应的数组坐标存储到了_FrustumCornersRay数组中
            int index = 0;
            if(v.texcoord.x < 0.5 && v.texcoord.y < 0.5)//（0，0）左下
            {
                index = 0;
            }else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5)//（1，0）右下
            {
                index = 1;
            }else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5)//(1,1)右上
            {
                index = 2;
            }
            else//左上
            {
                index = 3;
            }

            #if UNITY_UV_STARTS_AT_TOP//如果不符合unity的坐标系进行翻转
            if(_MainTex_TexelSize.y < 0)
            {
                index = 3 - index;
            }
            #endif

            o.interpolatedRay = _FrustumCornersRay[index];

            return o;
        }

        //片元着色器
        fixed4 frag(v2f i) : SV_Target{
            //用SAMPLE_DEPTH_TEXTURE对纹理进行采样后再用LinearEyeDepth得到视角空间下的线性深度坐标
            float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth));
            //再将其与i.interpolatedRay相乘再与摄像机的坐标进行相加后得到世界坐标
            float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay;

            //计算当前的高度值worldPos.y对应的雾效高度系数fogDensity,相乘后saturate截取到[0,1]
            float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
            fogDensity = saturate(fogDensity * _FogDensity);

            fixed4  finalColor = tex2D(_MainTex,i.uv);
            finalColor.rgb = lerp(finalColor.rgb,_FogColor.rgb,fogDensity);

            return finalColor;
        }
        ENDCG

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
