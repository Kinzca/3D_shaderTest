Shader "Unlit/False Color"
{
    SubShader//针对显卡A的SubShader属性
    {
        Pass
        {
        CGPROGRAM

        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"

        struct v2f
        {
            float4 pos:SV_POSITION;
            fixed4 color:COLOR0;
        };

        v2f vert(appdata_full v)
        {
            v2f o;
            // 计算顶点位置
            o.pos = UnityObjectToClipPos(v.vertex);
            
            //可视化法线方向
            //v.normal*0.5对顶点法线进行缩放处理，使其更好的呈现颜色；
            //fixed3(0.5,0.5,0.5)表示灰色被添加到缩放的法线向量中，用于表示可视化颜色的中间值；
            //(....(),1.0)表示将alpha的值和和颜色值结合到一个fixed4类型的变量中1.0表示完全不透明
            o.color=fixed4(v.normal*0.5+fixed3(0.5,0.5,0.5),1.0);

            //可视化切线方向
            //v.tangent.xyz*0.5对顶点向量进行缩放处理
            //o.color=fixed4(v.tangent.xyz*0.5+fixed3(0.5,0.5,0.5),1.0);
            
            //可视化副切线方向
            //通过cross叉乘来计算法线向量v.normal,和切线向量向量的xyz分量的叉乘结果；
            //叉乘得出的结果是垂直于法线向量和切线向量的方向，可以用右手定则得出，食指和中指分别表示两个向量则拇指方向则是叉乘结果的方向
            // fixed3 binormal=cross(v.normal,v.tangent.xyz)*v.tangent.w;
            // o.color=fixed4(binormal*0.5+fixed3(0.5,0.5,0.5),1.0);
            
            //可视化第一组纹理坐标
            //v.texcoord.xy表示顶点坐标的x和y分量.0.0表示顶点的z分量，即顶点的额外信息，1.0即表示顶点的不透明度
            //o.color=fixed4(v.texcoord.xy,0.0,1.0);
            
            //可视化第二组纹理坐标
            //o.color=fixed4(v.texcoord1.xy,0.0,1.0);
            
            //可视化第一组纹理坐标的小数部分
            //frac函数用于获取向量中每个分量的小数部分，saturate函数用于将向量的分量限制到【0，1】
            //计算第一组与第二组纹理坐标的差值，如果在【0，1】中，则条件为真
            // o.color=frac(v.texcoord);
            // if(any(saturate(v.texcoord)-v.texcoord1))
            // {
            //     o.color.b=0.5;
            // }
            // o.color.a=1.0;

            //可视化第二组纹理坐标的小数部分
            // o.color=frac(v.texcoord);
            // if(any(saturate(v.texcoord1)-v.texcoord1))
            // {
            //     o.color.b=0.5;
            // }
            // o.color.a=1.0;


             if (v.vertex.x > 0&&v.vertex.y>0) // 例如，根据顶点的 x 坐标来决定哪些顶点显示红色
                 o.color = fixed4(1.0, 0.0, 1.0, 0.5);

            return o;
            
            //可视化顶点颜色
            o.color = v.color;
        }

        //片元着色器的入口点，用于确定显示到屏幕上的最终颜色值
        fixed4 frag(v2f i):SV_Target{
            return i.color;
        }
        
        ENDCG
        }
    }
    
}
