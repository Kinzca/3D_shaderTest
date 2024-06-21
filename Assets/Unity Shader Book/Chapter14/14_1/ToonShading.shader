// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/ToonShading"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
        _Ramp("Ramp Texture",2D) = "white"{}//控制漫反射的渐变纹理
        _OutLine("Outline",Range(0,1)) = 0.1//控制轮廓线宽度
        _OutLineColor("OutLine Color",Color) = (0,0,0,1)//控制轮廓线颜色
        _Specular("Specular",Color) = (1,1,1,1)//高光反射颜色
        _SpecularScale("Specular Scale",Range(0,0.1)) = 0.01//控制高光反射的阈值
    }
    
    SubShader
    {
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry"}
        Pass
        {
            NAME "OUTLINE"
            
            Cull Front //剔除正面的三角面，只渲染正面
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _OutLine;
            fixed4 _OutLineColor;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert(a2v v)
            {
                v2f o;

                //将顶点和法线转换到视角方向上
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV,v.normal);

                normal.z = -0.5;
                pos = pos + float4(normalize(normal),0) * _OutLine;
                o.pos = mul(UNITY_MATRIX_P,pos);//将顶点从视角空间变换到剪裁空间

                return o;
            }

            float4 frag(v2f i) : SV_Target{
                return float4(_OutLineColor.rgb,1);//输出渲染的轮廓线
            }
            
            ENDCG
        }

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            Cull Back
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityShaderVariables.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            fixed4 _Specular;
            fixed _SpecularScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)//使用unity内置宏计算阴影相关变量
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos( v.vertex);
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
				o.worldNormal  = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o)//使用unity内置宏计算阴影相关变量

                return o;
            }

            float4 frag(v2f i) : SV_Target{
                //计算光照中各个方向向量并将其归一化
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                //计算材质反射率
                fixed4 c = tex2D(_MainTex,i.uv);
                fixed3 albedo = c.rgb * _Color.rgb;

                //计算环境光照
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos)//使用内置宏计算当前坐标下的阴影值

                //计算半伯兰特反射系数
                fixed diff = dot(worldNormal,worldLightDir);
                diff = (diff * 0.5 + 0.5) * atten;

                //将半伯兰特反射系数和最终的阴影相乘得到最终的漫反射系数
                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp,float2(diff,diff)).rgb;

                fixed spec = dot(worldNormal,worldHalfDir);
                fixed w = fwidth(spec) * 2.0;//用fwidth函数对颜色高光区域进行抗锯齿处理
                fixed3 specular = _Specular.rgb * lerp(0,1,smoothstep(-w,w,spec + _SpecularScale - 1)) * step(0.001,_SpecularScale);//step作用为了在_SpecularScale为0时完全消除高光反射的光照

                return fixed4(ambient + diffuse + specular,1.0);//返回最终值
            }
            
            ENDCG
        }    
    }
Fallback "Diffuse"
}

