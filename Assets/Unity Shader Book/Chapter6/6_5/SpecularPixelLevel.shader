// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/SpecularPixelLevel"
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
            float _Gloss;//范围很大，用float存储

            //定义顶点着色器的输入输出结构体，顶点着色器的输出结构体同时也是片元着色器的输入结构体
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };
            
            //在顶点着色器中只需要计算世界空间下的的顶点和法线坐标
            v2f vert(a2v v)
            {
                v2f o;
                //将顶点位置从物体转到裁剪
                o.pos = UnityObjectToClipPos(v.vertex);

                //将法线从物体转到世界并归一化
                o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
                //将顶点坐标从物体转到世界
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                return o;
            }

            //在片元着色中直接返回颜色
            fixed4 frag(v2f i) :SV_Target
            {
                //获取光照信息
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal =normalize(i.worldNormal);//获取世界法线
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);//获取光照方向

                //进行漫反射光照计算
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));

                //得到世界空间下的反射方向
                fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
                //获取世界空间下的观察方向
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

                //完成最后的光照计算
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir,viewDir)),_Gloss);

                return fixed4(ambient + diffuse + specular,1.0);
            }
            
            ENDCG
        }
    }
    Fallback "Specular"
}
