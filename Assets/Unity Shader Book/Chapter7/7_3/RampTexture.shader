// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/RampTexture"
{
    Properties
    {
        // 声明纹理属性存储渐变纹理
        _Color("Color Tint",Color) = (1,1,1,1)
        _RampTex("Ramp Tex",2D) = "white"{}
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader
    {
        Pass
        {
            //声明Pass光照模式
            Tags{"LightMode" = "ForwardBase"}
            
            //声明CG代码段，定义顶点着色器和片元着色器
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            //声明与Properties相匹配的变量
            fixed4 _Color;
            sampler2D _RampTex;//纹理
            float4 _RampTex_ST;//纹理偏移
            fixed4 _Specular;//高光
            float _Gloss;//高光面积

            //定义顶点着色器的输入输出结构体
            struct a2v
            {
                float4 vertex : POSITION;//顶点位置
                float3 normal : NORMAL;//法线位置
                float4 texcoord : TEXCOORD0;//第一纹理坐标
            };

            struct v2f
            {
                float4 pos : SV_POSITION;//剪裁坐标
                float3 worldNormal : TEXCOORD0;//世界法线
                float3 worldPos : TEXCOORD1;//世界坐标
                float2 uv : TEXCOORD2;//uv纹理坐标
            };

            //定义顶点着色器
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);//转换剪裁坐标

                o.worldNormal = UnityObjectToWorldNormal(v.normal);//转换世界法线
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//转换为世界坐标

                o.uv = TRANSFORM_TEX(v.texcoord,_RampTex);//使用内置的TRANSFORM_TEX计算进过平铺和偏移的纹理
                return o;
            }

            //片元着色器
            fixed4 frag(v2f i) : SV_Target
            {
                //归一化 世界法线和光照方向
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 ambint = UNITY_LIGHTMODEL_AMBIENT.xyz;//计算光照

                fixed halfLambert = 0.5 * dot(worldNormal,worldLightDir) + 0.5;//使用半兰伯特模型，使得范围映射到[0,1]
                //从_RampTex中获取颜色值,fixed2（。。。）是一个指定得二维坐标，用于指定特定得uv坐标点
                fixed3 diffuseColor = tex2D(_RampTex,fixed2(halfLambert,halfLambert)).rgb * _Color.rgb;//使用_RampTex纹理模拟漫反射 * 颜色

                fixed3 diffuse = _LightColor0.rgb * diffuseColor; //漫反射 = 光照颜色 * 漫反射 
                
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));//归一化视角方向
                fixed3 halfDir = normalize(worldLightDir + viewDir);//归一化半向量

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);//计算漫反射光照

                return fixed4(ambint + diffuse + specular,1.0);//计算最终光照
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
