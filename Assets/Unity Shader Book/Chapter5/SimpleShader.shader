// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/SimpleShader"
{
    Properties
    {
        //声明一个Color类型的属性
        _Color("Color Tint",Color) = (1.0,1.0,1.0,1.0)
    }
    
    SubShader//针对显卡A的SubShader属性
    {
        Pass
        {//设置渲染状态和标签
            //开始CG片段
            CGPROGRAM
            
            #include"UnityCG.cginc"//使用unity中的内置着色器
            
            //该代码片段的编译指令
            //告诉编译器哪个函数包含顶点着色器的代码，哪个函数包含片元着色器代码
            #pragma vertex vert 
            #pragma fragment frag

            //在CG代码中，我们需要定义一个与属性名称和类型都匹配的的变量
            fixed4 _Color;

            //使用一个结构体定义顶点着色器的输入
            struct a2v
            {
                //POSITION 语义告诉UNITY，用模型空间的顶点坐标填充vertex变量
                float4 vertex:POSITION;
                //NORMAL 语义告诉UNITY,用模型空间的法线方向填充normal变量
                float3 normal:NORMAL;
                //TEXCOORD0 语义告诉UNITY,用模型的第一纹理坐标填充 texcoord变量
                float4 texcorrd:TEXCOORD0;
            };

            //使用一个结构体来定义顶点着色器的输出
            struct v2f
            {
                //SV_POSITION 语义告诉Unity;pos里面包含了顶点在剪裁空间中的位置信息
                float4 pos:SV_POSITION;
                //COLOR0 语义可以用于储存颜色信息
                fixed3 color:COLOR;
            };

            //声明输出结构
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //v.normal包含这顶点的法线方向，其分量范围在[-1.0,1.0]
                //下面的代码把分量范围映射到(0.0,1.0)
                //储存到o.color中传递给片元着色器
                o.color=v.normal*0.5+fixed3(0.5,0.5,0.5);
                return o;
            }
            
            fixed4 frag(v2f i):SV_Target{
                fixed3 c=i.color;
                //使用_Color属性来控制输出颜色
                c*=_Color.rgb;
                //将插值后的i.color显示到屏幕上
                return fixed4(i.color,1.0);
            }
            
            ENDCG
            
        }
    }
}
