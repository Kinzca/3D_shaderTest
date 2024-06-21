// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/SpecularVertexLevel"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)//用于控制材质的高光反射颜色
        _Gloss("Gloss",Range(8.0,256))=20//控制高光区域的大小 
    }
    SubShader
    {
        Pass
        {
            //指定光照模式,用于定义unity光照流水线上的角色
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Diffuse;//范围在[0,1]，用fixed存储
            fixed4 _Specular;//范围在[0,1]，用fixed存储
            float _Gloss;//范围很大，用float存储，控制高光的锐度范围

            //定义顶点着色器的输入输出结构体，顶点着色器的输出结构体同时也是片元着色器的输入结构体
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR;
            };
            
            //在顶点着色器中计算包含高光反射的光照模型
            v2f vert(a2v v)
            {
                v2f o;
                //将顶点位置从物体转到裁剪
                o.pos = UnityObjectToClipPos(v.vertex);

                //获取光源的颜色信息
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //将法线从物体转到世界并归一化
                fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                //得到世界坐标下的光源方向
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                //计算漫反射光照分量
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb *saturate(dot(worldNormal,worldLightDir));

                //获取世界坐标下的反射矢量
                fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
                //获取世界左边下的观察方向的矢量
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex).xyz);//相机位置-顶点位置

                //进行高光计算,光照颜色 * 高光颜色 * （反射方向与观察方向的夹角）的_Gloss次幂
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir,viewDir)),_Gloss);

                //将计算结果相加
                o.color = ambient + diffuse + specular;

                return o;
            }

            //在片元着色中直接返回颜色
            fixed4 frag(v2f i) :COLOR{
                return fixed4(i.color,1.0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
