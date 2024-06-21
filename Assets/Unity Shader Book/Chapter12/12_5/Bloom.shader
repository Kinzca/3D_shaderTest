// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Bloom"
{
    
    Properties
    {
        _MainTex("Base (RGB)",2D) = "white"{}
        _Bloom("Bloom (RGB)",2D) = "black"{} //高斯模糊后的较亮区域
        _LuminanceThreshold("Luminance Threshold",Float) = 0.5 //提取较量区域使用的阈值
        _BlurSize("Blur Size",Float) = 1.0  //控制高斯模糊的区域范围
    }
    
    SubShader
    {
        CGINCLUDE//包含一个通用的CG指令，可以在多个着色器间共享

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _LuminanceThreshold;
        float _BlurSize;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0; 
        };

        v2f vertExtractBright(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            o.uv = v.texcoord;
            
            return o;
        }

        fixed4 luminance(fixed4 color)
        {
            return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
        }

        fixed fragExtractBright(v2f i) : SV_Target{
            fixed4 c = tex2D(_MainTex,i.uv);
            fixed val = clamp(luminance(c) - _LuminanceThreshold,0.0,1.0);

            return c * val;
        }

        struct v2fBloom
        {
            float4 pos : SV_POSITION;
            half4 uv : TEXCOORD0;
        };

        v2fBloom vertBloom(appdata_img v)
        {
            v2fBloom o;

            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord;
            o.uv.zw = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0.0)
                o.uv.w = 1.0 - o.uv.w;
            #endif

            return o;
            
        }

        fixed4 fragBloom(v2fBloom i) : SV_Target{
            return tex2D(_MainTex,i.uv.xy) + tex2D(_Bloom,i.uv.zw);
        }
        
        ENDCG

        ZTest Always Cull Off 
        ZWrite Off
        
        Pass
        {
            CGPROGRAM

            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            
            ENDCG
        }

        UsePass "Unlit/GaussianBlur/GAUSSIAN_BLUR_VERTICAL"
        UsePass "Unlit/GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"

        Pass
        {
            CGPROGRAM
            
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            
            ENDCG
        }
    }

Fallback Off
}
