// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Reflection"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _ReflectColor("Reflection Color",Color) =(1,1,1,1)//控制反射颜色
        _ReflectAmount("Reflect Amount",Range(0,1)) = 1//控制反射程度
        _Cubemap("Reflection Cubmap",Cube) = "_Skybox"{}//模拟反射的环境映射纹理
    }
    
    SubShader
    {
        Tags{"RenderType"="Opaque" "Queue"="Geometry"}
    
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            
            CGPROGRAM

            #pragma multi_compile_fwdbase //编译预指令

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed4 _ReflectColor;
            fixed _ReflectAmount;
            samplerCUBE _Cubemap;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldViewDir : TEXCOORD2;
                fixed3 worldRefl : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);//转换至剪裁空间坐标

                o.worldNormal = UnityObjectToWorldNormal(v.normal);//将物体法线转换到世界空间下的法线

                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//将物体坐标转换到世界空间下

                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);//视角方向转换到世界空间下的坐标

                //在世界空间下完成反射计算
                o.worldRefl = reflect(-o.worldViewDir,o.worldNormal);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                fixed3 worldNormal = normalize(i.worldNormal);//归一化世界法线
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));//归一化世界光照方向
                fixed3 worldViewDir = normalize(i.worldViewDir);//归一化视角方向

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//计算环境光照

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldNormal,worldLightDir));
                
                //texCUBE从立方体贴图上获取特定方向的颜色值，* 反射颜色
                fixed3 reflection = texCUBE(_Cubemap,i.worldRefl).rgb * _ReflectColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);//计算光照衰减

                //将漫反射和反射颜色混合,使用lerp计算光照的线性插值，并用_ReflectionAmount计算两种颜色的混合程度
                fixed3 color = ambient +lerp(diffuse,reflection,_ReflectAmount) * atten;
                
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
Fallback "Reflective/VertexLit"
}
