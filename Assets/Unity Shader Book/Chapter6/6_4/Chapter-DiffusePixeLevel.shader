// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Chapter-DiffusePixeLevel"
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
                fixed3 worldNormal : TEXCOORD0;//第一纹理坐标
            };

            //逐顶点的漫反射光照
            //将a2v作为参数传入
            //顶点着色器不需要计算光照模型，只把世界空间下的法线传递给片元着色器即可
            v2f vert(a2v v)
            {
                v2f o;
                //将顶点坐标从对象空间转换到剪裁空间
                o.pos = UnityObjectToClipPos(v.vertex);
                //将法线从对象空间转换到世界空间
                o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);

                return o;
            }

            //片元着色器计算漫反射光照
            //将v2f作为参数传入
            fixed4 frag(v2f i):SV_Target
            {
                //获取环境光颜色
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //规范化世界空间的法线向量，由顶点着色器传入的
                fixed3 worldNormal = normalize(i.worldNormal);
                //规范化世界空间的光源向量
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                //计算漫反射光照分量，光源颜色*材质漫反射度*（世界法线向量与世界光源的夹角度数）
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb *saturate(dot(worldNormal,worldLightDir));

                //最终颜色 = 环境光 + 漫反射光
                fixed3 color = ambient + diffuse;

                //返回最终颜色
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
    Fallback"Diffuse"
}
