// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/EdgeDetection"
{
    Properties
    {
        _MainTex("Base (RGB)",2D) = "white"{} //对应着输入的渲染纹理
        _EdgeOnly("Edge Only",Float) = 1.0
        _EdgeColor("Edge Color",Color) =  (0,0,0,1)
        _BackgroundColor("Background Color",Color) = (1,1,1,1)
    }
    
    SubShader
    {
        Pass
        {
            ZTest Always Cull Off
            ZWrite Off
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment fragSobel

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            uniform  half4 _MainTex_TexelSize;//xxx_TexelSize是unity提供的访问 xxx纹理对应的每个像素的大小,注意拼写是TexelSize
            fixed _EdgeOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;

            //在顶点着色器中计算边缘检测时所需要的纹理坐标
            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv[9] : TEXCOORD0;
            };

            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                half2 uv = v.texcoord;

                //uv表示当前顶点坐标，_MainTex_TexelSize表示每个像素的大小和信息，_MainTex_TexelSize.xy表示纹理的大小和信息*half()就表示着这个像素四周9个像素的纹理坐标
                o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1,-1);
                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0,-1);
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1,-1);
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,0);
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0,0);
                o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1,0);
                o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1,1);
                o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0,1);
                o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1,1);

                return o;
            }

            fixed luminance(fixed4 color)
            {
                return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
            }

            //Sobel将利用Sobel算子对原图进行边缘检测
            half Sobel(v2f i)
            {
                //首先定义水平和数值方向的卷积
                const half Gx[9] = {-1, 0, 1,
                                -2, 0, 2,
                                -1, 0, 1};
                const half Gy[9] = {-1, -2, -1,
                                0, 0, 0,
                                1, 2, 1};

                half texColor;
                half edgeX = 0;
                half edgeY = 0;

                //然后对9个像素以此采样计算他们的像素值，重叠到他们的梯度上
                for (int it = 0; it < 9; it++)
                {
                    //sobel算子对灰度值进行边缘检测而不需要RGB信息
                    texColor = luminance(tex2D(_MainTex,i.uv[it]));//提取主纹理的颜色值，并将他们转换为亮度值
                    edgeX += texColor * Gx[it];//表示水平梯度值，通过与卷积核相乘并将其累加到梯度值中
                    edgeY += texColor * Gy[it];//表示竖直梯度值
                }
                half edge = 1 - abs(edgeX) - abs(edgeY); //计算边缘强度

                return edge;
            }

            //片元着色器
            fixed4 fragSobel(v2f i) : SV_Target{
                //首先调用Sobel计算当前像素所需要的梯度值
                half edge = Sobel(i);

                //并利用该值计算了背景为原图，或者纯色下的颜色值
                //最后利用_EdgeOnly在两者间取插值得到最终的像素值
                fixed4 withEdgeColor = lerp(_EdgeColor,tex2D(_MainTex,i.uv[4]),edge);//仅有边缘强度的颜色
                fixed4 onlyEdgeColor = lerp(_EdgeColor,_BackgroundColor,edge);//带有边缘强度的颜色

                return lerp(withEdgeColor,onlyEdgeColor,_EdgeOnly);//最终颜色
            }
            
            ENDCG
        }
    }
Fallback Off
}
