// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/ScrollingbackGround"
{
    Properties
    {
        _MainTex("Base Layer (RGB)",2d) = "white"{}//第一层背景
        _DetailTex("2nd Layer (RGB)",2D) = "white"{}//第二层背景
        _ScrollX("Base layer Scroll Speec",Float) = 1.0//第一层滚动速度
        _Scroll2X("2nd layer Scroll Speed",Float) = 1.0//第二层滚动速度
        _Multiplier("Layer Multiplier",Float) = 1
    }
    
    SubShader
    {
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry"}
        
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            sampler2D _MainTex;
            sampler2D _DetailTex;
            float4 _MainTex_ST;//偏移值是一个四元数
            float4 _DetailTex_ST;
            float _ScrollX;
            float _Scroll2X;
            float _Multiplier;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);//首先转换到剪裁空间

                //首先用TRANSFORM_TEX获取主纹理，随后使用内置的_Time.y变量对纹理的水平坐标进行偏移，达到滚动的效果
                //frac同于获取小数部分这样就可以达到周期性的滚动效果
                //创建一个float2分量使用_Time.y乘以这个分量就可以对_ScrollX进行变化
                //最后将其存储在一个变量o.uv中，以减少插值寄存器空间
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex) + frac(float2(_ScrollX,0.0) * _Time.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_DetailTex) + frac(float2(_Scroll2X,0.0) * _Time.y);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                //对纹理背景进行采样
                fixed4 firstLayer = tex2D(_MainTex,i.uv.xy);
                fixed4 secondLayer = tex2D(_DetailTex,i.uv.zw);

                //对两个图层进行线性插值，插值由第二个图层的透明度决定
                //再将rgb分量与_Multiplier进行相乘调整亮度
                fixed4 c = lerp(firstLayer,secondLayer,secondLayer.a);
                c.rgb *= _Multiplier;

                return c;
            }
            
            ENDCG
        }
    }
    Fallback "VertexLit"
}
