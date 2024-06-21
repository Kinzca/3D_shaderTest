// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/EdgeDetectNormalAndDepth"
{
    Properties
    {
        _MainTex("Base (RGB)",2D) = "white"{}
        _EdgeOnly("Edge Only",Float) = 1.0
        _EdgeColor("Edge Color",Color) = (0,0,0,1)
        _BackgroundColor("Background Color",Color) = (1,1,1,1)
        _SampleDistance("Sample Distance",Float) = 1.0
        _Sensitivity("Sensitivity",Vector) = (1,1,1,1)//xy分量对应着法线和深度的灵敏检测器，zw分量并没有实际用途
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;//存储的纹素大小
        fixed _EdgeOnly;
        fixed4 _EdgeColor;
        fixed4 _BackgroundColor;
        float _SampleDistance;
        half4 _Sensitivity;
        
        sampler2D _CameraDepthNormalsTexture;//需要获取的法线+深度纹理

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv[5] : TEXCOORD0;
        };
        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            half2 uv = v.texcoord;
            o.uv[0] = uv;

            #if UNITY_UV_STARTS_AT_TOP//用于检查纹理坐标是否在顶部（左角）
            if(_MainTex_TexelSize.y < 0)//如果在顶部就对其进行翻转
                uv.y = 1 - uv.y;//从原始的（0,1）翻转到(1,0)
            #endif

            o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance;
            o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance;
            o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance;
            o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance;

            return o;
        }

        half CheckSame(half4 center,half4 sample)
        {
            half2 centerNormal = center.xy;
            float centerDepth = DecodeFloatRG(center.zw);
            half2 sampleNormal = sample.xy;
            float sampleDepth = DecodeFloatRG(sample.zw);

            //比较法线的差异度 * 灵敏度；并将计算结果与一个阈值比较得到是否需要显示边界
            half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
            int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1f;

            //比较深度值的差异度 * 灵敏度；并将计算结果与一个阈值比较得到是否需要显示边界
            float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
            int isSameDepth = diffDepth < 0.1 * centerDepth;

            //将法线和深度值相乘得到组合后的返回值
            return isSameNormal * isSameDepth ? 1.0 : 0.0;
        }
        
        fixed4 fragRobertsCrossDepthAndNormal(v2f i) : SV_Target{
            half4 sample1 = tex2D(_CameraDepthNormalsTexture,i.uv[1]);
            half4 sample2 = tex2D(_CameraDepthNormalsTexture,i.uv[2]);
            half4 sample3 = tex2D(_CameraDepthNormalsTexture,i.uv[3]);
            half4 sample4 = tex2D(_CameraDepthNormalsTexture,i.uv[4]);

            half edge = 1.0;

            edge *= CheckSame(sample1,sample2);
            edge *= CheckSame(sample3,sample4);

            fixed4 withEdgeColor = lerp(_EdgeColor,tex2D(_MainTex,i.uv[0]),edge);
            fixed4 onlyEdgeColor = lerp(_EdgeColor,_BackgroundColor,edge);

            return lerp(withEdgeColor,onlyEdgeColor,_EdgeOnly);
            
        }
        ENDCG

        Pass
        {
            ZTest Always
            Cull Off
            ZWrite Off
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment fragRobertsCrossDepthAndNormal
            
            ENDCG
        }
    }
Fallback Off
}
