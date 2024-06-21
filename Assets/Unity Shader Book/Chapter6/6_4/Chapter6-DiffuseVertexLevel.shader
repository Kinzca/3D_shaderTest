// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Chapter6-DiffuseVertexLevel"
{
    Properties
    {
        //定义漫反射名称，并指定其标签和类型
        _Diffuse("Diffuse",Color)=(1,1,1,1)
    }
    SubShader
    {
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            
            //定义CG代码段
            CGPROGRAM

            //在CG代码段中定义顶点着色器，和片元着色器
            #pragma vertex vert
            #pragma fragment frag

            //引入unity的内置变量
            #include "Lighting.cginc"

            //我们需要定义一个与Properties中变量相同的的名称的变量，以便使用
            fixed4 _Diffuse;

            //定义顶点着色器的输入输出结构体
            //输出结构体同时也是片元着色器的输入结构体
            struct a2v
            {
                float4 vertex : POSITION;//顶点位置
                float3 normal : NORMAL;//法线位置
            };

            struct v2f
            {
                float4 pos : SV_POSITION;//顶点位置
                fixed3 color : COLOR;//颜色
            };

            //逐顶点的漫反射光照
            //将a2v作为参数传入
            v2f vert(a2v v)
            {
                //定义输出结构体v2f
                v2f o;
                //将顶点位置从对象空间转换到剪裁空间
                o.pos = UnityObjectToClipPos(v.vertex);
                //获取光照的颜色，xyz只得就是红绿蓝通道
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                //将顶点法线从对象空间转换到世界空间，并进行归一化处理
                fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                //获取世界的光照，并进行归一化处理
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                //计算漫反射光照分量，光照颜色*材质漫反射属性*（世界光照和法线的夹角）
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));

                //将环境光照和漫反射光照进行相加，并将结果赋值给输出结构体
                o.color = ambient + diffuse;
                return o;
            }

            //片元着色器
            //将v2f作为参数传入
            fixed4 frag(v2f i):SV_Target
            {
                 return fixed4(i.color,1.0);
            }
            ENDCG
        }
    }
    Fallback"Diffuse"
}
